[CmdletBinding()]
param(
    [ValidateSet('Check', 'Plan', 'Apply', 'Uninstall')]
    [string]$Action = 'Check',

    [string]$RepositoryRoot,

    [ValidateSet('Text', 'Json')]
    [string]$OutputFormat = 'Text'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Manager = 'ai-skill-hub.codex-user-skills/v1'
$script:ManifestName = '.ai-skill-hub-user-skills.json'
$script:LockName = '.ai-skill-hub-user-skills.lock'
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
try {
    [Console]::OutputEncoding = $script:Utf8NoBom
}
catch {
    # File artifacts still use the explicit UTF-8 encoder below.
}
$script:DecisionMap = [ordered]@{
    CODEX_HOME_UNRESOLVED       = 'BLOCKED_CODEX_HOME_UNRESOLVED'
    CANONICAL_SOURCE_INVALID    = 'BLOCKED_CANONICAL_SOURCE_INVALID'
    DEPENDENCY_CLOSURE_INVALID  = 'BLOCKED_DEPENDENCY_CLOSURE_INVALID'
    TARGET_CONFLICT             = 'BLOCKED_TARGET_CONFLICT'
    UNKNOWN_PROVENANCE          = 'BLOCKED_UNKNOWN_PROVENANCE'
    LOCAL_MODIFICATION          = 'BLOCKED_LOCAL_MODIFICATION'
    BROKEN_LINK                 = 'BLOCKED_BROKEN_LINK'
    MANIFEST_MISSING            = 'BLOCKED_MANIFEST_MISSING'
    MANIFEST_INVALID            = 'BLOCKED_MANIFEST_INVALID'
    MANIFEST_TARGET_MISMATCH    = 'BLOCKED_MANIFEST_TARGET_MISMATCH'
    SYSTEM_MANAGED_TARGET       = 'BLOCKED_SYSTEM_MANAGED_TARGET'
    CONCURRENT_MANAGER_OPERATION = 'BLOCKED_CONCURRENT_OPERATION'
    STALE_TRANSACTION_ARTIFACT  = 'BLOCKED_STALE_TRANSACTION_ARTIFACT'
    PATH_SAFETY_VIOLATION       = 'BLOCKED_PATH_SAFETY_VIOLATION'
    POST_LOCK_STATE_CHANGED     = 'BLOCKED_POST_LOCK_STATE_CHANGED'
    ROLLBACK_FAILURE            = 'BLOCKED_ROLLBACK_FAILURE'
    UNEXPECTED_ERROR            = 'BLOCKED_UNEXPECTED_ERROR'
}

function New-ManagerException {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Condition,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if (-not $script:DecisionMap.Contains($Condition)) {
        $Condition = 'UNEXPECTED_ERROR'
    }
    $exception = New-Object System.InvalidOperationException($Message)
    $exception.Data['Condition'] = $Condition
    $exception.Data['Decision'] = $script:DecisionMap[$Condition]
    return $exception
}

function Throw-ManagerError {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Condition,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    throw (New-ManagerException -Condition $Condition -Message $Message)
}

function Get-ScriptRepositoryRoot {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif ($MyInvocation.MyCommand.Path) {
        $MyInvocation.MyCommand.Path
    }
    else {
        Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'The script path could not be resolved.'
    }
    return [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Path $scriptPath -Parent) '..'))
}

function Test-HasWildcard {
    param([Parameter(Mandatory = $true)][string]$Value)
    return $Value.IndexOfAny([char[]]'*?[]') -ge 0
}

function Get-NormalizedAbsolutePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue,

        [Parameter(Mandatory = $true)]
        [string]$Condition,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        Throw-ManagerError -Condition $Condition -Message "$Label is blank."
    }
    if (Test-HasWildcard -Value $PathValue) {
        Throw-ManagerError -Condition $Condition -Message "$Label contains wildcard characters."
    }
    if (-not [System.IO.Path]::IsPathRooted($PathValue)) {
        Throw-ManagerError -Condition $Condition -Message "$Label must be absolute."
    }
    try {
        $fullPath = [System.IO.Path]::GetFullPath($PathValue)
    }
    catch {
        Throw-ManagerError -Condition $Condition -Message "$Label could not be normalized."
    }
    $root = [System.IO.Path]::GetPathRoot($fullPath)
    if ([string]::IsNullOrWhiteSpace($root)) {
        Throw-ManagerError -Condition $Condition -Message "$Label has no filesystem root."
    }
    if ($fullPath.StartsWith('\\', [System.StringComparison]::Ordinal)) {
        Throw-ManagerError -Condition $Condition -Message "$Label cannot be a UNC path in V1."
    }
    return $fullPath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Test-PathEqual {
    param(
        [Parameter(Mandatory = $true)][string]$Left,
        [Parameter(Mandatory = $true)][string]$Right
    )
    return [string]::Equals($Left, $Right, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-PathInside {
    param(
        [Parameter(Mandatory = $true)][string]$Candidate,
        [Parameter(Mandatory = $true)][string]$Parent
    )
    if (Test-PathEqual -Left $Candidate -Right $Parent) {
        return $true
    }
    $prefix = $Parent.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    return $Candidate.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-SafeItem {
    param(
        [Parameter(Mandatory = $true)][string]$LiteralPath,
        [string]$BrokenCondition = 'BROKEN_LINK'
    )
    try {
        return Get-Item -LiteralPath $LiteralPath -Force -ErrorAction Stop
    }
    catch {
        if (Test-Path -LiteralPath $LiteralPath) {
            Throw-ManagerError -Condition $BrokenCondition -Message 'A filesystem object could not be inspected safely.'
        }
        return $null
    }
}

function Get-ItemIncludingBrokenLink {
    param([Parameter(Mandatory = $true)][string]$LiteralPath)
    $item = Get-SafeItem -LiteralPath $LiteralPath -BrokenCondition 'PATH_SAFETY_VIOLATION'
    if ($null -ne $item) {
        return $item
    }
    $parent = Split-Path -Path $LiteralPath -Parent
    $leaf = Split-Path -Path $LiteralPath -Leaf
    if (-not [string]::IsNullOrWhiteSpace($parent) -and (Test-Path -LiteralPath $parent -PathType Container)) {
        $match = @(Get-ChildItem -LiteralPath $parent -Force -ErrorAction Stop | Where-Object {
            [string]::Equals($_.Name, $leaf, [System.StringComparison]::OrdinalIgnoreCase)
        })
        if ($match.Count -gt 0) {
            return $match[0]
        }
    }
    return $null
}

function Test-IsReparsePoint {
    param([Parameter(Mandatory = $true)][System.IO.FileSystemInfo]$Item)
    return (($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
}

function Assert-NoReparseAncestors {
    param(
        [Parameter(Mandatory = $true)][string]$PathValue,
        [Parameter(Mandatory = $true)][string]$StopAt
    )
    $cursor = $PathValue
    while (-not [string]::IsNullOrWhiteSpace($cursor)) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-SafeItem -LiteralPath $cursor
            if ($null -ne $item -and (Test-IsReparsePoint -Item $item)) {
                Throw-ManagerError -Condition 'PATH_SAFETY_VIOLATION' -Message 'A target path ancestor is a reparse point.'
            }
        }
        if (Test-PathEqual -Left $cursor -Right $StopAt) {
            break
        }
        $parent = Split-Path -Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or (Test-PathEqual -Left $parent -Right $cursor)) {
            break
        }
        $cursor = $parent
    }
}

function ConvertTo-NormalizedRelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$PathValue,
        [string]$Condition = 'PATH_SAFETY_VIOLATION'
    )
    if ([string]::IsNullOrWhiteSpace($PathValue) -or [System.IO.Path]::IsPathRooted($PathValue) -or (Test-HasWildcard -Value $PathValue)) {
        Throw-ManagerError -Condition $Condition -Message 'A managed path is not a safe relative path.'
    }
    $normalized = $PathValue.Replace('\', '/').Trim('/')
    $segments = @($normalized -split '/')
    if ($segments.Count -eq 0 -or $segments -contains '' -or $segments -contains '.' -or $segments -contains '..') {
        Throw-ManagerError -Condition $Condition -Message 'A managed path contains an unsafe segment.'
    }
    if ([string]::Equals($segments[0], '.system', [System.StringComparison]::OrdinalIgnoreCase)) {
        Throw-ManagerError -Condition 'SYSTEM_MANAGED_TARGET' -Message 'The .system directory is permanently excluded.'
    }
    return $normalized
}

function Get-Sha256Bytes {
    param([Parameter(Mandatory = $true)][byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($sha.ComputeHash($Bytes) | ForEach-Object { $_.ToString('x2') }) -join '')
    }
    finally {
        $sha.Dispose()
    }
}

function Get-Sha256File {
    param([Parameter(Mandatory = $true)][string]$Path)
    return Get-Sha256Bytes -Bytes ([System.IO.File]::ReadAllBytes($Path))
}

function Get-RegularFileMap {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [string[]]$IncludedFiles = @(),
        [string]$UnsafeCondition = 'CANONICAL_SOURCE_INVALID'
    )
    $result = New-Object 'System.Collections.Generic.List[object]'
    $rootItem = Get-SafeItem -LiteralPath $Root -BrokenCondition $UnsafeCondition
    if ($null -eq $rootItem -or -not $rootItem.PSIsContainer) {
        Throw-ManagerError -Condition $UnsafeCondition -Message 'A required payload directory is missing.'
    }
    if (Test-IsReparsePoint -Item $rootItem) {
        Throw-ManagerError -Condition $UnsafeCondition -Message 'A payload root is a reparse point.'
    }

    if (@($IncludedFiles).Count -gt 0) {
        foreach ($declaredFile in @($IncludedFiles)) {
            $relative = ConvertTo-NormalizedRelativePath -PathValue ([string]$declaredFile) -Condition $UnsafeCondition
            $full = [System.IO.Path]::GetFullPath((Join-Path $Root ($relative.Replace('/', '\'))))
            if (-not (Test-PathInside -Candidate $full -Parent $Root)) {
                Throw-ManagerError -Condition $UnsafeCondition -Message 'An included file escapes its payload root.'
            }
            $item = Get-SafeItem -LiteralPath $full -BrokenCondition $UnsafeCondition
            if ($null -eq $item -or $item.PSIsContainer -or (Test-IsReparsePoint -Item $item)) {
                Throw-ManagerError -Condition $UnsafeCondition -Message 'An included payload file is missing or unsupported.'
            }
            $result.Add([pscustomobject]@{ RelativePath = $relative; FullPath = $full })
        }
    }
    else {
        $pending = New-Object 'System.Collections.Generic.Stack[string]'
        $pending.Push($Root)
        while ($pending.Count -gt 0) {
            $directory = $pending.Pop()
            foreach ($child in @(Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop)) {
                if (Test-IsReparsePoint -Item $child) {
                    Throw-ManagerError -Condition $UnsafeCondition -Message 'A payload contains a reparse point.'
                }
                if ($child.PSIsContainer) {
                    $pending.Push($child.FullName)
                }
                else {
                    $relative = $child.FullName.Substring($Root.Length).TrimStart('\', '/').Replace('\', '/')
                    $result.Add([pscustomobject]@{ RelativePath = $relative; FullPath = $child.FullName })
                }
            }
        }
    }
    return @($result.ToArray() | Sort-Object -Property @{ Expression = { $_.RelativePath }; Ascending = $true })
}

function Get-TreeFingerprint {
    param([Parameter(Mandatory = $true)][object[]]$FileMap)
    $stream = New-Object System.IO.MemoryStream
    try {
        [string[]]$relativePaths = @($FileMap | ForEach-Object { [string]$_.RelativePath })
        [Array]::Sort($relativePaths, [System.StringComparer]::Ordinal)
        foreach ($relativePath in $relativePaths) {
            $file = @($FileMap | Where-Object {
                [string]::Equals([string]$_.RelativePath, $relativePath, [System.StringComparison]::Ordinal)
            })[0]
            $fileHash = Get-Sha256File -Path $file.FullPath
            $record = '{0}{1}{2}{3}' -f $relativePath.Replace('\', '/'), [char]0, $fileHash, "`n"
            $recordBytes = $script:Utf8NoBom.GetBytes($record)
            $stream.Write($recordBytes, 0, $recordBytes.Length)
        }
        return Get-Sha256Bytes -Bytes $stream.ToArray()
    }
    finally {
        $stream.Dispose()
    }
}

function Invoke-GitText {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$AllowNonZero
    )
    $output = @(& git -C $Root @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    if (-not $AllowNonZero -and $exitCode -ne 0) {
        Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'The source Git repository check failed.'
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Text = (($output | ForEach-Object { [string]$_ }) -join "`n").Trim()
    }
}

function Test-StringArrayEqual {
    param([object]$Left, [object]$Right)
    $leftArray = @($Left | ForEach-Object { [string]$_ })
    $rightArray = @($Right | ForEach-Object { [string]$_ })
    if ($leftArray.Count -ne $rightArray.Count) { return $false }
    for ($index = 0; $index -lt $leftArray.Count; $index++) {
        if (-not [string]::Equals($leftArray[$index], $rightArray[$index], [System.StringComparison]::Ordinal)) {
            return $false
        }
    }
    return $true
}

function Test-ObjectHasProperties {
    param(
        [Parameter(Mandatory = $true)][object]$Value,
        [Parameter(Mandatory = $true)][string[]]$Names
    )
    if ($null -eq $Value) { return $false }
    $available = @($Value.PSObject.Properties.Name)
    foreach ($name in $Names) {
        if ($available -notcontains $name) { return $false }
    }
    return $true
}

function Test-JsonInteger {
    param([object]$Value)
    return ($Value -is [int] -or $Value -is [long])
}

function Test-UtcIso8601 {
    param([object]$Value)
    if ($Value -is [DateTime]) {
        return $Value.Kind -eq [DateTimeKind]::Utc
    }
    if ($Value -is [DateTimeOffset]) {
        return $Value.Offset -eq [TimeSpan]::Zero
    }
    if ($Value -isnot [string] -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        return $false
    }
    $parsed = [DateTimeOffset]::MinValue
    $valid = [DateTimeOffset]::TryParse(
        [string]$Value,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::RoundtripKind,
        [ref]$parsed
    )
    return ($valid -and $parsed.Offset -eq [TimeSpan]::Zero)
}

function ConvertTo-UtcIso8601String {
    param([Parameter(Mandatory = $true)][object]$Value)
    if ($Value -is [DateTime]) {
        return $Value.ToUniversalTime().ToString('o')
    }
    if ($Value -is [DateTimeOffset]) {
        return $Value.ToUniversalTime().ToString('o')
    }
    return [string]$Value
}

function Read-SourceDescriptor {
    param([Parameter(Mandatory = $true)][string]$Root)
    $descriptorPath = Join-Path $Root 'tools\codex_user_skills_manifest.json'
    if (-not (Test-Path -LiteralPath $descriptorPath -PathType Leaf)) {
        Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'The source descriptor is missing.'
    }
    try {
        $descriptor = Get-Content -LiteralPath $descriptorPath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'The source descriptor is not valid JSON.'
    }
    if (-not (Test-ObjectHasProperties -Value $descriptor -Names @(
        'schema_version', 'manager', 'bundle_name', 'bundle_version', 'primary_skills', 'managed_entries'
    ))) {
        Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'The source descriptor is missing a required field.'
    }
    if (
        -not (Test-JsonInteger -Value $descriptor.schema_version) -or
        $descriptor.schema_version -ne 1 -or
        $descriptor.manager -isnot [string] -or
        $descriptor.manager -ne $script:Manager -or
        $descriptor.bundle_name -isnot [string] -or
        [string]::IsNullOrWhiteSpace([string]$descriptor.bundle_name) -or
        -not (Test-JsonInteger -Value $descriptor.bundle_version) -or
        $descriptor.bundle_version -ne 1 -or
        $descriptor.primary_skills -isnot [System.Array] -or
        $descriptor.managed_entries -isnot [System.Array] -or
        -not (Test-StringArrayEqual -Left $descriptor.primary_skills -Right @('workflow-bootstrap', 'chatgpt-handoff-pilot')) -or
        @($descriptor.managed_entries).Count -ne 3
    ) {
        Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'The source descriptor schema or frozen bundle identity is invalid.'
    }

    $expected = [ordered]@{
        'workflow-bootstrap' = @('skills/workflow-bootstrap', 'skill', 'workflow-bootstrap')
        'chatgpt-handoff-pilot' = @('skills/chatgpt-handoff-pilot', 'skill', 'chatgpt-handoff-pilot')
        '_protocol' = @('skills/_protocol', 'dependency_container', $null)
    }
    $seen = @{}
    foreach ($entry in @($descriptor.managed_entries)) {
        if (-not (Test-ObjectHasProperties -Value $entry -Names @(
            'relative_source_path', 'relative_target_path', 'object_role', 'skill_name', 'dependency_of', 'included_files'
        ))) {
            Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'A source descriptor entry is missing a required field.'
        }
        if (
            $entry.relative_source_path -isnot [string] -or
            $entry.relative_target_path -isnot [string] -or
            $entry.object_role -isnot [string] -or
            ($null -ne $entry.skill_name -and $entry.skill_name -isnot [string]) -or
            $entry.dependency_of -isnot [System.Array] -or
            $entry.included_files -isnot [System.Array]
        ) {
            Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'A source descriptor entry has a wrong field type.'
        }
        $target = ConvertTo-NormalizedRelativePath -PathValue ([string]$entry.relative_target_path) -Condition 'CANONICAL_SOURCE_INVALID'
        $source = ConvertTo-NormalizedRelativePath -PathValue ([string]$entry.relative_source_path) -Condition 'CANONICAL_SOURCE_INVALID'
        if ($seen.ContainsKey($target) -or -not $expected.Contains($target)) {
            Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'The source descriptor has a duplicate or unexpected target.'
        }
        $seen[$target] = $true
        $contract = $expected[$target]
        if (
            $source -ne $contract[0] -or
            [string]$entry.object_role -ne $contract[1] -or
            [string]$entry.skill_name -ne [string]$contract[2]
        ) {
            Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'A source descriptor entry differs from the frozen V1 contract.'
        }
        if ($target -eq '_protocol') {
            if (
                -not (Test-StringArrayEqual -Left $entry.dependency_of -Right @('workflow-bootstrap', 'chatgpt-handoff-pilot')) -or
                -not (Test-StringArrayEqual -Left $entry.included_files -Right @('skill_assessment_output.md'))
            ) {
                Throw-ManagerError -Condition 'DEPENDENCY_CLOSURE_INVALID' -Message 'The shared dependency descriptor is incomplete.'
            }
        }
        elseif (@($entry.dependency_of).Count -ne 0 -or @($entry.included_files).Count -ne 0) {
            Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'A primary skill descriptor entry is not a full tree.'
        }
    }
    if ($seen.Count -ne $expected.Count) {
        Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'The source descriptor does not cover the frozen bundle.'
    }
    return [pscustomobject]@{ Path = $descriptorPath; Value = $descriptor }
}

function Get-FrontmatterName {
    param([Parameter(Mandatory = $true)][string]$SkillFile)
    $text = [System.IO.File]::ReadAllText($SkillFile, $script:Utf8NoBom)
    $match = [regex]::Match($text, '(?ms)\A---\s*\r?\n.*?^name:\s*["'']?([^"''\r\n]+)["'']?\s*$.*?^---\s*$')
    if (-not $match.Success) {
        Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'A canonical SKILL.md has invalid frontmatter.'
    }
    return $match.Groups[1].Value.Trim()
}

function Test-MarkdownDependencyClosure {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryRootValue,
        [Parameter(Mandatory = $true)][object[]]$Entries
    )
    $declaredFiles = @{}
    foreach ($entry in $Entries) {
        foreach ($file in @($entry.FileMap)) {
            $declaredFiles[$file.FullPath.ToLowerInvariant()] = $true
        }
    }

    foreach ($entry in @($Entries | Where-Object { $_.ObjectRole -eq 'skill' })) {
        $skillRoot = $entry.SourcePath
        foreach ($file in @($entry.FileMap | Where-Object { $_.RelativePath.EndsWith('.md', [System.StringComparison]::OrdinalIgnoreCase) })) {
            $text = [System.IO.File]::ReadAllText($file.FullPath, $script:Utf8NoBom)
            foreach ($match in [regex]::Matches($text, '\[[^\]]*\]\(([^)]+)\)')) {
                $link = $match.Groups[1].Value.Trim().Trim('<', '>')
                if (
                    [string]::IsNullOrWhiteSpace($link) -or
                    $link.StartsWith('#') -or
                    $link -match '^[A-Za-z][A-Za-z0-9+.-]*:'
                ) {
                    continue
                }
                $link = ($link -split '#', 2)[0]
                if ([string]::IsNullOrWhiteSpace($link) -or [System.IO.Path]::IsPathRooted($link) -or (Test-HasWildcard -Value $link)) {
                    Throw-ManagerError -Condition 'DEPENDENCY_CLOSURE_INVALID' -Message 'A Markdown payload link is unsafe.'
                }
                $candidate = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Path $file.FullPath -Parent) ($link.Replace('/', '\'))))
                if (-not (Test-PathInside -Candidate $candidate -Parent $RepositoryRootValue)) {
                    Throw-ManagerError -Condition 'DEPENDENCY_CLOSURE_INVALID' -Message 'A Markdown payload link escapes the repository.'
                }
                $item = Get-SafeItem -LiteralPath $candidate -BrokenCondition 'DEPENDENCY_CLOSURE_INVALID'
                if ($null -eq $item -or (Test-IsReparsePoint -Item $item)) {
                    Throw-ManagerError -Condition 'DEPENDENCY_CLOSURE_INVALID' -Message 'A Markdown payload link is missing or unsupported.'
                }
                if (-not (Test-PathInside -Candidate $candidate -Parent $skillRoot)) {
                    if ($item.PSIsContainer) {
                        $covered = @($declaredFiles.Keys | Where-Object { $_.StartsWith(($candidate.TrimEnd('\', '/') + '\').ToLowerInvariant()) }).Count -gt 0
                    }
                    else {
                        $covered = $declaredFiles.ContainsKey($candidate.ToLowerInvariant())
                    }
                    if (-not $covered) {
                        Throw-ManagerError -Condition 'DEPENDENCY_CLOSURE_INVALID' -Message 'A cross-directory Markdown dependency is undeclared.'
                    }
                }
            }
        }
    }
}

function Get-SourceBundle {
    param([Parameter(Mandatory = $true)][string]$Root)
    $repository = Get-NormalizedAbsolutePath -PathValue $Root -Condition 'CANONICAL_SOURCE_INVALID' -Label 'RepositoryRoot'
    if (-not (Test-Path -LiteralPath $repository -PathType Container)) {
        Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'RepositoryRoot is not a directory.'
    }
    $rootItem = Get-SafeItem -LiteralPath $repository -BrokenCondition 'CANONICAL_SOURCE_INVALID'
    if (Test-IsReparsePoint -Item $rootItem) {
        Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'RepositoryRoot cannot be a reparse point.'
    }
    $gitTop = Invoke-GitText -Root $repository -Arguments @('rev-parse', '--show-toplevel')
    $gitRoot = Get-NormalizedAbsolutePath -PathValue $gitTop.Text -Condition 'CANONICAL_SOURCE_INVALID' -Label 'Git repository root'
    if (-not (Test-PathEqual -Left $repository -Right $gitRoot)) {
        Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'RepositoryRoot must be the Git top level.'
    }
    $commitResult = Invoke-GitText -Root $repository -Arguments @('rev-parse', 'HEAD')
    if ($commitResult.Text -notmatch '^[0-9a-fA-F]{40}$') {
        Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'The source commit is not a full commit ID.'
    }

    $descriptorResult = Read-SourceDescriptor -Root $repository
    $resolvedEntries = New-Object 'System.Collections.Generic.List[object]'
    foreach ($entry in @($descriptorResult.Value.managed_entries)) {
        $entryCondition = if ([string]$entry.object_role -eq 'dependency_container') {
            'DEPENDENCY_CLOSURE_INVALID'
        }
        else {
            'CANONICAL_SOURCE_INVALID'
        }
        $sourceRelative = ConvertTo-NormalizedRelativePath -PathValue ([string]$entry.relative_source_path) -Condition 'CANONICAL_SOURCE_INVALID'
        $targetRelative = ConvertTo-NormalizedRelativePath -PathValue ([string]$entry.relative_target_path) -Condition 'CANONICAL_SOURCE_INVALID'
        $sourcePath = [System.IO.Path]::GetFullPath((Join-Path $repository ($sourceRelative.Replace('/', '\'))))
        if (-not (Test-PathInside -Candidate $sourcePath -Parent $repository)) {
            Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'A source entry escapes RepositoryRoot.'
        }
        $included = @($entry.included_files | ForEach-Object { [string]$_ })
        $fileMap = @(Get-RegularFileMap -Root $sourcePath -IncludedFiles $included -UnsafeCondition $entryCondition)
        if ($entry.object_role -eq 'skill') {
            $skillFile = Join-Path $sourcePath 'SKILL.md'
            if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
                Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'A required canonical SKILL.md is missing.'
            }
            $frontmatterName = Get-FrontmatterName -SkillFile $skillFile
            if ($frontmatterName -ne [string]$entry.skill_name) {
                Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'A skill frontmatter name differs from its directory.'
            }
        }
        $resolvedEntries.Add([pscustomobject]@{
            RelativeSourcePath = $sourceRelative
            RelativeTargetPath = $targetRelative
            ObjectRole = [string]$entry.object_role
            SkillName = if ($null -eq $entry.skill_name) { $null } else { [string]$entry.skill_name }
            DependencyOf = @($entry.dependency_of | ForEach-Object { [string]$_ })
            IncludedFiles = $included
            SourcePath = $sourcePath
            FileMap = $fileMap
            SourceFingerprint = Get-TreeFingerprint -FileMap $fileMap
        })
    }

    $resolvedEntryArray = $resolvedEntries.ToArray()
    Test-MarkdownDependencyClosure -RepositoryRootValue $repository -Entries $resolvedEntryArray

    $trackedPaths = New-Object 'System.Collections.Generic.List[string]'
    $trackedPaths.Add('tools/codex_user_skills_manifest.json')
    foreach ($entry in $resolvedEntryArray) {
        foreach ($file in @($entry.FileMap)) {
            $trackedPaths.Add($file.FullPath.Substring($repository.Length).TrimStart('\', '/').Replace('\', '/'))
        }
    }
    foreach ($relativePath in @($trackedPaths.ToArray() | Sort-Object -Unique)) {
        $tracked = Invoke-GitText -Root $repository -Arguments @('ls-files', '--error-unmatch', '--', $relativePath) -AllowNonZero
        if ($tracked.ExitCode -ne 0) {
            Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'A managed source file is not tracked.'
        }
        $working = Invoke-GitText -Root $repository -Arguments @('diff', '--quiet', 'HEAD', '--', $relativePath) -AllowNonZero
        $staged = Invoke-GitText -Root $repository -Arguments @('diff', '--cached', '--quiet', 'HEAD', '--', $relativePath) -AllowNonZero
        if ($working.ExitCode -ne 0 -or $staged.ExitCode -ne 0) {
            Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'A managed source file is dirty relative to HEAD.'
        }
    }
    foreach ($entry in $resolvedEntryArray) {
        $untracked = Invoke-GitText -Root $repository -Arguments @('ls-files', '--others', '--exclude-standard', '--', $entry.RelativeSourcePath)
        if (-not [string]::IsNullOrWhiteSpace($untracked.Text)) {
            Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'A managed source tree contains untracked payload.'
        }
    }
    $descriptorUntracked = Invoke-GitText -Root $repository -Arguments @('ls-files', '--others', '--exclude-standard', '--', 'tools/codex_user_skills_manifest.json')
    if (-not [string]::IsNullOrWhiteSpace($descriptorUntracked.Text)) {
        Throw-ManagerError -Condition 'CANONICAL_SOURCE_INVALID' -Message 'The source descriptor is untracked.'
    }

    return [pscustomobject]@{
        RepositoryRoot = $repository
        SourceCommit = $commitResult.Text.ToLowerInvariant()
        Descriptor = $descriptorResult.Value
        Entries = $resolvedEntryArray
    }
}

function Resolve-TargetContext {
    param([Parameter(Mandatory = $true)][string]$RepositoryRootValue)
    $hasExplicit = Test-Path -LiteralPath 'Env:CODEX_HOME'
    if ($hasExplicit) {
        $rawCodexHome = [string]$env:CODEX_HOME
        if ([string]::IsNullOrWhiteSpace($rawCodexHome)) {
            Throw-ManagerError -Condition 'CODEX_HOME_UNRESOLVED' -Message 'CODEX_HOME is explicitly blank.'
        }
    }
    else {
        $profile = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
        if ([string]::IsNullOrWhiteSpace($profile)) {
            Throw-ManagerError -Condition 'CODEX_HOME_UNRESOLVED' -Message 'The user profile could not be resolved.'
        }
        $rawCodexHome = Join-Path $profile '.codex'
    }

    $codexHome = Get-NormalizedAbsolutePath -PathValue $rawCodexHome -Condition 'PATH_SAFETY_VIOLATION' -Label 'CODEX_HOME'
    $driveRoot = [System.IO.Path]::GetPathRoot($codexHome).TrimEnd('\', '/')
    if (Test-PathEqual -Left $codexHome.TrimEnd('\', '/') -Right $driveRoot) {
        Throw-ManagerError -Condition 'PATH_SAFETY_VIOLATION' -Message 'CODEX_HOME cannot be a drive root.'
    }
    $targetRoot = [System.IO.Path]::GetFullPath((Join-Path $codexHome 'skills')).TrimEnd('\', '/')
    $canonicalSkills = [System.IO.Path]::GetFullPath((Join-Path $RepositoryRootValue 'skills')).TrimEnd('\', '/')
    if (
        (Test-PathInside -Candidate $targetRoot -Parent $RepositoryRootValue) -or
        (Test-PathInside -Candidate $RepositoryRootValue -Parent $targetRoot) -or
        (Test-PathInside -Candidate $targetRoot -Parent $canonicalSkills) -or
        (Test-PathInside -Candidate $canonicalSkills -Parent $targetRoot)
    ) {
        Throw-ManagerError -Condition 'PATH_SAFETY_VIOLATION' -Message 'The target overlaps the repository or canonical skills source.'
    }

    foreach ($path in @($codexHome, $targetRoot)) {
        $item = Get-ItemIncludingBrokenLink -LiteralPath $path
        if ($null -ne $item -and (-not $item.PSIsContainer -or (Test-IsReparsePoint -Item $item))) {
            Throw-ManagerError -Condition 'PATH_SAFETY_VIOLATION' -Message 'CODEX_HOME or Target_Root is not a normal directory.'
        }
    }
    $existingAncestor = $codexHome
    while (-not (Test-Path -LiteralPath $existingAncestor)) {
        $parent = Split-Path -Path $existingAncestor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or (Test-PathEqual -Left $parent -Right $existingAncestor)) { break }
        $existingAncestor = $parent
    }
    if (Test-Path -LiteralPath $existingAncestor) {
        Assert-NoReparseAncestors -PathValue $existingAncestor -StopAt ([System.IO.Path]::GetPathRoot($existingAncestor).TrimEnd('\', '/'))
    }

    return [pscustomobject]@{
        CodexHome = $codexHome
        TargetRoot = $targetRoot
        ManifestPath = Join-Path $targetRoot $script:ManifestName
        LockPath = Join-Path $targetRoot $script:LockName
    }
}

function Get-ExpectedTargetPath {
    param(
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [Parameter(Mandatory = $true)][string]$RelativeTarget
    )
    $relative = ConvertTo-NormalizedRelativePath -PathValue $RelativeTarget
    $full = [System.IO.Path]::GetFullPath((Join-Path $TargetRoot ($relative.Replace('/', '\'))))
    if (-not (Test-PathInside -Candidate $full -Parent $TargetRoot)) {
        Throw-ManagerError -Condition 'PATH_SAFETY_VIOLATION' -Message 'A managed target escapes Target_Root.'
    }
    return $full
}

function Convert-ManifestEntryToComparable {
    param([Parameter(Mandatory = $true)][object]$Entry)
    return [pscustomobject]@{
        RelativeSourcePath = ConvertTo-NormalizedRelativePath -PathValue ([string]$Entry.relative_source_path) -Condition 'MANIFEST_INVALID'
        RelativeTargetPath = ConvertTo-NormalizedRelativePath -PathValue ([string]$Entry.relative_target_path) -Condition 'MANIFEST_INVALID'
        ObjectRole = [string]$Entry.object_role
        SkillName = if ($null -eq $Entry.skill_name) { $null } else { [string]$Entry.skill_name }
        DependencyOf = @($Entry.dependency_of | ForEach-Object { [string]$_ })
        IncludedFiles = @($Entry.included_files | ForEach-Object { [string]$_ })
        SourceFingerprint = [string]$Entry.source_fingerprint
        InstalledFingerprint = [string]$Entry.installed_fingerprint
    }
}

function Read-OwnershipManifest {
    param(
        [Parameter(Mandatory = $true)][object]$Target,
        [Parameter(Mandatory = $true)][object]$Source
    )
    if (-not (Test-Path -LiteralPath $Target.ManifestPath)) {
        return $null
    }
    $manifestItem = Get-SafeItem -LiteralPath $Target.ManifestPath -BrokenCondition 'MANIFEST_INVALID'
    if ($null -eq $manifestItem -or $manifestItem.PSIsContainer -or (Test-IsReparsePoint -Item $manifestItem)) {
        Throw-ManagerError -Condition 'MANIFEST_INVALID' -Message 'The ownership manifest is not a normal file.'
    }
    try {
        $rawBytes = [System.IO.File]::ReadAllBytes($Target.ManifestPath)
        $manifest = $script:Utf8NoBom.GetString($rawBytes) | ConvertFrom-Json
    }
    catch {
        Throw-ManagerError -Condition 'MANIFEST_INVALID' -Message 'The ownership manifest is corrupt.'
    }
    if (-not (Test-ObjectHasProperties -Value $manifest -Names @(
        'schema_version', 'manager', 'source_repository', 'source_commit', 'installed_at',
        'updated_at', 'target_root', 'managed_entries'
    ))) {
        Throw-ManagerError -Condition 'MANIFEST_INVALID' -Message 'The ownership manifest is missing a required field.'
    }
    if (
        -not (Test-JsonInteger -Value $manifest.schema_version) -or
        $manifest.schema_version -ne 1 -or
        $manifest.manager -isnot [string] -or
        $manifest.manager -ne $script:Manager -or
        $manifest.source_repository -isnot [string] -or
        $manifest.source_repository -ne 'ai-skill-hub' -or
        $manifest.source_commit -isnot [string] -or
        [string]$manifest.source_commit -notmatch '^[0-9a-f]{40}$' -or
        -not (Test-UtcIso8601 -Value $manifest.installed_at) -or
        -not (Test-UtcIso8601 -Value $manifest.updated_at) -or
        $manifest.target_root -isnot [string] -or
        $manifest.managed_entries -isnot [System.Array] -or
        @($manifest.managed_entries).Count -ne @($Source.Entries).Count
    ) {
        Throw-ManagerError -Condition 'MANIFEST_INVALID' -Message 'The ownership manifest schema or identity is invalid.'
    }
    try {
        $manifestTarget = Get-NormalizedAbsolutePath -PathValue ([string]$manifest.target_root) -Condition 'MANIFEST_TARGET_MISMATCH' -Label 'Manifest target_root'
    }
    catch {
        throw
    }
    if (-not (Test-PathEqual -Left $manifestTarget -Right $Target.TargetRoot)) {
        Throw-ManagerError -Condition 'MANIFEST_TARGET_MISMATCH' -Message 'The ownership manifest target does not match Target_Root.'
    }

    $byTarget = @{}
    foreach ($rawEntry in @($manifest.managed_entries)) {
        if (-not (Test-ObjectHasProperties -Value $rawEntry -Names @(
            'relative_source_path', 'relative_target_path', 'object_role', 'skill_name',
            'dependency_of', 'included_files', 'source_fingerprint', 'installed_fingerprint'
        ))) {
            Throw-ManagerError -Condition 'MANIFEST_INVALID' -Message 'An ownership manifest entry is missing a required field.'
        }
        if (
            $rawEntry.relative_source_path -isnot [string] -or
            $rawEntry.relative_target_path -isnot [string] -or
            $rawEntry.object_role -isnot [string] -or
            ($null -ne $rawEntry.skill_name -and $rawEntry.skill_name -isnot [string]) -or
            $rawEntry.dependency_of -isnot [System.Array] -or
            $rawEntry.included_files -isnot [System.Array] -or
            $rawEntry.source_fingerprint -isnot [string] -or
            $rawEntry.installed_fingerprint -isnot [string]
        ) {
            Throw-ManagerError -Condition 'MANIFEST_INVALID' -Message 'An ownership manifest entry has a wrong field type.'
        }
        $entry = Convert-ManifestEntryToComparable -Entry $rawEntry
        if (
            $byTarget.ContainsKey($entry.RelativeTargetPath) -or
            $entry.SourceFingerprint -notmatch '^[0-9a-f]{64}$' -or
            $entry.InstalledFingerprint -notmatch '^[0-9a-f]{64}$'
        ) {
            Throw-ManagerError -Condition 'MANIFEST_INVALID' -Message 'The ownership manifest has a duplicate target or malformed fingerprint.'
        }
        $byTarget[$entry.RelativeTargetPath] = $entry
    }
    foreach ($sourceEntry in @($Source.Entries)) {
        if (-not $byTarget.ContainsKey($sourceEntry.RelativeTargetPath)) {
            Throw-ManagerError -Condition 'MANIFEST_INVALID' -Message 'The ownership manifest is incomplete.'
        }
        $manifestEntry = $byTarget[$sourceEntry.RelativeTargetPath]
        if (
            $manifestEntry.RelativeSourcePath -ne $sourceEntry.RelativeSourcePath -or
            $manifestEntry.ObjectRole -ne $sourceEntry.ObjectRole -or
            [string]$manifestEntry.SkillName -ne [string]$sourceEntry.SkillName -or
            -not (Test-StringArrayEqual -Left $manifestEntry.DependencyOf -Right $sourceEntry.DependencyOf) -or
            -not (Test-StringArrayEqual -Left $manifestEntry.IncludedFiles -Right $sourceEntry.IncludedFiles)
        ) {
            Throw-ManagerError -Condition 'MANIFEST_INVALID' -Message 'The ownership manifest differs from the full source descriptor.'
        }
    }
    return [pscustomobject]@{
        Value = $manifest
        RawBytes = $rawBytes
        EntriesByTarget = $byTarget
    }
}

function Get-InstalledEntryState {
    param(
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [Parameter(Mandatory = $true)][object]$SourceEntry
    )
    $path = Get-ExpectedTargetPath -TargetRoot $TargetRoot -RelativeTarget $SourceEntry.RelativeTargetPath
    if (-not (Test-Path -LiteralPath $path)) {
        $parent = Split-Path -Path $path -Parent
        $leaf = Split-Path -Path $path -Leaf
        if (Test-Path -LiteralPath $parent -PathType Container) {
            $namedItem = @(Get-ChildItem -LiteralPath $parent -Force -ErrorAction SilentlyContinue | Where-Object {
                [string]::Equals($_.Name, $leaf, [System.StringComparison]::OrdinalIgnoreCase)
            })
            if ($namedItem.Count -gt 0 -and (Test-IsReparsePoint -Item $namedItem[0])) {
                Throw-ManagerError -Condition 'BROKEN_LINK' -Message 'A managed target is a broken link.'
            }
        }
        return [pscustomobject]@{ Exists = $false; Path = $path; Fingerprint = ''; Type = 'absent' }
    }
    $item = Get-SafeItem -LiteralPath $path
    if ($null -eq $item) {
        Throw-ManagerError -Condition 'BROKEN_LINK' -Message 'A managed target is a broken link.'
    }
    if (Test-IsReparsePoint -Item $item) {
        $resolvedTarget = $null
        if ($null -ne $item.PSObject.Properties['ResolvedTarget']) {
            $resolvedTarget = [string]$item.ResolvedTarget
        }
        elseif ($null -ne $item.PSObject.Properties['Target']) {
            $resolvedTarget = [string]@($item.Target)[0]
            if (-not [string]::IsNullOrWhiteSpace($resolvedTarget) -and -not [System.IO.Path]::IsPathRooted($resolvedTarget)) {
                $resolvedTarget = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Path $path -Parent) $resolvedTarget))
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($resolvedTarget) -and -not (Test-Path -LiteralPath $resolvedTarget)) {
            Throw-ManagerError -Condition 'BROKEN_LINK' -Message 'A managed target is a broken link.'
        }
        Throw-ManagerError -Condition 'UNKNOWN_PROVENANCE' -Message 'A managed target is a link or reparse point.'
    }
    if (-not $item.PSIsContainer) {
        Throw-ManagerError -Condition 'TARGET_CONFLICT' -Message 'A managed target is an unexpected file.'
    }
    $fileMap = @(Get-RegularFileMap -Root $path -UnsafeCondition 'UNKNOWN_PROVENANCE')
    return [pscustomobject]@{
        Exists = $true
        Path = $path
        Fingerprint = Get-TreeFingerprint -FileMap $fileMap
        Type = 'directory'
    }
}

function Get-ManagerArtifacts {
    param([Parameter(Mandatory = $true)][object]$Target)
    if (-not (Test-Path -LiteralPath $Target.TargetRoot -PathType Container)) {
        return @()
    }
    $artifacts = New-Object 'System.Collections.Generic.List[object]'
    foreach ($item in @(Get-ChildItem -LiteralPath $Target.TargetRoot -Force)) {
        if ($item.Name -eq $script:LockName) {
            $artifacts.Add([pscustomobject]@{ Type = 'lock'; Name = $item.Name })
        }
        elseif (
            $item.Name -like '.ai-skill-hub-staging-*' -or
            $item.Name -like '.ai-skill-hub-backup-*' -or
            $item.Name -like '.ai-skill-hub-transaction-*' -or
            $item.Name -like '.ai-skill-hub-user-skills.*.tmp' -or
            $item.Name -like '.ai-skill-hub-user-skills.*.bak'
        ) {
            $artifacts.Add([pscustomobject]@{ Type = 'stale'; Name = $item.Name })
        }
    }
    return $artifacts.ToArray()
}

function Get-Preflight {
    param(
        [Parameter(Mandatory = $true)][object]$Source,
        [Parameter(Mandatory = $true)][object]$Target,
        [Parameter(Mandatory = $true)][string]$RequestedAction
    )
    foreach ($sourceEntry in @($Source.Entries)) {
        [void](Get-ExpectedTargetPath -TargetRoot $Target.TargetRoot -RelativeTarget $sourceEntry.RelativeTargetPath)
    }

    $artifacts = @(Get-ManagerArtifacts -Target $Target)
    if (@($artifacts | Where-Object { $_.Type -eq 'lock' }).Count -gt 0) {
        Throw-ManagerError -Condition 'CONCURRENT_MANAGER_OPERATION' -Message 'Another manager operation holds the lock.'
    }
    if (@($artifacts | Where-Object { $_.Type -eq 'stale' }).Count -gt 0) {
        Throw-ManagerError -Condition 'STALE_TRANSACTION_ARTIFACT' -Message 'A stale manager transaction artifact requires review.'
    }

    $manifest = Read-OwnershipManifest -Target $Target -Source $Source
    $states = @{}
    $existingCount = 0
    foreach ($sourceEntry in @($Source.Entries)) {
        $state = Get-InstalledEntryState -TargetRoot $Target.TargetRoot -SourceEntry $sourceEntry
        $states[$sourceEntry.RelativeTargetPath] = $state
        if ($state.Exists) { $existingCount++ }
    }

    if ($null -eq $manifest) {
        if ($existingCount -gt 0) {
            Throw-ManagerError -Condition 'MANIFEST_MISSING' -Message 'Managed target names exist without an ownership manifest.'
        }
        return [pscustomobject]@{
            Status = 'NOT_INSTALLED'
            Manifest = $null
            States = $states
            ChangedEntries = @($Source.Entries)
        }
    }

    if ($existingCount -ne @($Source.Entries).Count) {
        Throw-ManagerError -Condition 'UNKNOWN_PROVENANCE' -Message 'The owned install is partial.'
    }
    foreach ($sourceEntry in @($Source.Entries)) {
        $state = $states[$sourceEntry.RelativeTargetPath]
        $ownedEntry = $manifest.EntriesByTarget[$sourceEntry.RelativeTargetPath]
        if ($state.Fingerprint -ne $ownedEntry.InstalledFingerprint) {
            Throw-ManagerError -Condition 'LOCAL_MODIFICATION' -Message 'A managed target differs from its installed fingerprint.'
        }
    }
    $changedEntries = @($Source.Entries | Where-Object {
        $manifest.EntriesByTarget[$_.RelativeTargetPath].SourceFingerprint -ne $_.SourceFingerprint
    })
    $status = if ($changedEntries.Count -eq 0) { 'CURRENT' } else { 'SOURCE_UPDATE_AVAILABLE' }
    return [pscustomobject]@{
        Status = $status
        Manifest = $manifest
        States = $states
        ChangedEntries = $changedEntries
    }
}

function Get-TargetStateSignature {
    param(
        [Parameter(Mandatory = $true)][object]$Source,
        [Parameter(Mandatory = $true)][object]$Target
    )
    $parts = New-Object 'System.Collections.Generic.List[string]'
    if (Test-Path -LiteralPath $Target.ManifestPath -PathType Leaf) {
        $parts.Add('manifest:' + (Get-Sha256File -Path $Target.ManifestPath))
    }
    else {
        $parts.Add('manifest:absent')
    }
    foreach ($entry in @($Source.Entries)) {
        $state = Get-InstalledEntryState -TargetRoot $Target.TargetRoot -SourceEntry $entry
        $parts.Add(('{0}:{1}:{2}' -f $entry.RelativeTargetPath, $state.Type, $state.Fingerprint))
    }
    foreach ($entry in @($Source.Entries)) {
        $parts.Add(('source:{0}:{1}' -f $entry.RelativeTargetPath, $entry.SourceFingerprint))
    }
    return Get-Sha256Bytes -Bytes $script:Utf8NoBom.GetBytes(($parts -join "`n"))
}

function New-BaseResult {
    param(
        [Parameter(Mandatory = $true)][string]$RequestedAction,
        [string]$SourceCommit = '',
        [string]$Status = 'NOT_INSTALLED'
    )
    return [ordered]@{
        Decision = ''
        Action = $RequestedAction
        Repository = 'ai-skill-hub'
        Source_Commit = $SourceCommit
        Codex_Home = '$CODEX_HOME'
        Target_Root = '$CODEX_HOME/skills'
        Requested_Skills = @('workflow-bootstrap', 'chatgpt-handoff-pilot')
        Resolved_Dependencies = @('_protocol/skill_assessment_output.md')
        Managed_Entries = @('workflow-bootstrap', 'chatgpt-handoff-pilot', '_protocol')
        Current_Status = $Status
        Planned_Actions = @()
        Conflict_Count = 0
        Changed_Count = 0
        Unchanged_Count = 0
        Rollback_Status = 'NOT_REQUIRED'
        Restart_Required = 'NO'
        Manifest_Status = 'ABSENT'
        Target_Writability = 'NOT_TESTED_NO_WRITE'
        System_Skill_Protection = 'ENFORCED'
        Local_Modification_Count = 0
        External_Verification_Required = 'YES'
        Message = ''
    }
}

function Write-Result {
    param(
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$Result,
        [Parameter(Mandatory = $true)][string]$Format
    )
    if ($Format -eq 'Json') {
        $json = ([pscustomobject]$Result | ConvertTo-Json -Depth 10)
        [Console]::Out.WriteLine($json)
        return
    }
    foreach ($key in $Result.Keys) {
        $value = $Result[$key]
        if ($value -is [System.Array]) {
            $value = @($value) -join ','
        }
        [Console]::Out.WriteLine(('{0}={1}' -f $key, [string]$value))
    }
}

function Write-Utf8NoBomFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Text
    )
    $stream = New-Object System.IO.FileStream($Path, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    try {
        $bytes = $script:Utf8NoBom.GetBytes($Text)
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
    }
    finally {
        $stream.Dispose()
    }
}

function Copy-EntryToStaging {
    param(
        [Parameter(Mandatory = $true)][object]$Entry,
        [Parameter(Mandatory = $true)][string]$StagingRoot
    )
    $entryStage = Join-Path $StagingRoot ($Entry.RelativeTargetPath.Replace('/', '\'))
    [System.IO.Directory]::CreateDirectory($entryStage) | Out-Null
    foreach ($file in @($Entry.FileMap)) {
        $destination = Join-Path $entryStage ($file.RelativePath.Replace('/', '\'))
        $parent = Split-Path -Path $destination -Parent
        [System.IO.Directory]::CreateDirectory($parent) | Out-Null
        [System.IO.File]::Copy($file.FullPath, $destination, $false)
    }
    $stagedMap = @(Get-RegularFileMap -Root $entryStage -UnsafeCondition 'UNEXPECTED_ERROR')
    if ((Get-TreeFingerprint -FileMap $stagedMap) -ne $Entry.SourceFingerprint) {
        Throw-ManagerError -Condition 'UNEXPECTED_ERROR' -Message 'A staged payload fingerprint does not match its source.'
    }
    return $entryStage
}

function New-OwnershipManifestObject {
    param(
        [Parameter(Mandatory = $true)][object]$Source,
        [Parameter(Mandatory = $true)][object]$Target,
        [Parameter(Mandatory = $true)][object]$Preflight
    )
    $now = [DateTime]::UtcNow.ToString('o')
    $installedAt = if ($null -ne $Preflight.Manifest) {
        ConvertTo-UtcIso8601String -Value $Preflight.Manifest.Value.installed_at
    }
    else {
        $now
    }
    $entries = New-Object 'System.Collections.Generic.List[object]'
    foreach ($entry in @($Source.Entries)) {
        $installedState = Get-InstalledEntryState -TargetRoot $Target.TargetRoot -SourceEntry $entry
        if (-not $installedState.Exists -or $installedState.Fingerprint -ne $entry.SourceFingerprint) {
            Throw-ManagerError -Condition 'UNEXPECTED_ERROR' -Message 'Final installed payload verification failed.'
        }
        $entries.Add([ordered]@{
            relative_source_path = $entry.RelativeSourcePath
            relative_target_path = $entry.RelativeTargetPath
            object_role = $entry.ObjectRole
            skill_name = $entry.SkillName
            dependency_of = @($entry.DependencyOf)
            included_files = @($entry.IncludedFiles)
            source_fingerprint = $entry.SourceFingerprint
            installed_fingerprint = $installedState.Fingerprint
        })
    }
    return [ordered]@{
        schema_version = 1
        manager = $script:Manager
        source_repository = 'ai-skill-hub'
        source_commit = $Source.SourceCommit
        installed_at = $installedAt
        updated_at = $now
        target_root = $Target.TargetRoot
        managed_entries = $entries.ToArray()
    }
}

function Write-OwnershipManifestAtomic {
    param(
        [Parameter(Mandatory = $true)][object]$Target,
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$Manifest
    )
    if (Test-Injected -Name 'ManifestWrite') {
        Throw-ManagerError -Condition 'UNEXPECTED_ERROR' -Message 'Injected manifest write failure.'
    }
    $temporaryPath = Join-Path $Target.TargetRoot ('.ai-skill-hub-user-skills.{0}.tmp' -f ([guid]::NewGuid().ToString('N')))
    $replaceBackupPath = Join-Path $Target.TargetRoot ('.ai-skill-hub-user-skills.{0}.bak' -f ([guid]::NewGuid().ToString('N')))
    $json = ([pscustomobject]$Manifest | ConvertTo-Json -Depth 10) + "`n"
    Write-Utf8NoBomFile -Path $temporaryPath -Text $json
    try {
        if (Test-Path -LiteralPath $Target.ManifestPath -PathType Leaf) {
            [System.IO.File]::Replace($temporaryPath, $Target.ManifestPath, $replaceBackupPath, $true)
        }
        else {
            [System.IO.File]::Move($temporaryPath, $Target.ManifestPath)
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
        if (Test-Path -LiteralPath $replaceBackupPath) {
            Remove-Item -LiteralPath $replaceBackupPath -Force
        }
    }
}

function Acquire-ManagerLock {
    param([Parameter(Mandatory = $true)][object]$Target)
    try {
        $stream = New-Object System.IO.FileStream($Target.LockPath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        $bytes = $script:Utf8NoBom.GetBytes(([string]$PID))
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
        return $stream
    }
    catch {
        Throw-ManagerError -Condition 'CONCURRENT_MANAGER_OPERATION' -Message 'The manager lock could not be acquired.'
    }
}

function Remove-EmptyCreatedDirectories {
    param(
        [Parameter(Mandatory = $true)][object]$Target,
        [Parameter(Mandatory = $true)][bool]$CreatedTarget,
        [Parameter(Mandatory = $true)][bool]$CreatedHome
    )
    if ($CreatedTarget -and (Test-Path -LiteralPath $Target.TargetRoot -PathType Container)) {
        if (@(Get-ChildItem -LiteralPath $Target.TargetRoot -Force).Count -eq 0) {
            Remove-Item -LiteralPath $Target.TargetRoot -Force
        }
    }
    if ($CreatedHome -and (Test-Path -LiteralPath $Target.CodexHome -PathType Container)) {
        if (@(Get-ChildItem -LiteralPath $Target.CodexHome -Force).Count -eq 0) {
            Remove-Item -LiteralPath $Target.CodexHome -Force
        }
    }
}

function Test-Injected {
    param([Parameter(Mandatory = $true)][string]$Name)
    if ($env:AI_SKILL_HUB_TEST_MODE -ne '1') {
        return $false
    }
    $injections = @(([string]$env:AI_SKILL_HUB_TEST_INJECT) -split ',' | ForEach-Object { $_.Trim() })
    return $injections -contains $Name
}

function Assert-TargetWritable {
    param([Parameter(Mandatory = $true)][object]$Target)
    $probePath = Join-Path $Target.TargetRoot ('.ai-skill-hub-probe-{0}' -f ([guid]::NewGuid().ToString('N')))
    try {
        Write-Utf8NoBomFile -Path $probePath -Text 'probe'
    }
    catch {
        Throw-ManagerError -Condition 'TARGET_CONFLICT' -Message 'Target_Root is not writable for the requested action.'
    }
    finally {
        if (Test-Path -LiteralPath $probePath) {
            Remove-Item -LiteralPath $probePath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-Apply {
    param(
        [Parameter(Mandatory = $true)][object]$Source,
        [Parameter(Mandatory = $true)][object]$Target,
        [Parameter(Mandatory = $true)][object]$Preflight,
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$Result
    )
    if ($Preflight.Status -eq 'CURRENT') {
        $Result.Decision = 'NO_CHANGE_CODEX_USER_SKILLS_ALREADY_CURRENT'
        $Result.Unchanged_Count = @($Source.Entries).Count
        return
    }

    $beforeSignature = Get-TargetStateSignature -Source $Source -Target $Target
    $createdHome = -not (Test-Path -LiteralPath $Target.CodexHome)
    $createdTarget = -not (Test-Path -LiteralPath $Target.TargetRoot)
    $lockStream = $null
    $stagingRoot = $null
    $backupRoot = $null
    $transactionRoot = $null
    $movedNewTargets = New-Object 'System.Collections.Generic.List[string]'
    $backups = New-Object 'System.Collections.Generic.List[object]'
    $priorManifestBytes = if ($null -ne $Preflight.Manifest) { $Preflight.Manifest.RawBytes } else { $null }
    $mutationStarted = $false
    $rollbackFailed = $false

    try {
        if ($createdHome) { [System.IO.Directory]::CreateDirectory($Target.CodexHome) | Out-Null }
        if ($createdTarget) { [System.IO.Directory]::CreateDirectory($Target.TargetRoot) | Out-Null }
        $lockStream = Acquire-ManagerLock -Target $Target

        $afterSignature = Get-TargetStateSignature -Source $Source -Target $Target
        if ((Test-Injected -Name 'PostLockStateChange') -or $beforeSignature -ne $afterSignature) {
            Throw-ManagerError -Condition 'POST_LOCK_STATE_CHANGED' -Message 'Managed state changed after lock acquisition.'
        }

        Assert-TargetWritable -Target $Target
        $Result.Target_Writability = 'VERIFIED'

        $id = [guid]::NewGuid().ToString('N')
        $stagingRoot = Join-Path $Target.TargetRoot ('.ai-skill-hub-staging-{0}' -f $id)
        $backupRoot = Join-Path $Target.TargetRoot ('.ai-skill-hub-backup-{0}' -f $id)
        $transactionRoot = Join-Path $Target.TargetRoot ('.ai-skill-hub-transaction-{0}' -f $id)
        [System.IO.Directory]::CreateDirectory($stagingRoot) | Out-Null
        [System.IO.Directory]::CreateDirectory($backupRoot) | Out-Null
        [System.IO.Directory]::CreateDirectory($transactionRoot) | Out-Null
        Write-Utf8NoBomFile -Path (Join-Path $transactionRoot 'journal.json') -Text (([pscustomobject][ordered]@{
            action = 'Apply'
            entries = @($Preflight.ChangedEntries | ForEach-Object { $_.RelativeTargetPath })
        } | ConvertTo-Json -Depth 5) + "`n")

        foreach ($entry in @($Preflight.ChangedEntries)) {
            [void](Copy-EntryToStaging -Entry $entry -StagingRoot $stagingRoot)
        }
        if ($null -ne $priorManifestBytes) {
            [System.IO.File]::WriteAllBytes((Join-Path $backupRoot $script:ManifestName), $priorManifestBytes)
        }

        $moveIndex = 0
        foreach ($entry in @($Preflight.ChangedEntries)) {
            $targetPath = Get-ExpectedTargetPath -TargetRoot $Target.TargetRoot -RelativeTarget $entry.RelativeTargetPath
            $stagePath = Join-Path $stagingRoot ($entry.RelativeTargetPath.Replace('/', '\'))
            if (Test-Path -LiteralPath $targetPath) {
                $backupPath = Join-Path $backupRoot ($entry.RelativeTargetPath.Replace('/', '\'))
                [System.IO.Directory]::CreateDirectory((Split-Path -Path $backupPath -Parent)) | Out-Null
                [System.IO.Directory]::Move($targetPath, $backupPath)
                $backups.Add([pscustomobject]@{ Target = $targetPath; Backup = $backupPath; Fingerprint = $Preflight.States[$entry.RelativeTargetPath].Fingerprint })
                $mutationStarted = $true
                if (Test-Injected -Name 'ApplyAfterBackup') {
                    Throw-ManagerError -Condition 'UNEXPECTED_ERROR' -Message 'Injected Apply failure after backup.'
                }
            }
            [System.IO.Directory]::Move($stagePath, $targetPath)
            $movedNewTargets.Add($targetPath)
            $mutationStarted = $true
            $moveIndex++
            if ($moveIndex -eq 1 -and (Test-Injected -Name 'ApplyAfterFirstMove')) {
                Throw-ManagerError -Condition 'UNEXPECTED_ERROR' -Message 'Injected Apply failure.'
            }
        }

        $manifestObject = New-OwnershipManifestObject -Source $Source -Target $Target -Preflight $Preflight
        Write-OwnershipManifestAtomic -Target $Target -Manifest $manifestObject
        [void](Read-OwnershipManifest -Target $Target -Source $Source)
        foreach ($entry in @($Source.Entries)) {
            $finalState = Get-InstalledEntryState -TargetRoot $Target.TargetRoot -SourceEntry $entry
            if (-not $finalState.Exists -or $finalState.Fingerprint -ne $entry.SourceFingerprint) {
                Throw-ManagerError -Condition 'UNEXPECTED_ERROR' -Message 'Final Apply verification failed.'
            }
        }

        Remove-Item -LiteralPath $backupRoot -Recurse -Force
        Remove-Item -LiteralPath $transactionRoot -Recurse -Force
        if (Test-Path -LiteralPath $stagingRoot) { Remove-Item -LiteralPath $stagingRoot -Recurse -Force }
        $Result.Decision = 'PASS_CODEX_USER_SKILLS_APPLY'
        $Result.Changed_Count = @($Preflight.ChangedEntries).Count
        $Result.Unchanged_Count = @($Source.Entries).Count - @($Preflight.ChangedEntries).Count
        $Result.Manifest_Status = 'VALID'
        $Result.Restart_Required = 'YES'
    }
    catch {
        $originalException = $_.Exception
        if ($mutationStarted) {
            try {
                foreach ($newTarget in @($movedNewTargets.ToArray() | Select-Object -Last 100)) {
                    if (Test-Path -LiteralPath $newTarget) {
                        Remove-Item -LiteralPath $newTarget -Recurse -Force
                    }
                }
                if (Test-Injected -Name 'RollbackRestore') {
                    throw 'Injected rollback restore failure.'
                }
                foreach ($backup in $backups.ToArray()) {
                    if (Test-Path -LiteralPath $backup.Backup) {
                        [System.IO.Directory]::Move($backup.Backup, $backup.Target)
                    }
                    $restoredEntry = @($Source.Entries | Where-Object { (Get-ExpectedTargetPath -TargetRoot $Target.TargetRoot -RelativeTarget $_.RelativeTargetPath) -eq $backup.Target })[0]
                    $restored = Get-InstalledEntryState -TargetRoot $Target.TargetRoot -SourceEntry $restoredEntry
                    if (-not $restored.Exists -or $restored.Fingerprint -ne $backup.Fingerprint) {
                        throw 'Restored target fingerprint verification failed.'
                    }
                }
                if ($null -ne $priorManifestBytes) {
                    [System.IO.File]::WriteAllBytes($Target.ManifestPath, $priorManifestBytes)
                    if ((Get-Sha256Bytes -Bytes $priorManifestBytes) -ne (Get-Sha256File -Path $Target.ManifestPath)) {
                        throw 'Restored manifest byte verification failed.'
                    }
                }
                elseif (Test-Path -LiteralPath $Target.ManifestPath) {
                    Remove-Item -LiteralPath $Target.ManifestPath -Force
                }
                $Result.Rollback_Status = 'RESTORED'
            }
            catch {
                $rollbackFailed = $true
                $Result.Rollback_Status = 'FAILED_EVIDENCE_RETAINED'
            }
        }
        if (-not $rollbackFailed) {
            foreach ($artifact in @($stagingRoot, $backupRoot, $transactionRoot)) {
                if (-not [string]::IsNullOrWhiteSpace($artifact) -and (Test-Path -LiteralPath $artifact)) {
                    Remove-Item -LiteralPath $artifact -Recurse -Force
                }
            }
        }
        if ($rollbackFailed) {
            throw (New-ManagerException -Condition 'ROLLBACK_FAILURE' -Message 'Apply rollback could not be verified; recovery evidence was retained.')
        }
        throw $originalException
    }
    finally {
        if ($null -ne $lockStream) {
            $lockStream.Dispose()
        }
        if (Test-Path -LiteralPath $Target.LockPath) {
            Remove-Item -LiteralPath $Target.LockPath -Force -ErrorAction SilentlyContinue
        }
        if (-not $mutationStarted -or $Result.Rollback_Status -eq 'RESTORED') {
            Remove-EmptyCreatedDirectories -Target $Target -CreatedTarget $createdTarget -CreatedHome $createdHome
        }
    }
}

function Get-UnrelatedSnapshot {
    param(
        [Parameter(Mandatory = $true)][object]$Target,
        [Parameter(Mandatory = $true)][object]$Source
    )
    if (-not (Test-Path -LiteralPath $Target.TargetRoot -PathType Container)) { return @() }
    $managed = @($Source.Entries | ForEach-Object { $_.RelativeTargetPath.ToLowerInvariant() })
    $records = New-Object 'System.Collections.Generic.List[string]'
    foreach ($item in @(Get-ChildItem -LiteralPath $Target.TargetRoot -Force)) {
        if (
            $managed -contains $item.Name.ToLowerInvariant() -or
            $item.Name -eq $script:ManifestName -or
            $item.Name -eq $script:LockName -or
            $item.Name -like '.ai-skill-hub-*'
        ) {
            continue
        }
        if ([string]::Equals($item.Name, '.system', [System.StringComparison]::OrdinalIgnoreCase)) {
            $records.Add('.system|protected')
            continue
        }
        if (Test-IsReparsePoint -Item $item) {
            $records.Add(($item.Name + '|reparse'))
            continue
        }
        if ($item.PSIsContainer) {
            $map = @(Get-RegularFileMap -Root $item.FullName -UnsafeCondition 'UNKNOWN_PROVENANCE')
            $records.Add(($item.Name + '|directory|' + (Get-TreeFingerprint -FileMap $map)))
        }
        else {
            $records.Add(($item.Name + '|file|' + (Get-Sha256File -Path $item.FullName)))
        }
    }
    return @($records.ToArray() | Sort-Object)
}

function Invoke-Uninstall {
    param(
        [Parameter(Mandatory = $true)][object]$Source,
        [Parameter(Mandatory = $true)][object]$Target,
        [Parameter(Mandatory = $true)][object]$Preflight,
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$Result
    )
    if ($Preflight.Status -eq 'NOT_INSTALLED') {
        $Result.Decision = 'NO_CHANGE_CODEX_USER_SKILLS_NOT_INSTALLED'
        return
    }

    $beforeSignature = Get-TargetStateSignature -Source $Source -Target $Target
    $unrelatedBefore = @(Get-UnrelatedSnapshot -Target $Target -Source $Source)
    $lockStream = $null
    $backupRoot = $null
    $transactionRoot = $null
    $backups = New-Object 'System.Collections.Generic.List[object]'
    $priorManifestBytes = $Preflight.Manifest.RawBytes
    $mutationStarted = $false
    $rollbackFailed = $false

    try {
        $lockStream = Acquire-ManagerLock -Target $Target
        $afterSignature = Get-TargetStateSignature -Source $Source -Target $Target
        if ((Test-Injected -Name 'PostLockStateChange') -or $beforeSignature -ne $afterSignature) {
            Throw-ManagerError -Condition 'POST_LOCK_STATE_CHANGED' -Message 'Managed state changed after lock acquisition.'
        }
        Assert-TargetWritable -Target $Target
        $Result.Target_Writability = 'VERIFIED'

        $id = [guid]::NewGuid().ToString('N')
        $backupRoot = Join-Path $Target.TargetRoot ('.ai-skill-hub-backup-{0}' -f $id)
        $transactionRoot = Join-Path $Target.TargetRoot ('.ai-skill-hub-transaction-{0}' -f $id)
        [System.IO.Directory]::CreateDirectory($backupRoot) | Out-Null
        [System.IO.Directory]::CreateDirectory($transactionRoot) | Out-Null
        [System.IO.File]::WriteAllBytes((Join-Path $backupRoot $script:ManifestName), $priorManifestBytes)
        Write-Utf8NoBomFile -Path (Join-Path $transactionRoot 'journal.json') -Text (([pscustomobject][ordered]@{
            action = 'Uninstall'
            entries = @($Source.Entries | ForEach-Object { $_.RelativeTargetPath })
        } | ConvertTo-Json -Depth 5) + "`n")

        $moveIndex = 0
        foreach ($entry in @($Source.Entries)) {
            $targetPath = Get-ExpectedTargetPath -TargetRoot $Target.TargetRoot -RelativeTarget $entry.RelativeTargetPath
            $backupPath = Join-Path $backupRoot ($entry.RelativeTargetPath.Replace('/', '\'))
            [System.IO.Directory]::CreateDirectory((Split-Path -Path $backupPath -Parent)) | Out-Null
            [System.IO.Directory]::Move($targetPath, $backupPath)
            $backups.Add([pscustomobject]@{
                Target = $targetPath
                Backup = $backupPath
                Fingerprint = $Preflight.States[$entry.RelativeTargetPath].Fingerprint
            })
            $mutationStarted = $true
            $moveIndex++
            if ($moveIndex -eq 1 -and (Test-Injected -Name 'UninstallAfterFirstMove')) {
                Throw-ManagerError -Condition 'UNEXPECTED_ERROR' -Message 'Injected Uninstall failure.'
            }
        }
        [System.IO.File]::Delete($Target.ManifestPath)

        foreach ($entry in @($Source.Entries)) {
            $targetPath = Get-ExpectedTargetPath -TargetRoot $Target.TargetRoot -RelativeTarget $entry.RelativeTargetPath
            if (Test-Path -LiteralPath $targetPath) {
                Throw-ManagerError -Condition 'UNEXPECTED_ERROR' -Message 'A managed target remained after Uninstall.'
            }
        }
        if (Test-Path -LiteralPath $Target.ManifestPath) {
            Throw-ManagerError -Condition 'UNEXPECTED_ERROR' -Message 'The ownership manifest remained after Uninstall.'
        }
        $unrelatedAfter = @(Get-UnrelatedSnapshot -Target $Target -Source $Source)
        if (-not (Test-StringArrayEqual -Left $unrelatedBefore -Right $unrelatedAfter)) {
            Throw-ManagerError -Condition 'UNEXPECTED_ERROR' -Message 'An unrelated target changed during Uninstall.'
        }

        Remove-Item -LiteralPath $backupRoot -Recurse -Force
        Remove-Item -LiteralPath $transactionRoot -Recurse -Force
        $Result.Decision = 'PASS_CODEX_USER_SKILLS_UNINSTALL'
        $Result.Changed_Count = @($Source.Entries).Count
        $Result.Manifest_Status = 'ABSENT'
        $Result.Restart_Required = 'YES'
    }
    catch {
        $originalException = $_.Exception
        if ($mutationStarted) {
            try {
                if (Test-Injected -Name 'RollbackRestore') {
                    throw 'Injected rollback restore failure.'
                }
                foreach ($backup in $backups.ToArray()) {
                    if (Test-Path -LiteralPath $backup.Backup) {
                        [System.IO.Directory]::Move($backup.Backup, $backup.Target)
                    }
                    $restoredEntry = @($Source.Entries | Where-Object { (Get-ExpectedTargetPath -TargetRoot $Target.TargetRoot -RelativeTarget $_.RelativeTargetPath) -eq $backup.Target })[0]
                    $restored = Get-InstalledEntryState -TargetRoot $Target.TargetRoot -SourceEntry $restoredEntry
                    if (-not $restored.Exists -or $restored.Fingerprint -ne $backup.Fingerprint) {
                        throw 'Restored uninstall target fingerprint verification failed.'
                    }
                }
                [System.IO.File]::WriteAllBytes($Target.ManifestPath, $priorManifestBytes)
                if ((Get-Sha256Bytes -Bytes $priorManifestBytes) -ne (Get-Sha256File -Path $Target.ManifestPath)) {
                    throw 'Restored uninstall manifest byte verification failed.'
                }
                $unrelatedAfterRollback = @(Get-UnrelatedSnapshot -Target $Target -Source $Source)
                if (-not (Test-StringArrayEqual -Left $unrelatedBefore -Right $unrelatedAfterRollback)) {
                    throw 'Unrelated target verification failed after rollback.'
                }
                $Result.Rollback_Status = 'RESTORED'
            }
            catch {
                $rollbackFailed = $true
                $Result.Rollback_Status = 'FAILED_EVIDENCE_RETAINED'
            }
        }
        if (-not $rollbackFailed) {
            foreach ($artifact in @($backupRoot, $transactionRoot)) {
                if (-not [string]::IsNullOrWhiteSpace($artifact) -and (Test-Path -LiteralPath $artifact)) {
                    Remove-Item -LiteralPath $artifact -Recurse -Force
                }
            }
        }
        if ($rollbackFailed) {
            throw (New-ManagerException -Condition 'ROLLBACK_FAILURE' -Message 'Uninstall rollback could not be verified; recovery evidence was retained.')
        }
        throw $originalException
    }
    finally {
        if ($null -ne $lockStream) {
            $lockStream.Dispose()
        }
        if (Test-Path -LiteralPath $Target.LockPath) {
            Remove-Item -LiteralPath $Target.LockPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-ManagerMain {
    $result = New-BaseResult -RequestedAction $Action
    $exitCode = 0
    try {
        $rootValue = if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) { Get-ScriptRepositoryRoot } else { $RepositoryRoot }
        $source = Get-SourceBundle -Root $rootValue
        $result.Source_Commit = $source.SourceCommit
        $target = Resolve-TargetContext -RepositoryRootValue $source.RepositoryRoot
        $preflight = Get-Preflight -Source $source -Target $target -RequestedAction $Action
        $result.Current_Status = $preflight.Status
        $result.Manifest_Status = if ($null -eq $preflight.Manifest) { 'ABSENT' } else { 'VALID' }

        if ($preflight.Status -eq 'CURRENT') {
            $result.Unchanged_Count = @($source.Entries).Count
        }

        switch ($Action) {
            'Check' {
                if ($preflight.Status -eq 'CURRENT') {
                    $result.Decision = 'NO_CHANGE_CODEX_USER_SKILLS_ALREADY_CURRENT'
                }
                else {
                    $result.Decision = 'PASS_CODEX_USER_SKILLS_CHECK'
                }
            }
            'Plan' {
                if ($preflight.Status -eq 'CURRENT') {
                    $result.Decision = 'NO_CHANGE_CODEX_USER_SKILLS_ALREADY_CURRENT'
                }
                else {
                    $result.Decision = 'PASS_CODEX_USER_SKILLS_PLAN'
                    if ($preflight.Status -eq 'NOT_INSTALLED') {
                        $result.Planned_Actions = @(
                            'create target directories if absent',
                            'acquire manager lock',
                            'post-lock revalidate',
                            'stage 3 managed entries',
                            'install 3 managed entries',
                            'write ownership manifest last',
                            'verify and cleanup'
                        )
                    }
                    else {
                        $result.Planned_Actions = @(
                            'acquire manager lock',
                            'post-lock revalidate',
                            ('stage {0} changed managed entries' -f @($preflight.ChangedEntries).Count),
                            ('replace {0} owned managed entries' -f @($preflight.ChangedEntries).Count),
                            'write ownership manifest last',
                            'verify and cleanup'
                        )
                    }
                }
            }
            'Apply' {
                Invoke-Apply -Source $source -Target $target -Preflight $preflight -Result $result
            }
            'Uninstall' {
                Invoke-Uninstall -Source $source -Target $target -Preflight $preflight -Result $result
            }
        }
    }
    catch {
        $condition = if ($_.Exception.Data.Contains('Condition')) { [string]$_.Exception.Data['Condition'] } else { 'UNEXPECTED_ERROR' }
        $decision = if ($_.Exception.Data.Contains('Decision')) { [string]$_.Exception.Data['Decision'] } else { $script:DecisionMap['UNEXPECTED_ERROR'] }
        $result.Decision = $decision
        $result.Message = if ($condition -eq 'ROLLBACK_FAILURE') {
            'Rollback failed; manager-owned recovery evidence was retained for manual review.'
        }
        else {
            'The requested action was blocked by a fail-closed safety check.'
        }
        if ($condition -eq 'LOCAL_MODIFICATION') {
            $result.Current_Status = 'LOCAL_MODIFICATION'
            $result.Local_Modification_Count = 1
        }
        elseif ($condition -eq 'MANIFEST_INVALID' -or $condition -eq 'MANIFEST_TARGET_MISMATCH') {
            $result.Current_Status = 'MANIFEST_INVALID'
            $result.Manifest_Status = 'INVALID'
        }
        elseif ($condition -in @('TARGET_CONFLICT', 'UNKNOWN_PROVENANCE', 'BROKEN_LINK', 'MANIFEST_MISSING')) {
            $result.Current_Status = 'TARGET_CONFLICT'
            $result.Conflict_Count = 1
        }
        if ($condition -eq 'ROLLBACK_FAILURE' -or $condition -eq 'UNEXPECTED_ERROR') {
            $exitCode = 3
        }
        else {
            $exitCode = 2
        }
        if ($OutputFormat -eq 'Text') {
            [Console]::Error.WriteLine(('Condition={0}' -f $condition))
        }
        else {
            [Console]::Error.WriteLine(('Manager condition: {0}' -f $condition))
        }
    }

    Write-Result -Result $result -Format $OutputFormat
    return $exitCode
}

exit (Invoke-ManagerMain)
