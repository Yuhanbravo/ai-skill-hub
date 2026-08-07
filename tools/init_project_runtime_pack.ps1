[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [ValidateSet('Submodule', 'ExternalPath')]
    [string]$HubMode = 'Submodule',

    [string]$HubUrl,

    [string]$HubRef = 'main',

    [string]$HubPath = '.ai/ai-skill-hub',

    [ValidateSet('ManagedBlock', 'Fail')]
    [string]$ExistingFilePolicy = 'ManagedBlock',

    [switch]$DryRun
)

# ai-skill-hub Project Runtime Pack MVP V1 initializer.
# Frozen contract: docs/design/project_runtime_pack_mvp_v1_design_contract.md
# Windows + PowerShell 7.4+ + Git 2.40+ only. Fail closed on any ambiguity.

if ($PSVersionTable.PSVersion -lt [version]'7.4.0') {
    [Console]::Error.WriteLine('FAIL: init_project_runtime_pack.ps1 requires PowerShell 7.4.0 or later.')
    [Console]::Out.WriteLine('Decision=BLOCKED_UNEXPECTED_ERROR')
    [Console]::Out.WriteLine('Project_Root=')
    [Console]::Out.WriteLine("Hub_Mode=$HubMode")
    [Console]::Out.WriteLine('Hub_Path=')
    [Console]::Out.WriteLine('Hub_Url=')
    [Console]::Out.WriteLine("Requested_Ref=$HubRef")
    [Console]::Out.WriteLine('Resolved_Commit=')
    [Console]::Out.WriteLine('Planned_Actions=')
    [Console]::Out.WriteLine('Changed_Count=0')
    [Console]::Out.WriteLine('Index_Change=NO')
    [Console]::Out.WriteLine('Working_Tree_Change=NO')
    [Console]::Out.WriteLine('Rollback_Status=NOT_REQUIRED')
    [Console]::Out.WriteLine('Manifest_Status=ABSENT')
    [Console]::Out.WriteLine('Message=PowerShell 7.4.0 or later is required.')
    exit 2
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:BoundParams = $PSBoundParameters

$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$script:Utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
try {
    [Console]::OutputEncoding = $script:Utf8NoBom
}
catch {
    # Result lines are ASCII-safe; file artifacts always use the explicit encoder.
}

$script:GeneratorId = 'ai-skill-hub.project-runtime-pack'
$script:SubmoduleName = 'ai-skill-hub'
$script:StartMarker = '<!-- ai-skill-hub:runtime-pack:start schema=v1 -->'
$script:EndMarker = '<!-- ai-skill-hub:runtime-pack:end -->'
$script:MarkerPrefix = '<!-- ai-skill-hub:runtime-pack:'
$script:ManifestRelPath = '.ai/runtime-pack.json'
$script:ManagedTextHashAlgorithm = 'sha256'
$script:ManagedTextHashNormalization = 'utf8-lf-v1'

$script:DecisionMap = @{
    NOT_GIT_REPOSITORY = 'BLOCKED_NOT_GIT_REPOSITORY'
    PROJECT_NOT_ROOT = 'BLOCKED_PROJECT_NOT_ROOT'
    GIT_OPERATION_ACTIVE = 'BLOCKED_GIT_OPERATION_ACTIVE'
    DIRTY_WORKTREE = 'BLOCKED_DIRTY_WORKTREE'
    STAGED_CHANGES = 'BLOCKED_STAGED_CHANGES'
    GIT_SAFE_DIRECTORY = 'BLOCKED_GIT_SAFE_DIRECTORY'
    PATH_SAFETY_VIOLATION = 'BLOCKED_PATH_SAFETY_VIOLATION'
    HUB_PATH_CONFLICT = 'BLOCKED_HUB_PATH_CONFLICT'
    SUBMODULE_CONFLICT = 'BLOCKED_SUBMODULE_CONFLICT'
    EXTERNAL_PATH_INVALID = 'BLOCKED_EXTERNAL_PATH_INVALID'
    REF_INVALID = 'BLOCKED_REF_INVALID'
    REF_NOT_FOUND = 'BLOCKED_REF_NOT_FOUND'
    REF_AMBIGUOUS = 'BLOCKED_REF_AMBIGUOUS'
    CREDENTIAL_OR_TRANSPORT = 'BLOCKED_CREDENTIAL_OR_TRANSPORT'
    EXISTING_FILE = 'BLOCKED_EXISTING_FILE'
    MANAGED_BLOCK_INVALID = 'BLOCKED_MANAGED_BLOCK_INVALID'
    UNKNOWN_MANAGED_BLOCK_PROVENANCE = 'BLOCKED_UNKNOWN_MANAGED_BLOCK_PROVENANCE'
    MANAGED_CONTENT_MODIFIED = 'BLOCKED_MANAGED_CONTENT_MODIFIED'
    TEXT_FORMAT_UNSUPPORTED = 'BLOCKED_TEXT_FORMAT_UNSUPPORTED'
    MANIFEST_INVALID = 'BLOCKED_MANIFEST_INVALID'
    MANIFEST_UNKNOWN_FIELD = 'BLOCKED_MANIFEST_UNKNOWN_FIELD'
    SCHEMA_INCOMPATIBLE = 'BLOCKED_SCHEMA_INCOMPATIBLE'
    RUNTIME_PACK_MISMATCH = 'BLOCKED_RUNTIME_PACK_MISMATCH'
    UPGRADE_REQUIRED = 'BLOCKED_UPGRADE_REQUIRED'
    CANONICAL_INDEX_MISSING = 'BLOCKED_CANONICAL_INDEX_MISSING'
    FAILED_APPLY_ROLLED_BACK = 'FAILED_APPLY_ROLLED_BACK'
    ROLLBACK_FAILURE = 'BLOCKED_ROLLBACK_FAILURE'
    CONCURRENT_STATE_CHANGE = 'BLOCKED_CONCURRENT_STATE_CHANGE'
    UNEXPECTED_ERROR = 'BLOCKED_UNEXPECTED_ERROR'
    INITIALIZED = 'PASS_PROJECT_RUNTIME_PACK_INITIALIZED'
    NO_CHANGE = 'NO_CHANGE_PROJECT_RUNTIME_PACK_ALREADY_CURRENT'
    DRY_RUN = 'PASS_PROJECT_RUNTIME_PACK_DRY_RUN'
}

function New-PackException {
    param(
        [Parameter(Mandatory = $true)][string]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if (-not $script:DecisionMap.Contains($Condition)) {
        $Condition = 'UNEXPECTED_ERROR'
    }
    $exception = New-Object System.InvalidOperationException($Message)
    $exception.Data['Condition'] = $Condition
    $exception.Data['Decision'] = $script:DecisionMap[$Condition]
    return $exception
}

function Throw-PackError {
    param(
        [Parameter(Mandatory = $true)][string]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )
    throw (New-PackException -Condition $Condition -Message $Message)
}

function Write-PackDiagnostic {
    param([Parameter(Mandatory = $true)][string]$Message)
    [Console]::Error.WriteLine($Message)
}

$script:Result = [ordered]@{
    Decision = ''
    Project_Root = ''
    Hub_Mode = $HubMode
    Hub_Path = ''
    Hub_Url = ''
    Requested_Ref = $HubRef
    Resolved_Commit = ''
    Planned_Actions = ''
    Changed_Count = 0
    Index_Change = 'NO'
    Working_Tree_Change = 'NO'
    Rollback_Status = 'NOT_REQUIRED'
    Manifest_Status = 'ABSENT'
    Message = ''
}

function Write-PackResult {
    foreach ($key in @(
        'Decision', 'Project_Root', 'Hub_Mode', 'Hub_Path', 'Hub_Url',
        'Requested_Ref', 'Resolved_Commit', 'Planned_Actions', 'Changed_Count',
        'Index_Change', 'Working_Tree_Change', 'Rollback_Status',
        'Manifest_Status', 'Message'
    )) {
        $value = [string]$script:Result[$key]
        $value = $value.Replace("`r", ' ').Replace("`n", ' ')
        [Console]::Out.WriteLine("$key=$value")
    }
}

# ---------------------------------------------------------------------------
# Frozen generated content (Design Contract Appendix A and B, canonical LF).
# ---------------------------------------------------------------------------

$script:BlockBodies = @{
    agents = @(
        $script:StartMarker
        '## AI Skill Hub Runtime Pack'
        ''
        '- Runtime manifest: `.ai/runtime-pack.json`'
        '- Shared router: `.agents/skills/ai-skill-hub-router/SKILL.md`'
        '- Read the router before selecting hub guidance; the router locates canonical Skills through the manifest and canonical index.'
        '- Keep this entry thin. Do not copy canonical Skill bodies into this project.'
        '- If the manifest, hub commit, index, router, or selected Skill is missing or inconsistent, stop and report the mismatch.'
        $script:EndMarker
    ) -join "`n"
    claude = @(
        $script:StartMarker
        '## AI Skill Hub Runtime Pack'
        ''
        '- Follow `AGENTS.md` for shared project entry guidance.'
        '- Runtime manifest: `.ai/runtime-pack.json`'
        '- Claude router: `.claude/skills/ai-skill-hub-router/SKILL.md`'
        '- Read the router before selecting hub guidance. Do not copy canonical Skill bodies into this file.'
        '- If the manifest, hub commit, index, router, or selected Skill is missing or inconsistent, stop and report the mismatch.'
        $script:EndMarker
    ) -join "`n"
    copilot = @(
        $script:StartMarker
        '## AI Skill Hub Runtime Pack'
        ''
        '- Follow `AGENTS.md` first for shared project guidance.'
        '- Runtime manifest: `.ai/runtime-pack.json`'
        '- Shared router: `.agents/skills/ai-skill-hub-router/SKILL.md`'
        '- Use the router to locate canonical Skills; do not duplicate their bodies in Copilot instructions.'
        '- If the manifest, hub commit, index, router, or selected Skill is missing or inconsistent, stop and report the mismatch.'
        $script:EndMarker
    ) -join "`n"
}

$script:RouterTemplate = @(
    '---'
    'name: ai-skill-hub-router'
    'description: "Locate and load the appropriate canonical ai-skill-hub Skill for this project. Use when a task may benefit from reusable hub guidance or explicitly names a hub Skill."'
    '---'
    ''
    '# AI Skill Hub Router'
    ''
    'This router is read-only. It may discover, route, reference, and load guidance, but it must not modify the project, initialize a submodule, fetch, or update the hub.'
    ''
    '## Route'
    ''
    '1. Locate the Git project root and read `../../../.ai/runtime-pack.json` relative to this Skill directory.'
    '2. Require schema version `1`, generator `ai-skill-hub.project-runtime-pack` version `1`, the exact five adapter records, and this router''s matching generated-file hash. On failure, stop with `ROUTER_MANIFEST_INVALID`.'
    '3. Resolve `hub.path` and `routing.canonical_index` exactly as recorded. Reject path escape, unknown mode, or an index outside the resolved hub.'
    '4. For `submodule`, require the committed superproject gitlink to equal `hub.resolved_commit`, and require the materialized hub HEAD to equal that same commit. If the checkout is absent, stop with `ROUTER_HUB_NOT_MATERIALIZED`; if versions differ, stop with `ROUTER_HUB_VERSION_MISMATCH`.'
    '5. For `external-path`, require the external Git worktree HEAD to equal `hub.resolved_commit`; otherwise stop with `ROUTER_HUB_VERSION_MISMATCH`.'
    '6. Read the canonical `SKILLS_INDEX.md`. If it is missing, stop with `ROUTER_INDEX_MISSING`.'
    '7. If the user explicitly names a Skill, require an exact indexed name. Otherwise use the index category, use scenario, name, and per-Skill overview, and select only when exactly one Skill is a clear match. Use `ROUTER_NO_MATCH` for none and `ROUTER_AMBIGUOUS_MATCH` for a tie.'
    '8. Resolve the indexed canonical path and require it to stay under `<hub>/skills/<skill-name>/SKILL.md`. On path escape or malformed index data, stop with `ROUTER_CANONICAL_PATH_INVALID`.'
    '9. Read the selected `SKILL.md` completely. If it is absent, stop with `ROUTER_SKILL_NOT_FOUND`. Read every supporting resource that the selected Skill requires; if one is absent, stop with `ROUTER_SUPPORTING_RESOURCE_MISSING`.'
    '10. Follow the selected canonical Skill together with the user''s authorization and project rules. The router itself grants no write or external-operation authority.'
    ''
    'Do not fall back to model memory, copied Skill text, a hub adapter, or an internet copy when any validation fails.'
) -join "`n"

$script:AdapterDefs = @(
    [ordered]@{ Id = 'agents-entry'; Path = 'AGENTS.md'; Management = 'managed-block'; Block = 'agents' }
    [ordered]@{ Id = 'claude-entry'; Path = 'CLAUDE.md'; Management = 'managed-block'; Block = 'claude' }
    [ordered]@{ Id = 'claude-router'; Path = '.claude/skills/ai-skill-hub-router/SKILL.md'; Management = 'generated-file'; Block = 'router' }
    [ordered]@{ Id = 'copilot-entry'; Path = '.github/copilot-instructions.md'; Management = 'managed-block'; Block = 'copilot' }
    [ordered]@{ Id = 'shared-router'; Path = '.agents/skills/ai-skill-hub-router/SKILL.md'; Management = 'generated-file'; Block = 'router' }
)

function Get-CanonicalContent {
    param([Parameter(Mandatory = $true)][string]$Block)
    if ($Block -eq 'router') {
        return $script:RouterTemplate + "`n"
    }
    return $script:BlockBodies[$Block] + "`n"
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

function Get-Sha256Text {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text)
    return Get-Sha256Bytes -Bytes ($script:Utf8NoBom.GetBytes($Text))
}

function ConvertTo-Utf8LfV1 {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text)
    return $Text.Replace("`r`n", "`n").Replace("`r", "`n")
}

function Get-Sha256NormalizedText {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text)
    return Get-Sha256Text -Text (ConvertTo-Utf8LfV1 -Text $Text)
}

function Get-Sha256File {
    param([Parameter(Mandatory = $true)][string]$Path)
    return Get-Sha256Bytes -Bytes ([System.IO.File]::ReadAllBytes($Path))
}

function Get-ContentHash {
    param([Parameter(Mandatory = $true)][string]$Block)
    return Get-Sha256NormalizedText -Text (Get-CanonicalContent -Block $Block)
}

# ---------------------------------------------------------------------------
# Path helpers
# ---------------------------------------------------------------------------

function Test-HasWildcard {
    param([Parameter(Mandatory = $true)][string]$Value)
    return $Value.IndexOfAny([char[]]'*?[]') -ge 0
}

function Get-FullPathSafe {
    param(
        [Parameter(Mandatory = $true)][string]$PathValue,
        [Parameter(Mandatory = $true)][string]$Condition,
        [Parameter(Mandatory = $true)][string]$Label
    )
    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        Throw-PackError -Condition $Condition -Message "$Label is blank."
    }
    if (Test-HasWildcard -Value $PathValue) {
        Throw-PackError -Condition $Condition -Message "$Label contains wildcard characters."
    }
    if ($PathValue.IndexOfAny([char[]]"`0") -ge 0) {
        Throw-PackError -Condition $Condition -Message "$Label contains a NUL character."
    }
    try {
        $full = [System.IO.Path]::GetFullPath($PathValue)
    }
    catch {
        Throw-PackError -Condition $Condition -Message "$Label could not be normalized."
    }
    return $full.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
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

function Test-IsReparsePoint {
    param([Parameter(Mandatory = $true)][string]$LiteralPath)
    try {
        $item = Get-Item -LiteralPath $LiteralPath -Force -ErrorAction Stop
    }
    catch {
        return $false
    }
    return (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
}

function Assert-NoReparseAncestors {
    param(
        [Parameter(Mandatory = $true)][string]$PathValue,
        [Parameter(Mandatory = $true)][string]$StopAt
    )
    $cursor = $PathValue
    while (-not [string]::IsNullOrWhiteSpace($cursor)) {
        if ((Test-Path -LiteralPath $cursor) -and (Test-IsReparsePoint -LiteralPath $cursor)) {
            Throw-PackError -Condition 'PATH_SAFETY_VIOLATION' -Message 'A target path ancestor is a reparse point.'
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

$script:ReservedDeviceNames = @(
    'CON', 'PRN', 'AUX', 'NUL',
    'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
    'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
)

function ConvertTo-SafeRelativePosixPath {
    param(
        [Parameter(Mandatory = $true)][string]$PathValue,
        [Parameter(Mandatory = $true)][string]$Condition,
        [Parameter(Mandatory = $true)][string]$Label
    )
    if ([string]::IsNullOrWhiteSpace($PathValue) -or (Test-HasWildcard -Value $PathValue)) {
        Throw-PackError -Condition $Condition -Message "$Label is blank or contains wildcards."
    }
    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        Throw-PackError -Condition $Condition -Message "$Label must be project-relative."
    }
    if ($PathValue -match '[\x00-\x1f]') {
        Throw-PackError -Condition $Condition -Message "$Label contains control characters."
    }
    $normalized = $PathValue.Replace('\', '/').Trim('/')
    $segments = @($normalized -split '/')
    if ($segments.Count -eq 0 -or $segments -contains '' -or $segments -contains '.' -or $segments -contains '..') {
        Throw-PackError -Condition $Condition -Message "$Label contains an unsafe segment."
    }
    foreach ($segment in $segments) {
        if ($segment.IndexOf(':') -ge 0) {
            Throw-PackError -Condition $Condition -Message "$Label contains a colon (drive or alternate data stream) segment."
        }
        if ([string]::Equals($segment, '.git', [System.StringComparison]::OrdinalIgnoreCase)) {
            Throw-PackError -Condition $Condition -Message "$Label cannot contain a .git segment."
        }
        if ($segment.EndsWith('.')) {
            Throw-PackError -Condition $Condition -Message "$Label contains a segment with a trailing dot."
        }
        if ($segment.EndsWith(' ')) {
            Throw-PackError -Condition $Condition -Message "$Label contains a segment with a trailing space."
        }
        $base = ($segment -split '\.')[0]
        if ($script:ReservedDeviceNames -contains $base.ToUpperInvariant()) {
            Throw-PackError -Condition $Condition -Message "$Label contains a reserved device name."
        }
    }
    return $normalized
}

# ---------------------------------------------------------------------------
# Git invocation
# ---------------------------------------------------------------------------

$script:GitExe = $null

function Resolve-Git {
    $commands = @(Get-Command git.exe -CommandType Application -ErrorAction SilentlyContinue)
    if ($commands.Count -eq 0) {
        Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'git.exe could not be resolved on PATH.'
    }
    $script:GitExe = [string]$commands[0].Source
}

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [string]$WorkingDirectory,
        [hashtable]$ExtraEnvironment,
        [switch]$AllowNonZero
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $script:GitExe
    foreach ($argument in $Arguments) {
        [void]$psi.ArgumentList.Add([string]$argument)
    }
    if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) {
        $psi.WorkingDirectory = $WorkingDirectory
    }
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = $script:Utf8NoBom
    $psi.StandardErrorEncoding = $script:Utf8NoBom
    $psi.Environment['GIT_TERMINAL_PROMPT'] = '0'
    if ($null -ne $ExtraEnvironment) {
        foreach ($key in $ExtraEnvironment.Keys) {
            $psi.Environment[$key] = [string]$ExtraEnvironment[$key]
        }
    }
    $process = [System.Diagnostics.Process]::Start($psi)
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    $stdout = $stdoutTask.Result
    $exitCode = $process.ExitCode
    $process.Dispose()
    if ($stderr -match 'detected dubious ownership') {
        Throw-PackError -Condition 'GIT_SAFE_DIRECTORY' -Message 'Git reported a safe.directory ownership error; fix the environment Git configuration (the initializer never edits Git config).'
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        StdOut = $stdout
        StdErr = $stderr
    }
}

function Invoke-GitChecked {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [string]$WorkingDirectory,
        [hashtable]$ExtraEnvironment,
        [Parameter(Mandatory = $true)][string]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )
    $result = Invoke-Git -Arguments $Arguments -WorkingDirectory $WorkingDirectory -ExtraEnvironment $ExtraEnvironment
    if ($result.ExitCode -ne 0) {
        Throw-PackError -Condition $Condition -Message $Message
    }
    return $result
}

function Get-GitSingleLine {
    param([Parameter(Mandatory = $true)][pscustomobject]$Result)
    return ($Result.StdOut -split "`n" | Select-Object -First 1).Trim()
}

# ---------------------------------------------------------------------------
# Existing text file analysis (UTF-8 / BOM / newline discipline)
# ---------------------------------------------------------------------------

function Read-ExistingTextFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $payload = $bytes
    if ($hasBom) {
        $payload = New-Object byte[] ($bytes.Length - 3)
        [Array]::Copy($bytes, 3, $payload, 0, $payload.Length)
    }
    try {
        $text = $script:Utf8Strict.GetString($payload)
    }
    catch {
        Throw-PackError -Condition 'TEXT_FORMAT_UNSUPPORTED' -Message "$Label is not valid UTF-8."
    }
    $crlfCount = ([regex]::Matches($text, "`r`n")).Count
    $stripped = $text.Replace("`r`n", '')
    $crCount = ([regex]::Matches($stripped, "`r")).Count
    $bareLf = ([regex]::Matches($stripped, "`n")).Count
    $newline = 'LF'
    if (($crlfCount -gt 0 -and ($bareLf -gt 0 -or $crCount -gt 0)) -or ($bareLf -gt 0 -and $crCount -gt 0)) {
        Throw-PackError -Condition 'TEXT_FORMAT_UNSUPPORTED' -Message "$Label mixes newline styles."
    }
    if ($crlfCount -gt 0) {
        $newline = 'CRLF'
    }
    elseif ($crCount -gt 0) {
        $newline = 'CR'
    }
    return [pscustomobject]@{
        Bytes = $bytes
        HasBom = $hasBom
        Text = $text
        Newline = $newline
    }
}

function Get-ManagedBlockInfo {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][string]$Label
    )
    $normalizedText = ConvertTo-Utf8LfV1 -Text $Text
    $endsWithLf = $normalizedText.EndsWith("`n")
    $lines = @($normalizedText -split "`n")
    if ($endsWithLf) {
        $lines = $lines[0..($lines.Count - 2)]
    }
    $startLike = New-Object 'System.Collections.Generic.List[int]'
    $endLike = New-Object 'System.Collections.Generic.List[int]'
    $startExact = New-Object 'System.Collections.Generic.List[int]'
    $endExact = New-Object 'System.Collections.Generic.List[int]'
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line.StartsWith($script:MarkerPrefix, [System.StringComparison]::Ordinal)) {
            if ($line.StartsWith($script:MarkerPrefix + 'start', [System.StringComparison]::Ordinal)) {
                $startLike.Add($i)
            }
            elseif ($line.StartsWith($script:MarkerPrefix + 'end', [System.StringComparison]::Ordinal)) {
                $endLike.Add($i)
            }
        }
        if ($line -ceq $script:StartMarker) {
            $startExact.Add($i)
        }
        if ($line -ceq $script:EndMarker) {
            $endExact.Add($i)
        }
    }
    if ($startLike.Count -eq 0 -and $endLike.Count -eq 0) {
        return [pscustomobject]@{ Kind = 'None'; StartLine = -1; EndLine = -1; CanonicalText = '' }
    }
    $invalid = $false
    if ($startLike.Count -ne 1 -or $endLike.Count -ne 1) {
        $invalid = $true
    }
    elseif ($startExact.Count -ne 1 -or $endExact.Count -ne 1) {
        $invalid = $true
    }
    elseif ($startExact[0] -gt $endExact[0]) {
        $invalid = $true
    }
    if ($invalid) {
        Throw-PackError -Condition 'MANAGED_BLOCK_INVALID' -Message "$Label has duplicate, nested, orphan, reversed, or non-v1 managed markers."
    }
    $blockLines = $lines[$startExact[0]..$endExact[0]]
    $canonical = ($blockLines -join "`n") + "`n"
    return [pscustomobject]@{
        Kind = 'Block'
        StartLine = $startExact[0]
        EndLine = $endExact[0]
        CanonicalText = $canonical
    }
}

function ConvertTo-HostNewline {
    param(
        [Parameter(Mandatory = $true)][string]$CanonicalText,
        [Parameter(Mandatory = $true)][string]$Newline
    )
    if ($Newline -eq 'CRLF') {
        return $CanonicalText.Replace("`n", "`r`n")
    }
    if ($Newline -eq 'CR') {
        return $CanonicalText.Replace("`n", "`r")
    }
    return $CanonicalText
}

# ---------------------------------------------------------------------------
# Atomic file writes
# ---------------------------------------------------------------------------

function Register-CreatedDirectories {
    # Records directories that this transaction is about to create (deepest
    # first input: the directory that must exist). Only directories that do
    # not exist yet and that sit strictly inside the project root are tracked;
    # pre-existing directories (empty or not) are never recorded and therefore
    # never removed by rollback.
    param([Parameter(Mandatory = $true)][string]$TargetDir)
    if ($null -eq $script:Ctx) {
        return
    }
    $chain = New-Object 'System.Collections.Generic.List[string]'
    $cursor = $TargetDir
    while (-not [string]::IsNullOrWhiteSpace($cursor)) {
        if (Test-PathEqual -Left $cursor -Right $script:Ctx.ProjectRoot) {
            break
        }
        if (-not (Test-PathInside -Candidate $cursor -Parent $script:Ctx.ProjectRoot)) {
            break
        }
        if (Test-Path -LiteralPath $cursor) {
            break
        }
        $chain.Add($cursor)
        $cursor = Split-Path -Path $cursor -Parent
    }
    foreach ($dir in $chain) {
        if (-not $script:Ctx.CreatedDirectories.Contains($dir)) {
            $script:Ctx.CreatedDirectories.Add($dir)
        }
    }
}

function Write-FileAtomic {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][byte[]]$Bytes
    )
    $parent = Split-Path -Path $Path -Parent
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        Register-CreatedDirectories -TargetDir $parent
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $tempPath = Join-Path $parent ('.runtime-pack-' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [System.IO.File]::WriteAllBytes($tempPath, $Bytes)
        if ((Get-Sha256File -Path $tempPath) -ne (Get-Sha256Bytes -Bytes $Bytes)) {
            Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'A staged file write could not be verified.'
        }
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            [System.IO.File]::Move($tempPath, $Path, $true)
        }
        else {
            [System.IO.File]::Move($tempPath, $Path)
        }
    }
    finally {
        if (Test-Path -LiteralPath $tempPath -PathType Leaf) {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
        }
    }
}

# ---------------------------------------------------------------------------
# Manifest generation and built-in validation (schema v1)
# ---------------------------------------------------------------------------

function ConvertTo-JsonLiteral {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Value)
    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append('"')
    foreach ($char in $Value.ToCharArray()) {
        $code = [int]$char
        if ($char -eq '"') {
            [void]$builder.Append('\"')
        }
        elseif ($char -eq '\') {
            [void]$builder.Append('\\')
        }
        elseif ($code -lt 0x20) {
            [void]$builder.Append(('\u{0:x4}' -f $code))
        }
        else {
            [void]$builder.Append($char)
        }
    }
    [void]$builder.Append('"')
    return $builder.ToString()
}

function New-ManifestText {
    param(
        [Parameter(Mandatory = $true)][string]$Mode,
        [Parameter(Mandatory = $true)][string]$HubPathOut,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$HubUrlOut,
        [Parameter(Mandatory = $true)][string]$RequestedRefOut,
        [Parameter(Mandatory = $true)][string]$ResolvedCommit,
        [Parameter(Mandatory = $true)][string]$CanonicalIndex,
        [Parameter(Mandatory = $true)][object[]]$Adapters
    )
    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add('{')
    $lines.Add('  "schema_version": 1,')
    $lines.Add('  "generator": {')
    $lines.Add('    "id": ' + (ConvertTo-JsonLiteral -Value $script:GeneratorId) + ',')
    $lines.Add('    "version": 1')
    $lines.Add('  },')
    $lines.Add('  "hub": {')
    $lines.Add('    "mode": ' + (ConvertTo-JsonLiteral -Value $Mode) + ',')
    $lines.Add('    "path": ' + (ConvertTo-JsonLiteral -Value $HubPathOut) + ',')
    $lines.Add('    "url": ' + (ConvertTo-JsonLiteral -Value $HubUrlOut) + ',')
    $lines.Add('    "requested_ref": ' + (ConvertTo-JsonLiteral -Value $RequestedRefOut) + ',')
    $lines.Add('    "resolved_commit": ' + (ConvertTo-JsonLiteral -Value $ResolvedCommit))
    $lines.Add('  },')
    $lines.Add('  "routing": {')
    $lines.Add('    "strategy": "thin-router",')
    $lines.Add('    "canonical_index": ' + (ConvertTo-JsonLiteral -Value $CanonicalIndex))
    $lines.Add('  },')
    $lines.Add('  "adapters": [')
    for ($i = 0; $i -lt $Adapters.Count; $i++) {
        $adapter = $Adapters[$i]
        $lines.Add('    {')
        $lines.Add('      "id": ' + (ConvertTo-JsonLiteral -Value ([string]$adapter.Id)) + ',')
        $lines.Add('      "path": ' + (ConvertTo-JsonLiteral -Value ([string]$adapter.Path)) + ',')
        $lines.Add('      "management": ' + (ConvertTo-JsonLiteral -Value ([string]$adapter.Management)) + ',')
        $lines.Add('      "content_sha256": ' + (ConvertTo-JsonLiteral -Value ([string]$adapter.Hash)) + ',')
        $lines.Add('      "hash_algorithm": ' + (ConvertTo-JsonLiteral -Value $script:ManagedTextHashAlgorithm) + ',')
        $lines.Add('      "hash_normalization": ' + (ConvertTo-JsonLiteral -Value $script:ManagedTextHashNormalization))
        if ($i -lt $Adapters.Count - 1) {
            $lines.Add('    },')
        }
        else {
            $lines.Add('    }')
        }
    }
    $lines.Add(']')
    $lines.Add('}')
    return (($lines -join "`n") + "`n")
}

function Assert-ExactProperties {
    param(
        [Parameter(Mandatory = $true)][object]$Value,
        [Parameter(Mandatory = $true)][string[]]$Expected,
        [Parameter(Mandatory = $true)][string]$Label
    )
    if ($null -eq $Value -or $Value -isnot [pscustomobject]) {
        Throw-PackError -Condition 'MANIFEST_INVALID' -Message "$Label must be an object."
    }
    $names = @($Value.PSObject.Properties.Name)
    foreach ($name in $names) {
        if ($Expected -cnotcontains $name) {
            Throw-PackError -Condition 'MANIFEST_UNKNOWN_FIELD' -Message "$Label contains unknown field '$name'."
        }
    }
    if ($names.Count -ne $Expected.Count) {
        Throw-PackError -Condition 'MANIFEST_INVALID' -Message "$Label is missing a required field."
    }
    for ($i = 0; $i -lt $Expected.Count; $i++) {
        if ($names[$i] -cne $Expected[$i]) {
            Throw-PackError -Condition 'MANIFEST_INVALID' -Message "$Label fields are not in the frozen order."
        }
    }
}

function Test-JsonIntegerOne {
    param([object]$Value)
    return (($Value -is [int] -or $Value -is [long]) -and $Value -eq 1)
}

function Read-RuntimeManifest {
    param([Parameter(Mandatory = $true)][string]$ManifestPath)
    $bytes = [System.IO.File]::ReadAllBytes($ManifestPath)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Throw-PackError -Condition 'MANIFEST_INVALID' -Message 'The runtime manifest must be UTF-8 without BOM.'
    }
    try {
        $text = $script:Utf8Strict.GetString($bytes)
    }
    catch {
        Throw-PackError -Condition 'MANIFEST_INVALID' -Message 'The runtime manifest is not valid UTF-8.'
    }
    try {
        $manifest = $text | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Throw-PackError -Condition 'MANIFEST_INVALID' -Message 'The runtime manifest is not valid JSON.'
    }
    Assert-ExactProperties -Value $manifest -Expected @('schema_version', 'generator', 'hub', 'routing', 'adapters') -Label 'manifest'
    if (-not (Test-JsonIntegerOne -Value $manifest.schema_version)) {
        Throw-PackError -Condition 'SCHEMA_INCOMPATIBLE' -Message 'manifest schema_version must be integer 1.'
    }
    Assert-ExactProperties -Value $manifest.generator -Expected @('id', 'version') -Label 'generator'
    if ($manifest.generator.id -cne $script:GeneratorId) {
        Throw-PackError -Condition 'SCHEMA_INCOMPATIBLE' -Message 'manifest generator id is not recognized.'
    }
    if (-not (Test-JsonIntegerOne -Value $manifest.generator.version)) {
        Throw-PackError -Condition 'SCHEMA_INCOMPATIBLE' -Message 'manifest generator version must be integer 1.'
    }
    Assert-ExactProperties -Value $manifest.hub -Expected @('mode', 'path', 'url', 'requested_ref', 'resolved_commit') -Label 'hub'
    if ($manifest.hub.mode -cnotin @('submodule', 'external-path')) {
        Throw-PackError -Condition 'MANIFEST_INVALID' -Message 'manifest hub.mode is invalid.'
    }
    foreach ($stringField in @('path', 'url', 'requested_ref', 'resolved_commit')) {
        if ($manifest.hub.$stringField -isnot [string]) {
            Throw-PackError -Condition 'MANIFEST_INVALID' -Message "manifest hub.$stringField must be a string."
        }
    }
    if ([string]$manifest.hub.resolved_commit -cnotmatch '^[0-9a-f]{40}$') {
        Throw-PackError -Condition 'MANIFEST_INVALID' -Message 'manifest hub.resolved_commit must be a 40-character lower-case hex commit id.'
    }
    Assert-ExactProperties -Value $manifest.routing -Expected @('strategy', 'canonical_index') -Label 'routing'
    if ($manifest.routing.strategy -cne 'thin-router') {
        Throw-PackError -Condition 'MANIFEST_INVALID' -Message 'manifest routing.strategy is invalid.'
    }
    if ($manifest.routing.canonical_index -isnot [string]) {
        Throw-PackError -Condition 'MANIFEST_INVALID' -Message 'manifest routing.canonical_index must be a string.'
    }
    $expectedIndex = ([string]$manifest.hub.path).TrimEnd('/') + '/SKILLS_INDEX.md'
    if ([string]$manifest.routing.canonical_index -cne $expectedIndex) {
        Throw-PackError -Condition 'MANIFEST_INVALID' -Message 'manifest routing.canonical_index must equal <hub.path>/SKILLS_INDEX.md.'
    }
    if ($manifest.hub.mode -ceq 'submodule') {
        $hubPathText = [string]$manifest.hub.path
        if (
            [System.IO.Path]::IsPathRooted($hubPathText) -or
            $hubPathText.Contains('\') -or
            $hubPathText.StartsWith('/') -or
            @($hubPathText -split '/') -contains '..' -or
            @($hubPathText -split '/') -contains '.'
        ) {
            Throw-PackError -Condition 'MANIFEST_INVALID' -Message 'manifest hub.path must be a project-relative POSIX path in submodule mode.'
        }
    }
    else {
        $hubPathText = ([string]$manifest.hub.path).Replace('\', '/')
        if (-not ($hubPathText -match '^[A-Za-z]:/') -or [string]$manifest.hub.path -cne $hubPathText) {
            Throw-PackError -Condition 'MANIFEST_INVALID' -Message 'manifest hub.path must be an absolute slash-normalized path in external-path mode.'
        }
    }
    if ($null -eq $manifest.adapters -or $manifest.adapters -isnot [System.Array]) {
        Throw-PackError -Condition 'MANIFEST_INVALID' -Message 'manifest adapters must be an array.'
    }
    $adapters = @($manifest.adapters)
    $expectedIds = @('agents-entry', 'claude-entry', 'claude-router', 'copilot-entry', 'shared-router')
    if ($adapters.Count -ne $expectedIds.Count) {
        Throw-PackError -Condition 'MANIFEST_INVALID' -Message 'manifest adapters must contain exactly the five frozen records.'
    }
    for ($i = 0; $i -lt $expectedIds.Count; $i++) {
        $adapter = $adapters[$i]
        $adapterFields = @($adapter.PSObject.Properties.Name)
        $hasAlgorithm = $adapterFields -ccontains 'hash_algorithm'
        $hasNormalization = $adapterFields -ccontains 'hash_normalization'
        if ($hasAlgorithm -ne $hasNormalization) {
            Throw-PackError -Condition 'MANIFEST_INVALID' -Message "manifest adapter hash metadata for $($adapter.id) must be present together."
        }
        $expectedAdapterFields = if ($hasAlgorithm) {
            @('id', 'path', 'management', 'content_sha256', 'hash_algorithm', 'hash_normalization')
        }
        else {
            @('id', 'path', 'management', 'content_sha256')
        }
        Assert-ExactProperties -Value $adapter -Expected $expectedAdapterFields -Label "adapters[$i]"
        if ($adapter.id -cne $expectedIds[$i]) {
            Throw-PackError -Condition 'MANIFEST_INVALID' -Message 'manifest adapters must be the exact five ids in ordinal ascending order.'
        }
        $def = $script:AdapterDefs[$i]
        if ([string]$adapter.path -cne [string]$def.Path) {
            Throw-PackError -Condition 'MANIFEST_INVALID' -Message "manifest adapter path for $($adapter.id) is invalid."
        }
        if ([string]$adapter.management -cne [string]$def.Management) {
            Throw-PackError -Condition 'MANIFEST_INVALID' -Message "manifest adapter management for $($adapter.id) is invalid."
        }
        if ([string]$adapter.content_sha256 -cnotmatch '^[0-9a-f]{64}$') {
            Throw-PackError -Condition 'MANIFEST_INVALID' -Message "manifest adapter content_sha256 for $($adapter.id) is invalid."
        }
        if ($hasAlgorithm -and [string]$adapter.hash_algorithm -cne $script:ManagedTextHashAlgorithm) {
            Throw-PackError -Condition 'SCHEMA_INCOMPATIBLE' -Message "manifest adapter hash_algorithm for $($adapter.id) is not recognized."
        }
        if ($hasNormalization -and [string]$adapter.hash_normalization -cne $script:ManagedTextHashNormalization) {
            Throw-PackError -Condition 'SCHEMA_INCOMPATIBLE' -Message "manifest adapter hash_normalization for $($adapter.id) is not recognized."
        }
    }
    return $manifest
}

# ---------------------------------------------------------------------------
# Hub URL and HubRef handling
# ---------------------------------------------------------------------------

function ConvertTo-NormalizedHubUrl {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Url,
        [Parameter(Mandatory = $true)][string]$Condition
    )
    $normalized = $Url.Trim()
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        Throw-PackError -Condition $Condition -Message 'The hub URL is blank.'
    }
    if ($normalized -match '[\x00-\x1f\x7f]') {
        Throw-PackError -Condition $Condition -Message 'The hub URL contains control characters.'
    }
    $isScheme = $normalized -match '^(https|ssh|git|file)://'
    $isScpLike = $normalized -match '^[A-Za-z0-9_.-]+@[A-Za-z0-9_.-]+:.+' -or $normalized -match '^[A-Za-z0-9_.-]+:.+'
    if (-not $isScheme -and -not $isScpLike) {
        Throw-PackError -Condition $Condition -Message 'The hub URL is not an accepted Git URL form.'
    }
    while ($normalized.EndsWith('/')) {
        $normalized = $normalized.Substring(0, $normalized.Length - 1)
    }
    if ($normalized -match '^file://') {
        Write-PackDiagnostic 'WARNING: file:// hub URLs are non-portable and are only acceptable for local smoke/test profiles.'
    }
    return $normalized
}

function Get-HubRefKind {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Ref)
    if ([string]::IsNullOrWhiteSpace($Ref)) {
        Throw-PackError -Condition 'REF_INVALID' -Message 'HubRef is blank.'
    }
    if ($Ref -ceq 'HEAD' -or $Ref.StartsWith('-')) {
        Throw-PackError -Condition 'REF_INVALID' -Message 'HubRef cannot be HEAD or start with a dash.'
    }
    if ($Ref -match '[~^@:?*\[\\\x00-\x20]' -or $Ref.Contains('..')) {
        Throw-PackError -Condition 'REF_INVALID' -Message 'HubRef contains a forbidden revision expression or character.'
    }
    if ($Ref -match '^[0-9a-fA-F]{40}$') {
        return 'commit'
    }
    if ($Ref -match '^[0-9a-fA-F]{4,39}$') {
        Throw-PackError -Condition 'REF_INVALID' -Message 'Abbreviated commit ids are not accepted; pass the full 40-character commit id.'
    }
    if ($Ref.StartsWith('refs/heads/')) {
        return 'branch-qualified'
    }
    if ($Ref.StartsWith('refs/tags/')) {
        return 'tag-qualified'
    }
    if ($Ref.StartsWith('refs/')) {
        Throw-PackError -Condition 'REF_INVALID' -Message 'Only refs/heads/* and refs/tags/* qualified refs are accepted.'
    }
    return 'short'
}

function Resolve-HubRefFromRemote {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Ref,
        [Parameter(Mandatory = $true)][string]$Kind
    )
    if ($Kind -eq 'commit') {
        $resolved = $Ref.ToLowerInvariant()
        $tempRepo = New-TempVerificationRepo
        try {
            Invoke-GitChecked -Arguments @('init', '-q', '--bare', $tempRepo) -Condition 'UNEXPECTED_ERROR' -Message 'Could not create the isolated ref-verification repository.' | Out-Null
            $fetch = Invoke-Git -Arguments @('-C', $tempRepo, 'fetch', '-q', $Url, '+refs/heads/*:refs/runtime-pack/heads/*', '+refs/tags/*:refs/tags/*')
            if ($fetch.ExitCode -ne 0) {
                Throw-PackError -Condition 'CREDENTIAL_OR_TRANSPORT' -Message 'The hub remote could not be fetched for commit verification (credential or transport failure).'
            }
            $verify = Invoke-Git -Arguments @('-C', $tempRepo, 'cat-file', '-e', "$resolved^{commit}")
            if ($verify.ExitCode -ne 0) {
                Throw-PackError -Condition 'REF_NOT_FOUND' -Message 'The requested 40-character commit is not reachable from the hub remote.'
            }
            $indexCheck = Invoke-Git -Arguments @('-C', $tempRepo, 'cat-file', '-e', "${resolved}:SKILLS_INDEX.md")
            if ($indexCheck.ExitCode -ne 0) {
                Throw-PackError -Condition 'CANONICAL_INDEX_MISSING' -Message 'SKILLS_INDEX.md is missing at the resolved hub commit.'
            }
            return $resolved
        }
        finally {
            Remove-TempVerificationRepo -Path $tempRepo
        }
    }

    $patterns = @()
    if ($Kind -eq 'branch-qualified') {
        $patterns = @($Ref)
    }
    elseif ($Kind -eq 'tag-qualified') {
        $patterns = @($Ref, "$Ref^{}")
    }
    else {
        $patterns = @("refs/heads/$Ref", "refs/tags/$Ref", "refs/tags/$Ref^{}")
    }
    $lsRemote = Invoke-Git -Arguments (@('ls-remote', $Url) + $patterns)
    if ($lsRemote.ExitCode -ne 0) {
        Throw-PackError -Condition 'CREDENTIAL_OR_TRANSPORT' -Message 'The hub remote could not be queried (credential or transport failure).'
    }
    $branchCommit = ''
    $tagCommit = ''
    foreach ($line in ($lsRemote.StdOut -split "`n")) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) {
            continue
        }
        $parts = $trimmed -split "`t"
        if ($parts.Count -ne 2) {
            continue
        }
        $sha = $parts[0].Trim().ToLowerInvariant()
        $refName = $parts[1].Trim()
        if ($Kind -eq 'branch-qualified' -and $refName -ceq $Ref) {
            $branchCommit = $sha
        }
        elseif ($Kind -eq 'tag-qualified') {
            if ($refName -ceq "$Ref^{}") {
                $tagCommit = $sha
            }
            elseif ($refName -ceq $Ref -and [string]::IsNullOrEmpty($tagCommit)) {
                $tagCommit = $sha
            }
        }
        elseif ($Kind -eq 'short') {
            if ($refName -ceq "refs/heads/$Ref") {
                $branchCommit = $sha
            }
            elseif ($refName -ceq "refs/tags/$Ref^{}") {
                $tagCommit = $sha
            }
            elseif ($refName -ceq "refs/tags/$Ref" -and [string]::IsNullOrEmpty($tagCommit)) {
                $tagCommit = $sha
            }
        }
    }
    if (-not [string]::IsNullOrEmpty($branchCommit) -and -not [string]::IsNullOrEmpty($tagCommit)) {
        Throw-PackError -Condition 'REF_AMBIGUOUS' -Message "HubRef '$Ref' exists as both a branch and a tag on the hub remote."
    }
    $resolved = if (-not [string]::IsNullOrEmpty($branchCommit)) { $branchCommit } else { $tagCommit }
    if ([string]::IsNullOrEmpty($resolved)) {
        Throw-PackError -Condition 'REF_NOT_FOUND' -Message "HubRef '$Ref' was not found on the hub remote."
    }
    if ($resolved -cnotmatch '^[0-9a-f]{40}$') {
        Throw-PackError -Condition 'REF_INVALID' -Message 'The hub remote returned an unexpected ref value.'
    }
    $tempRepo = New-TempVerificationRepo
    try {
        Invoke-GitChecked -Arguments @('init', '-q', '--bare', $tempRepo) -Condition 'UNEXPECTED_ERROR' -Message 'Could not create the isolated ref-verification repository.' | Out-Null
        $fetch = Invoke-Git -Arguments @('-C', $tempRepo, 'fetch', '-q', $Url, "+refs/heads/*:refs/runtime-pack/heads/*", '+refs/tags/*:refs/tags/*')
        if ($fetch.ExitCode -ne 0) {
            Throw-PackError -Condition 'CREDENTIAL_OR_TRANSPORT' -Message 'The hub remote could not be fetched for canonical index verification (credential or transport failure).'
        }
        $indexCheck = Invoke-Git -Arguments @('-C', $tempRepo, 'cat-file', '-e', "${resolved}:SKILLS_INDEX.md")
        if ($indexCheck.ExitCode -ne 0) {
            Throw-PackError -Condition 'CANONICAL_INDEX_MISSING' -Message 'SKILLS_INDEX.md is missing at the resolved hub commit.'
        }
    }
    finally {
        Remove-TempVerificationRepo -Path $tempRepo
    }
    return $resolved
}

function Resolve-HubRefFromLocalRepo {
    param(
        [Parameter(Mandatory = $true)][string]$RepoPath,
        [Parameter(Mandatory = $true)][string]$Ref,
        [Parameter(Mandatory = $true)][string]$Kind
    )
    if ($Kind -eq 'commit') {
        $resolved = $Ref.ToLowerInvariant()
        $verify = Invoke-Git -Arguments @('-C', $RepoPath, 'cat-file', '-e', "$resolved^{commit}")
        if ($verify.ExitCode -ne 0) {
            Throw-PackError -Condition 'REF_NOT_FOUND' -Message 'The requested 40-character commit is not present in the external hub checkout.'
        }
        return $resolved
    }
    $branchRef = if ($Kind -eq 'branch-qualified') { $Ref } elseif ($Kind -eq 'short') { "refs/heads/$Ref" } else { '' }
    $tagRef = if ($Kind -eq 'tag-qualified') { $Ref } elseif ($Kind -eq 'short') { "refs/tags/$Ref" } else { '' }
    $branchCommit = ''
    $tagCommit = ''
    if (-not [string]::IsNullOrEmpty($branchRef)) {
        $branch = Invoke-Git -Arguments @('-C', $RepoPath, 'show-ref', '--verify', '--hash', $branchRef)
        if ($branch.ExitCode -eq 0) {
            $branchCommit = (Get-GitSingleLine -Result $branch).ToLowerInvariant()
        }
    }
    if (-not [string]::IsNullOrEmpty($tagRef)) {
        $tag = Invoke-Git -Arguments @('-C', $RepoPath, 'show-ref', '--verify', '--hash', $tagRef)
        if ($tag.ExitCode -eq 0) {
            $peel = Invoke-Git -Arguments @('-C', $RepoPath, 'rev-parse', "$tagRef^{}")
            if ($peel.ExitCode -ne 0) {
                Throw-PackError -Condition 'REF_INVALID' -Message 'The external hub tag could not be peeled to a commit.'
            }
            $tagCommit = (Get-GitSingleLine -Result $peel).ToLowerInvariant()
        }
    }
    if (-not [string]::IsNullOrEmpty($branchCommit) -and -not [string]::IsNullOrEmpty($tagCommit)) {
        Throw-PackError -Condition 'REF_AMBIGUOUS' -Message "HubRef '$Ref' exists as both a branch and a tag in the external hub checkout."
    }
    $resolved = if (-not [string]::IsNullOrEmpty($branchCommit)) { $branchCommit } else { $tagCommit }
    if ([string]::IsNullOrEmpty($resolved)) {
        Throw-PackError -Condition 'REF_NOT_FOUND' -Message "HubRef '$Ref' was not found in the external hub checkout."
    }
    return $resolved
}

function New-TempVerificationRepo {
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ('runtime-pack-verify-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    return $root
}

function Remove-TempVerificationRepo {
    param([Parameter(Mandatory = $true)][string]$Path)
    try {
        if ((Test-Path -LiteralPath $Path) -and $Path.Contains('runtime-pack-verify-')) {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        # Best effort OS temp cleanup only.
    }
}

# ---------------------------------------------------------------------------
# Failure injection (test-only; inert when the environment variable is unset)
# ---------------------------------------------------------------------------

function Get-FailAt {
    return [System.Environment]::GetEnvironmentVariable('AI_SKILL_HUB_RUNTIME_PACK_TEST_FAIL_AT')
}

function Get-TestTouchRealIndex {
    # Test-only: when set to '1', a deterministic concurrent real-index change
    # is simulated inside CommitReady just before the pre-swap hash check.
    return [System.Environment]::GetEnvironmentVariable('AI_SKILL_HUB_RUNTIME_PACK_TEST_TOUCH_REAL_INDEX')
}

function Get-TestRollbackSkip {
    # Test-only: when set, rollback deliberately skips one cleanup step so that
    # rollback verification can be proven to detect the residue.
    return [System.Environment]::GetEnvironmentVariable('AI_SKILL_HUB_RUNTIME_PACK_TEST_ROLLBACK_SKIP')
}

function Assert-FailAt {
    param([Parameter(Mandatory = $true)][string]$Point)
    $injected = Get-FailAt
    if ([string]::IsNullOrEmpty($injected)) {
        return
    }
    if ($injected -ceq $Point -or ($injected -ceq 'DuringRollback' -and $Point -ceq 'AfterSubmodule')) {
        throw (New-PackException -Condition 'UNEXPECTED_ERROR' -Message "Injected failure at $Point.")
    }
}

# ---------------------------------------------------------------------------
# Main flow
# ---------------------------------------------------------------------------

$script:Ctx = $null

function Get-ScriptHubRoot {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif ($MyInvocation.MyCommand.Path) {
        $MyInvocation.MyCommand.Path
    }
    else {
        Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The script path could not be resolved.'
    }
    return [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Path $scriptPath -Parent) '..'))
}

function Get-GitlinkCommit {
    param(
        [Parameter(Mandatory = $true)][string]$RelPath,
        [hashtable]$Env
    )
    $result = Invoke-Git -Arguments @('-C', $script:Ctx.ProjectRoot, 'ls-files', '-s', '-z', '--', $RelPath) -ExtraEnvironment $Env
    foreach ($entry in ($result.StdOut -split "`0")) {
        if ([string]::IsNullOrWhiteSpace($entry)) {
            continue
        }
        if ($entry -match '^160000\s+([0-9a-f]{40})\s+\d+\t') {
            return $Matches[1]
        }
    }
    return ''
}

function Get-GitPathList {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [hashtable]$Env
    )
    $result = Invoke-Git -Arguments $Arguments -ExtraEnvironment $Env
    if ($result.ExitCode -ne 0) {
        return @()
    }
    return @($result.StdOut -split "`0" | Where-Object { -not [string]::IsNullOrEmpty($_) })
}

function Get-RealIndexHash {
    if (Test-Path -LiteralPath $script:Ctx.RealIndexPath -PathType Leaf) {
        return Get-Sha256File -Path $script:Ctx.RealIndexPath
    }
    return ''
}

function Write-RealIndexBytesAtomic {
    param([byte[]]$Bytes)
    $lockPath = Join-Path $script:Ctx.GitDir 'index.lock'
    if (Test-Path -LiteralPath $lockPath) {
        Throw-PackError -Condition 'GIT_OPERATION_ACTIVE' -Message 'A Git index lock is present.'
    }
    if ($null -eq $Bytes) {
        if (Test-Path -LiteralPath $script:Ctx.RealIndexPath -PathType Leaf) {
            Remove-Item -LiteralPath $script:Ctx.RealIndexPath -Force
        }
        return
    }
    [System.IO.File]::WriteAllBytes($lockPath, $Bytes)
    try {
        if (Test-Path -LiteralPath $script:Ctx.RealIndexPath -PathType Leaf) {
            [System.IO.File]::Move($lockPath, $script:Ctx.RealIndexPath, $true)
        }
        else {
            [System.IO.File]::Move($lockPath, $script:Ctx.RealIndexPath)
        }
    }
    finally {
        if (Test-Path -LiteralPath $lockPath) {
            Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-SubmoduleHead {
    param([Parameter(Mandatory = $true)][string]$HubAbsPath)
    $dotGit = Join-Path $HubAbsPath '.git'
    if (-not (Test-Path -LiteralPath $dotGit)) {
        return ''
    }
    $head = Invoke-Git -Arguments @('-C', $HubAbsPath, 'rev-parse', 'HEAD')
    if ($head.ExitCode -ne 0) {
        return ''
    }
    return (Get-GitSingleLine -Result $head).ToLowerInvariant()
}

function Test-PackAdaptersCurrent {
    param([Parameter(Mandatory = $true)][object]$Manifest)
    $requiresMigration = $false
    for ($i = 0; $i -lt $script:AdapterDefs.Count; $i++) {
        $def = $script:AdapterDefs[$i]
        $absPath = Join-Path $script:Ctx.ProjectRoot ([string]$def.Path).Replace('/', '\')
        $adapter = $Manifest.adapters[$i]
        $expectedHash = [string]$adapter.content_sha256
        $normalizationAware = @($adapter.PSObject.Properties.Name) -ccontains 'hash_normalization'
        if (-not (Test-Path -LiteralPath $absPath -PathType Leaf)) {
            Throw-PackError -Condition 'MANAGED_CONTENT_MODIFIED' -Message "Adapter file '$($def.Path)' is missing."
        }
        if (Test-IsReparsePoint -LiteralPath $absPath) {
            Throw-PackError -Condition 'PATH_SAFETY_VIOLATION' -Message "Adapter file '$($def.Path)' is a reparse point."
        }
        if ($def.Management -eq 'generated-file') {
            $fileInfo = Read-ExistingTextFile -Path $absPath -Label $def.Path
            if ($fileInfo.HasBom) {
                Throw-PackError -Condition 'MANAGED_CONTENT_MODIFIED' -Message "Generated router '$($def.Path)' has an unsupported BOM (local modification)."
            }
            $actualNormalizedHash = Get-Sha256NormalizedText -Text $fileInfo.Text
            if ($normalizationAware -and $actualNormalizedHash -cne $expectedHash) {
                Throw-PackError -Condition 'MANAGED_CONTENT_MODIFIED' -Message "Generated router '$($def.Path)' does not match the manifest hash (local modification)."
            }
            if (-not $normalizationAware -and (Get-Sha256File -Path $absPath) -cne $expectedHash) {
                if ($expectedHash -cne (Get-ContentHash -Block $def.Block) -or $actualNormalizedHash -cne $expectedHash) {
                    Throw-PackError -Condition 'MANAGED_CONTENT_MODIFIED' -Message "Generated router '$($def.Path)' does not match the legacy manifest hash (local modification)."
                }
                $requiresMigration = $true
            }
        }
        else {
            $fileInfo = Read-ExistingTextFile -Path $absPath -Label $def.Path
            $blockInfo = Get-ManagedBlockInfo -Text $fileInfo.Text -Label $def.Path
            if ($blockInfo.Kind -ne 'Block') {
                Throw-PackError -Condition 'MANAGED_CONTENT_MODIFIED' -Message "Managed block in '$($def.Path)' is missing."
            }
            if ((Get-Sha256NormalizedText -Text $blockInfo.CanonicalText) -cne $expectedHash) {
                Throw-PackError -Condition 'MANAGED_CONTENT_MODIFIED' -Message "Managed block in '$($def.Path)' does not match the manifest hash (local modification)."
            }
            if (-not $normalizationAware) {
                if ($expectedHash -cne (Get-ContentHash -Block $def.Block)) {
                    Throw-PackError -Condition 'MANAGED_CONTENT_MODIFIED' -Message "Managed block in '$($def.Path)' does not match the legacy canonical hash (local modification)."
                }
                $requiresMigration = $true
            }
        }
    }
    return $requiresMigration
}

function Add-PlanAction {
    param(
        [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][bool]$Mutating,
        [Parameter(Mandatory = $true)][bool]$WorktreeChange
    )
    $script:Ctx.Plan.Add([pscustomobject]@{
        Token = $Token
        Mutating = $Mutating
        WorktreeChange = $WorktreeChange
    })
}

function Invoke-Preflight {
    $ctx = [ordered]@{
        ProjectRoot = ''
        GitDir = ''
        RealIndexPath = ''
        IndexPreExisted = $false
        IndexPreHash = ''
        IndexEntriesPre = ''
        IndexPreBytes = $null
        StatusPre = ''
        HubMode = $HubMode
        HubPathNorm = ''
        HubAbsPath = ''
        HubUrlNorm = ''
        HubRefKind = ''
        ResolvedCommit = ''
        ManifestPath = ''
        ManifestExists = $false
        Manifest = $null
        RequiresHashNormalizationMigration = $false
        SubmoduleAction = ''
        GitlinkCommit = ''
        SectionName = ''
        SectionUrl = ''
        ConfigSectionExisted = $false
        ConfigSectionPreText = ''
        ModuleGitDirExisted = $false
        HubPathExistedPre = $false
        HubPathPreState = 'absent'
        GitmodulesExistedPre = $false
        GitmodulesPreBytes = $null
        HumanFileBackups = @{}
        CreatedPaths = New-Object 'System.Collections.Generic.List[string]'
        CreatedDirectories = New-Object 'System.Collections.Generic.List[string]'
        Plan = New-Object 'System.Collections.Generic.List[object]'
        PlannedStageSet = New-Object 'System.Collections.Generic.List[string]'
        JournalRoot = ''
        AlternateIndexPath = ''
        IndexSwapped = $false
        HubPathCreated = $false
        MutationStarted = $false
    }
    $script:Ctx = $ctx

    Resolve-Git

    # --- Target repository root -------------------------------------------
    $projectRoot = Get-FullPathSafe -PathValue $ProjectPath -Condition 'NOT_GIT_REPOSITORY' -Label 'ProjectPath'
    if (-not (Test-Path -LiteralPath $projectRoot -PathType Container)) {
        Throw-PackError -Condition 'NOT_GIT_REPOSITORY' -Message 'ProjectPath does not exist or is not a directory.'
    }
    $topLevelResult = Invoke-Git -Arguments @('-C', $projectRoot, 'rev-parse', '--show-toplevel')
    if ($topLevelResult.ExitCode -ne 0) {
        Throw-PackError -Condition 'NOT_GIT_REPOSITORY' -Message 'ProjectPath is not inside a Git working tree.'
    }
    $bareResult = Invoke-Git -Arguments @('-C', $projectRoot, 'rev-parse', '--is-bare-repository')
    if ((Get-GitSingleLine -Result $bareResult) -ceq 'true') {
        Throw-PackError -Condition 'NOT_GIT_REPOSITORY' -Message 'Bare repositories are not supported.'
    }
    $topLevel = Get-FullPathSafe -PathValue (Get-GitSingleLine -Result $topLevelResult) -Condition 'NOT_GIT_REPOSITORY' -Label 'Git top-level'
    if (-not (Test-PathEqual -Left $topLevel -Right $projectRoot)) {
        Throw-PackError -Condition 'PROJECT_NOT_ROOT' -Message 'ProjectPath must be the Git working tree top-level.'
    }
    $ctx.ProjectRoot = $projectRoot
    $script:Result.Project_Root = $projectRoot
    $gitDirResult = Invoke-GitChecked -Arguments @('-C', $projectRoot, 'rev-parse', '--absolute-git-dir') -Condition 'NOT_GIT_REPOSITORY' -Message 'The Git directory could not be resolved.'
    $ctx.GitDir = Get-FullPathSafe -PathValue (Get-GitSingleLine -Result $gitDirResult) -Condition 'NOT_GIT_REPOSITORY' -Label 'Git directory'
    $ctx.RealIndexPath = Join-Path $ctx.GitDir 'index'

    # --- No active Git operation ------------------------------------------
    foreach ($marker in @('MERGE_HEAD', 'CHERRY_PICK_HEAD', 'REVERT_HEAD', 'BISECT_LOG', 'index.lock')) {
        if (Test-Path -LiteralPath (Join-Path $ctx.GitDir $marker)) {
            Throw-PackError -Condition 'GIT_OPERATION_ACTIVE' -Message "An active Git operation or lock was detected ($marker)."
        }
    }
    foreach ($markerDir in @('rebase-merge', 'rebase-apply', 'sequencer')) {
        if (Test-Path -LiteralPath (Join-Path $ctx.GitDir $markerDir) -PathType Container) {
            Throw-PackError -Condition 'GIT_OPERATION_ACTIVE' -Message "An active Git operation was detected ($markerDir)."
        }
    }

    # --- Parameter combination and path safety -----------------------------
    if ($HubMode -eq 'ExternalPath') {
        if ($script:BoundParams.ContainsKey('HubUrl')) {
            Throw-PackError -Condition 'EXTERNAL_PATH_INVALID' -Message '-HubUrl is forbidden in ExternalPath mode.'
        }
        if (-not $script:BoundParams.ContainsKey('HubPath')) {
            Throw-PackError -Condition 'EXTERNAL_PATH_INVALID' -Message 'ExternalPath mode requires an explicit absolute -HubPath.'
        }
        if ([string]::IsNullOrWhiteSpace($HubPath) -or (Test-HasWildcard -Value $HubPath) -or -not [System.IO.Path]::IsPathRooted($HubPath)) {
            Throw-PackError -Condition 'EXTERNAL_PATH_INVALID' -Message 'ExternalPath -HubPath must be an absolute path.'
        }
        $external = Get-FullPathSafe -PathValue $HubPath -Condition 'EXTERNAL_PATH_INVALID' -Label 'HubPath'
        if (-not (Test-Path -LiteralPath $external -PathType Container)) {
            Throw-PackError -Condition 'EXTERNAL_PATH_INVALID' -Message 'ExternalPath -HubPath must be an existing directory.'
        }
        if (Test-IsReparsePoint -LiteralPath $external) {
            Throw-PackError -Condition 'EXTERNAL_PATH_INVALID' -Message 'ExternalPath -HubPath cannot be a reparse point.'
        }
        Assert-NoReparseAncestors -PathValue $external -StopAt ([System.IO.Path]::GetPathRoot($external))
        if ((Test-PathInside -Candidate $external -Parent $projectRoot) -or (Test-PathInside -Candidate $projectRoot -Parent $external)) {
            Throw-PackError -Condition 'EXTERNAL_PATH_INVALID' -Message 'ExternalPath -HubPath must be outside the target project.'
        }
        $extTop = Invoke-Git -Arguments @('-C', $external, 'rev-parse', '--show-toplevel')
        $extBare = Invoke-Git -Arguments @('-C', $external, 'rev-parse', '--is-bare-repository')
        if ($extTop.ExitCode -ne 0 -or (Get-GitSingleLine -Result $extBare) -ceq 'true') {
            Throw-PackError -Condition 'EXTERNAL_PATH_INVALID' -Message 'ExternalPath -HubPath must be a non-bare Git working tree root.'
        }
        $extTopFull = Get-FullPathSafe -PathValue (Get-GitSingleLine -Result $extTop) -Condition 'EXTERNAL_PATH_INVALID' -Label 'External hub top-level'
        if (-not (Test-PathEqual -Left $extTopFull -Right $external)) {
            Throw-PackError -Condition 'EXTERNAL_PATH_INVALID' -Message 'ExternalPath -HubPath must be the external repository working tree root.'
        }
        $ctx.HubPathNorm = $external.Replace('\', '/')
        $ctx.HubAbsPath = $external
        $extOrigin = Invoke-Git -Arguments @('-C', $external, 'config', '--get', 'remote.origin.url')
        $ctx.HubUrlNorm = ''
        if ($extOrigin.ExitCode -eq 0) {
            $ctx.HubUrlNorm = ConvertTo-NormalizedHubUrl -Url (Get-GitSingleLine -Result $extOrigin) -Condition 'EXTERNAL_PATH_INVALID'
        }
        $ctx.HubRefKind = Get-HubRefKind -Ref $HubRef
    }
    else {
        $ctx.HubPathNorm = ConvertTo-SafeRelativePosixPath -PathValue $HubPath -Condition 'PATH_SAFETY_VIOLATION' -Label 'HubPath'
        $ctx.HubAbsPath = Join-Path $projectRoot ($ctx.HubPathNorm.Replace('/', '\'))
        if (-not (Test-PathInside -Candidate $ctx.HubAbsPath -Parent $projectRoot)) {
            Throw-PackError -Condition 'PATH_SAFETY_VIOLATION' -Message 'HubPath escapes the project root after normalization.'
        }
        Assert-NoReparseAncestors -PathValue $ctx.HubAbsPath -StopAt $projectRoot
        if ($script:BoundParams.ContainsKey('HubUrl')) {
            $ctx.HubUrlNorm = ConvertTo-NormalizedHubUrl -Url $HubUrl -Condition 'REF_INVALID'
        }
        else {
            $sourceOrigin = Invoke-Git -Arguments @('-C', (Get-ScriptHubRoot), 'config', '--get', 'remote.origin.url')
            if ($sourceOrigin.ExitCode -ne 0) {
                Throw-PackError -Condition 'REF_INVALID' -Message 'HubUrl was not provided and the source hub origin could not be read; pass -HubUrl explicitly.'
            }
            $ctx.HubUrlNorm = ConvertTo-NormalizedHubUrl -Url (Get-GitSingleLine -Result $sourceOrigin) -Condition 'REF_INVALID'
        }
        $ctx.HubRefKind = Get-HubRefKind -Ref $HubRef
    }
    $script:Result.Hub_Path = $ctx.HubPathNorm
    $script:Result.Hub_Url = $ctx.HubUrlNorm

    # --- Git status snapshot -----------------------------------------------
    $statusResult = Invoke-GitChecked -Arguments @('-C', $projectRoot, 'status', '--porcelain=v2', '--untracked-files=all') -Condition 'NOT_GIT_REPOSITORY' -Message 'Git status could not be read.'
    $ctx.StatusPre = $statusResult.StdOut.TrimEnd("`r", "`n")
    $unstaged = @(Get-GitPathList -Arguments @('-C', $projectRoot, 'diff', '--name-only', '-z'))
    $untracked = @(Get-GitPathList -Arguments @('-C', $projectRoot, 'ls-files', '--others', '--exclude-standard', '-z'))
    $staged = @(Get-GitPathList -Arguments @('-C', $projectRoot, 'diff', '--cached', '--name-only', '-z'))
    $ctx.IndexPreExisted = Test-Path -LiteralPath $ctx.RealIndexPath -PathType Leaf
    $ctx.IndexPreHash = Get-RealIndexHash
    if ($ctx.IndexPreExisted) {
        $ctx.IndexPreBytes = [System.IO.File]::ReadAllBytes($ctx.RealIndexPath)
    }
    $ctx.IndexEntriesPre = (Invoke-Git -Arguments @('-C', $projectRoot, 'ls-files', '-s', '-z')).StdOut

    # --- Manifest ------------------------------------------------------------
    $ctx.ManifestPath = Join-Path $projectRoot ($script:ManifestRelPath.Replace('/', '\'))
    $ctx.ManifestExists = Test-Path -LiteralPath $ctx.ManifestPath -PathType Leaf
    if ($ctx.ManifestExists) {
        $ctx.Manifest = Read-RuntimeManifest -ManifestPath $ctx.ManifestPath
        $script:Result.Manifest_Status = 'VALID'
        $ctx.ResolvedCommit = [string]$ctx.Manifest.hub.resolved_commit
        $script:Result.Resolved_Commit = $ctx.ResolvedCommit
        if (
            [string]$ctx.Manifest.hub.mode -ceq 'submodule' -and
            -not $script:BoundParams.ContainsKey('HubUrl')
        ) {
            $ctx.HubUrlNorm = [string]$ctx.Manifest.hub.url
            $script:Result.Hub_Url = $ctx.HubUrlNorm
        }
        if (-not $script:BoundParams.ContainsKey('HubRef')) {
            $script:Result.Requested_Ref = [string]$ctx.Manifest.hub.requested_ref
        }
    }

    # --- Managed file / generated file structure checks ----------------------
    foreach ($def in $script:AdapterDefs) {
        $absPath = Join-Path $projectRoot ([string]$def.Path).Replace('/', '\')
        if (-not (Test-Path -LiteralPath $absPath)) {
            continue
        }
        if (Test-IsReparsePoint -LiteralPath $absPath) {
            Throw-PackError -Condition 'PATH_SAFETY_VIOLATION' -Message "Adapter target '$($def.Path)' is a reparse point."
        }
        if (Test-Path -LiteralPath $absPath -PathType Container) {
            Throw-PackError -Condition 'EXISTING_FILE' -Message "Adapter target '$($def.Path)' is a directory."
        }
        if ($def.Management -eq 'generated-file') {
            if (-not $ctx.ManifestExists) {
                Throw-PackError -Condition 'EXISTING_FILE' -Message "Router target '$($def.Path)' already exists without a runtime manifest (target conflict)."
            }
        }
        else {
            $fileInfo = Read-ExistingTextFile -Path $absPath -Label $def.Path
            $blockInfo = Get-ManagedBlockInfo -Text $fileInfo.Text -Label $def.Path
            if ($blockInfo.Kind -eq 'Block' -and -not $ctx.ManifestExists) {
                Throw-PackError -Condition 'UNKNOWN_MANAGED_BLOCK_PROVENANCE' -Message "Managed block in '$($def.Path)' has no runtime manifest (unknown provenance)."
            }
            if ($blockInfo.Kind -eq 'None' -and -not $ctx.ManifestExists -and $ExistingFilePolicy -eq 'Fail') {
                Throw-PackError -Condition 'EXISTING_FILE' -Message "Entry file '$($def.Path)' already exists and ExistingFilePolicy is Fail."
            }
        }
    }

    # --- Dirty / staged policy -----------------------------------------------
    $isClean = ($unstaged.Count -eq 0 -and $untracked.Count -eq 0 -and $staged.Count -eq 0)
    if (-not $isClean) {
        $allowedStaged = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
        foreach ($def in $script:AdapterDefs) {
            [void]$allowedStaged.Add([string]$def.Path)
        }
        [void]$allowedStaged.Add($script:ManifestRelPath)
        if ($ctx.ManifestExists -and [string]$ctx.Manifest.hub.mode -ceq 'submodule') {
            [void]$allowedStaged.Add('.gitmodules')
            [void]$allowedStaged.Add([string]$ctx.Manifest.hub.path)
        }
        $exceptionOk = $false
        if ($ctx.ManifestExists -and $unstaged.Count -eq 0 -and $untracked.Count -eq 0 -and $staged.Count -gt 0) {
            $requiredStaged = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
            foreach ($def in $script:AdapterDefs) {
                [void]$requiredStaged.Add([string]$def.Path)
            }
            [void]$requiredStaged.Add($script:ManifestRelPath)
            $exceptionOk = $true
            foreach ($path in $staged) {
                if (-not $allowedStaged.Contains($path)) {
                    $exceptionOk = $false
                    break
                }
            }
            foreach ($path in $requiredStaged) {
                if ($staged -notcontains $path) {
                    $exceptionOk = $false
                    break
                }
            }
        }
        if (-not $exceptionOk) {
            if ($staged.Count -gt 0) {
                Throw-PackError -Condition 'STAGED_CHANGES' -Message 'The repository has staged changes outside the initializer-owned set.'
            }
            Throw-PackError -Condition 'DIRTY_WORKTREE' -Message 'The repository has unstaged or untracked changes.'
        }
    }

    # --- Submodule state detection -------------------------------------------
    if ($HubMode -eq 'Submodule') {
        $sectionList = @()
        $gitmodulesPath = Join-Path $projectRoot '.gitmodules'
        $ctx.GitmodulesExistedPre = Test-Path -LiteralPath $gitmodulesPath -PathType Leaf
        if ($ctx.GitmodulesExistedPre) {
            $ctx.GitmodulesPreBytes = [System.IO.File]::ReadAllBytes($gitmodulesPath)
            $sections = Invoke-Git -Arguments @('-C', $projectRoot, 'config', '-f', '.gitmodules', '--get-regexp', '^submodule\..*\.path$')
            if ($sections.ExitCode -eq 0) {
                foreach ($line in ($sections.StdOut -split "`n")) {
                    $trimmed = $line.Trim()
                    if ($trimmed -match '^submodule\.(.+)\.path\s+(.+)$') {
                        $sectionList += [pscustomobject]@{ Name = $Matches[1]; Path = $Matches[2].Trim() }
                    }
                }
            }
        }
        $matchingNames = @($sectionList | Where-Object { $_.Path -ceq $ctx.HubPathNorm } | ForEach-Object { $_.Name })
        if ($matchingNames.Count -gt 1) {
            Throw-PackError -Condition 'SUBMODULE_CONFLICT' -Message 'Duplicate submodule sections register the hub path.'
        }
        if ($matchingNames.Count -eq 1) {
            $ctx.SectionName = $matchingNames[0]
            $urlResult = Invoke-Git -Arguments @('-C', $projectRoot, 'config', '-f', '.gitmodules', '--get', "submodule.$($ctx.SectionName).url")
            if ($urlResult.ExitCode -eq 0) {
                $ctx.SectionUrl = ConvertTo-NormalizedHubUrl -Url (Get-GitSingleLine -Result $urlResult) -Condition 'SUBMODULE_CONFLICT'
                if ($ctx.SectionUrl -cne $ctx.HubUrlNorm) {
                    Throw-PackError -Condition 'SUBMODULE_CONFLICT' -Message 'The existing submodule at the hub path has a different URL.'
                }
            }
        }
        $ctx.GitlinkCommit = Get-GitlinkCommit -RelPath $ctx.HubPathNorm
        if ($matchingNames.Count -eq 1 -and [string]::IsNullOrEmpty($ctx.GitlinkCommit)) {
            Throw-PackError -Condition 'SUBMODULE_CONFLICT' -Message 'The hub path is registered in .gitmodules but has no committed gitlink.'
        }
        if ($matchingNames.Count -eq 0 -and -not [string]::IsNullOrEmpty($ctx.GitlinkCommit)) {
            Throw-PackError -Condition 'HUB_PATH_CONFLICT' -Message 'The hub path is occupied by an unregistered nested repository (gitlink without .gitmodules registration).'
        }
        $configCheck = Invoke-Git -Arguments @('-C', $projectRoot, 'config', '--get-regexp', "^submodule\.$($script:SubmoduleName)\.")
        $ctx.ConfigSectionExisted = ($configCheck.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($configCheck.StdOut))
        $ctx.ConfigSectionPreText = ''
        if ($ctx.ConfigSectionExisted) {
            $ctx.ConfigSectionPreText = $configCheck.StdOut
        }
        $ctx.ModuleGitDirExisted = Test-Path -LiteralPath (Join-Path $ctx.GitDir "modules\$($script:SubmoduleName)") -PathType Container
        $hubItem = Get-Item -LiteralPath $ctx.HubAbsPath -Force -ErrorAction SilentlyContinue
        $ctx.HubPathExistedPre = ($null -ne $hubItem)
        if ($null -ne $hubItem) {
            if (-not $hubItem.PSIsContainer) {
                $ctx.HubPathPreState = 'file'
            }
            else {
                $preChildren = @(Get-ChildItem -LiteralPath $ctx.HubAbsPath -Force -ErrorAction SilentlyContinue)
                $ctx.HubPathPreState = if ($preChildren.Count -eq 0) { 'empty' } else { 'populated' }
            }
        }
        if ($null -ne $hubItem -and (Test-IsReparsePoint -LiteralPath $ctx.HubAbsPath)) {
            Throw-PackError -Condition 'PATH_SAFETY_VIOLATION' -Message 'The hub path is a reparse point.'
        }
        if ([string]::IsNullOrEmpty($ctx.GitlinkCommit)) {
            if ($ctx.ConfigSectionExisted -or $ctx.ModuleGitDirExisted) {
                Throw-PackError -Condition 'SUBMODULE_CONFLICT' -Message 'Stale submodule config or module gitdir exists without a committed gitlink.'
            }
            if ($null -ne $hubItem) {
                if (-not $hubItem.PSIsContainer) {
                    Throw-PackError -Condition 'HUB_PATH_CONFLICT' -Message 'The hub path is occupied by a regular file.'
                }
                $hasDotGit = Test-Path -LiteralPath (Join-Path $ctx.HubAbsPath '.git')
                $children = @(Get-ChildItem -LiteralPath $ctx.HubAbsPath -Force -ErrorAction SilentlyContinue)
                if ($hasDotGit -or $children.Count -gt 0) {
                    Throw-PackError -Condition 'HUB_PATH_CONFLICT' -Message 'The hub path is occupied by an unregistered directory or nested repository.'
                }
                Throw-PackError -Condition 'HUB_PATH_CONFLICT' -Message 'The hub path is occupied by an unregistered directory.'
            }
            $ctx.SubmoduleAction = 'add'
        }
        else {
            $head = Get-SubmoduleHead -HubAbsPath $ctx.HubAbsPath
            if ([string]::IsNullOrEmpty($head)) {
                $ctx.SubmoduleAction = 'materialize'
            }
            else {
                if ($head -cne $ctx.GitlinkCommit) {
                    Throw-PackError -Condition 'SUBMODULE_CONFLICT' -Message 'The materialized submodule HEAD differs from the committed gitlink.'
                }
                $ctx.SubmoduleAction = 'reuse'
            }
        }
    }
}

function Invoke-ManifestRerunEvaluation {
    $ctx = $script:Ctx
    $manifest = $ctx.Manifest
    $manifestMode = [string]$manifest.hub.mode
    $requestedMode = if ($HubMode -eq 'Submodule') { 'submodule' } else { 'external-path' }
    if ($manifestMode -cne $requestedMode) {
        Throw-PackError -Condition 'RUNTIME_PACK_MISMATCH' -Message 'The requested hub mode differs from the runtime manifest.'
    }
    if ($manifestMode -ceq 'submodule') {
        if ([string]$manifest.hub.path -cne $ctx.HubPathNorm) {
            Throw-PackError -Condition 'RUNTIME_PACK_MISMATCH' -Message 'The requested hub path differs from the runtime manifest.'
        }
        if ($script:BoundParams.ContainsKey('HubUrl') -and $ctx.HubUrlNorm -cne [string]$manifest.hub.url) {
            Throw-PackError -Condition 'RUNTIME_PACK_MISMATCH' -Message 'The requested hub URL differs from the runtime manifest.'
        }
        if ($ctx.GitlinkCommit -cne $ctx.ResolvedCommit) {
            Throw-PackError -Condition 'RUNTIME_PACK_MISMATCH' -Message 'The committed gitlink differs from the runtime manifest resolved commit.'
        }
    }
    else {
        if ([string]$manifest.hub.path -cne $ctx.HubPathNorm) {
            Throw-PackError -Condition 'RUNTIME_PACK_MISMATCH' -Message 'The requested external hub path differs from the runtime manifest.'
        }
        $externalHead = Get-SubmoduleHead -HubAbsPath $ctx.HubAbsPath
        if ($externalHead -cne $ctx.ResolvedCommit) {
            Throw-PackError -Condition 'RUNTIME_PACK_MISMATCH' -Message 'The external hub HEAD differs from the runtime manifest resolved commit.'
        }
    }
    if ($script:BoundParams.ContainsKey('HubRef')) {
        if ($ctx.HubRefKind -eq 'commit') {
            if ($HubRef.ToLowerInvariant() -cne $ctx.ResolvedCommit) {
                Throw-PackError -Condition 'UPGRADE_REQUIRED' -Message 'The requested commit differs from the recorded runtime pack commit; upgrades are a separate work item.'
            }
        }
        elseif ($HubRef -cne [string]$manifest.hub.requested_ref) {
            Throw-PackError -Condition 'UPGRADE_REQUIRED' -Message 'The requested ref differs from the recorded runtime pack ref; upgrades are a separate work item.'
        }
    }
    $ctx.RequiresHashNormalizationMigration = Test-PackAdaptersCurrent -Manifest $manifest
    if ($manifestMode -ceq 'submodule') {
        $indexPath = Join-Path $ctx.HubAbsPath 'SKILLS_INDEX.md'
        if ($ctx.SubmoduleAction -ne 'materialize' -and -not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
            Throw-PackError -Condition 'CANONICAL_INDEX_MISSING' -Message 'The canonical index is missing from the materialized hub checkout.'
        }
    }
    else {
        $indexPath = Join-Path $ctx.HubAbsPath 'SKILLS_INDEX.md'
        if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
            Throw-PackError -Condition 'CANONICAL_INDEX_MISSING' -Message 'The canonical index is missing from the external hub checkout.'
        }
    }
}

function Invoke-Plan {
    $ctx = $script:Ctx
    if ($HubMode -eq 'Submodule') {
        if ($ctx.SubmoduleAction -eq 'add') {
            $ctx.ResolvedCommit = Resolve-HubRefFromRemote -Url $ctx.HubUrlNorm -Ref $HubRef -Kind $ctx.HubRefKind
            Add-PlanAction -Token "submodule-add:$($ctx.HubPathNorm)" -Mutating $true -WorktreeChange $true
            [void]$ctx.PlannedStageSet.Add('.gitmodules')
            [void]$ctx.PlannedStageSet.Add($ctx.HubPathNorm)
        }
        elseif ($ctx.SubmoduleAction -eq 'materialize') {
            if (-not $ctx.ManifestExists) {
                $ctx.ResolvedCommit = Resolve-HubRefFromRemote -Url $ctx.HubUrlNorm -Ref $HubRef -Kind $ctx.HubRefKind
                if ($ctx.GitlinkCommit -cne $ctx.ResolvedCommit) {
                    Throw-PackError -Condition 'UPGRADE_REQUIRED' -Message 'The existing gitlink differs from the resolved ref; upgrades are a separate work item.'
                }
            }
            else {
                if ($ctx.GitlinkCommit -cne $ctx.ResolvedCommit) {
                    Throw-PackError -Condition 'RUNTIME_PACK_MISMATCH' -Message 'The committed gitlink differs from the runtime manifest resolved commit.'
                }
            }
            Add-PlanAction -Token "submodule-materialize:$($ctx.HubPathNorm)" -Mutating $true -WorktreeChange $true
        }
        else {
            if (-not $ctx.ManifestExists) {
                $ctx.ResolvedCommit = Resolve-HubRefFromRemote -Url $ctx.HubUrlNorm -Ref $HubRef -Kind $ctx.HubRefKind
                if ($ctx.GitlinkCommit -cne $ctx.ResolvedCommit) {
                    Throw-PackError -Condition 'UPGRADE_REQUIRED' -Message 'The existing gitlink differs from the resolved ref; upgrades are a separate work item.'
                }
            }
            Add-PlanAction -Token "submodule-reuse:$($ctx.HubPathNorm)" -Mutating $false -WorktreeChange $false
        }
        $script:Result.Resolved_Commit = $ctx.ResolvedCommit
    }
    else {
        $ctx.ResolvedCommit = Resolve-HubRefFromLocalRepo -RepoPath $ctx.HubAbsPath -Ref $HubRef -Kind $ctx.HubRefKind
        $script:Result.Resolved_Commit = $ctx.ResolvedCommit
        $externalHead = Get-SubmoduleHead -HubAbsPath $ctx.HubAbsPath
        if ($externalHead -cne $ctx.ResolvedCommit) {
            Throw-PackError -Condition 'EXTERNAL_PATH_INVALID' -Message 'The external hub HEAD does not equal the resolved commit.'
        }
        if (-not (Test-Path -LiteralPath (Join-Path $ctx.HubAbsPath 'SKILLS_INDEX.md') -PathType Leaf)) {
            Throw-PackError -Condition 'CANONICAL_INDEX_MISSING' -Message 'The canonical index is missing from the external hub checkout.'
        }
        Add-PlanAction -Token "external-verify:$($ctx.HubPathNorm)" -Mutating $false -WorktreeChange $false
    }

    if (-not $ctx.ManifestExists) {
        foreach ($def in $script:AdapterDefs) {
            $absPath = Join-Path $ctx.ProjectRoot ([string]$def.Path).Replace('/', '\')
            if (Test-Path -LiteralPath $absPath -PathType Leaf) {
                Add-PlanAction -Token "adopt-append:$($def.Path)" -Mutating $true -WorktreeChange $true
            }
            else {
                Add-PlanAction -Token "create:$($def.Path)" -Mutating $true -WorktreeChange $true
            }
            [void]$ctx.PlannedStageSet.Add([string]$def.Path)
        }
        Add-PlanAction -Token "write-manifest:$($script:ManifestRelPath)" -Mutating $true -WorktreeChange $true
        [void]$ctx.PlannedStageSet.Add($script:ManifestRelPath)
    }
    if ($ctx.PlannedStageSet.Count -gt 0) {
        Add-PlanAction -Token 'stage-index' -Mutating $true -WorktreeChange $false
    }
    $script:Result.Planned_Actions = (($ctx.Plan | ForEach-Object { $_.Token }) -join ';')
    $script:Result.Changed_Count = @($ctx.Plan | Where-Object { $_.Mutating }).Count
}

function Write-JournalFile {
    $journal = [ordered]@{
        journal_version = 1
        generator = $script:GeneratorId
        project_root = $script:Ctx.ProjectRoot
        hub_mode = $script:Ctx.HubMode
        hub_path = $script:Ctx.HubPathNorm
        resolved_commit = $script:Ctx.ResolvedCommit
        status_pre = $script:Ctx.StatusPre
        index_pre_existed = $script:Ctx.IndexPreExisted
        index_pre_hash = $script:Ctx.IndexPreHash
        gitmodules_pre_existed = $script:Ctx.GitmodulesExistedPre
        hub_path_existed_pre = $script:Ctx.HubPathExistedPre
        hub_path_pre_state = $script:Ctx.HubPathPreState
        module_gitdir_existed_pre = $script:Ctx.ModuleGitDirExisted
        config_section_existed_pre = $script:Ctx.ConfigSectionExisted
        config_section_pre_text = $script:Ctx.ConfigSectionPreText
        submodule_action = $script:Ctx.SubmoduleAction
        created_paths = @($script:Ctx.CreatedPaths)
        created_directories = @($script:Ctx.CreatedDirectories)
        backed_up_files = @($script:Ctx.HumanFileBackups.Keys)
    }
    $json = $journal | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllBytes(
        (Join-Path $script:Ctx.JournalRoot 'journal.json'),
        $script:Utf8NoBom.GetBytes($json + "`n")
    )
}

function Invoke-SubmoduleMutation {
    $ctx = $script:Ctx
    # Seed the alternate transaction index from the exact pre-state real index
    # bytes. Every mutating Git command in this phase either avoids the
    # superproject index entirely (clone / checkout / config) or writes only to
    # this alternate index (pathspec add). The real index must stay untouched
    # until CommitReady performs the atomic swap.
    if ($ctx.IndexPreExisted) {
        [System.IO.File]::WriteAllBytes($ctx.AlternateIndexPath, $ctx.IndexPreBytes)
    }
    if ($HubMode -ne 'Submodule') {
        # ExternalPath: read-only validation already completed in Plan.
        return
    }
    if ($ctx.SubmoduleAction -eq 'add') {
        $moduleGitDir = Join-Path $ctx.GitDir ('modules\' + $script:SubmoduleName)
        $modulesParent = Join-Path $ctx.GitDir 'modules'
        if (-not (Test-Path -LiteralPath $modulesParent -PathType Container)) {
            New-Item -ItemType Directory -Path $modulesParent -Force | Out-Null
        }
        # Track only the hub path ancestors; the hub directory itself is
        # removed recursively by rollback (HubPathCreated).
        Register-CreatedDirectories -TargetDir (Split-Path -Path $ctx.HubAbsPath -Parent)
        # 1. Clone the hub directly into the standard submodule layout
        #    (worktree gitfile -> .git/modules/<name>). No superproject index
        #    is involved, so GIT_INDEX_FILE cannot leak into child processes.
        $clone = Invoke-Git -Arguments @(
            '-c', 'protocol.file.allow=always',
            'clone', '--separate-git-dir', $moduleGitDir, '--',
            $ctx.HubUrlNorm, $ctx.HubAbsPath
        )
        if ($clone.ExitCode -ne 0) {
            Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The hub repository could not be cloned into the submodule layout.'
        }
        Assert-FailAt -Point 'AfterModuleGitDirCreated'
        # 2. Materialize the exact resolved commit inside the submodule.
        $catFile = Invoke-Git -Arguments @('-C', $ctx.HubAbsPath, 'cat-file', '-e', "$($ctx.ResolvedCommit)^{commit}")
        if ($catFile.ExitCode -ne 0) {
            $fetch = Invoke-Git -Arguments @('-C', $ctx.HubAbsPath, '-c', 'protocol.file.allow=always', 'fetch', 'origin', $ctx.ResolvedCommit)
            if ($fetch.ExitCode -ne 0) {
                Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The resolved commit could not be fetched into the new submodule.'
            }
        }
        $checkout = Invoke-Git -Arguments @('-C', $ctx.HubAbsPath, 'checkout', '-q', '--detach', $ctx.ResolvedCommit)
        if ($checkout.ExitCode -ne 0) {
            Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The submodule could not be checked out at the resolved commit.'
        }
        # 3. Register the submodule in .gitmodules (worktree file, append-safe)
        #    and in the specific .git/config section.
        $gitmodulesPath = Join-Path $ctx.ProjectRoot '.gitmodules'
        $gmPath = Invoke-Git -Arguments @('-C', $ctx.ProjectRoot, 'config', '-f', $gitmodulesPath, "submodule.$($script:SubmoduleName).path", $ctx.HubPathNorm)
        if ($gmPath.ExitCode -ne 0) {
            Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The submodule path could not be registered in .gitmodules.'
        }
        $gmUrl = Invoke-Git -Arguments @('-C', $ctx.ProjectRoot, 'config', '-f', $gitmodulesPath, "submodule.$($script:SubmoduleName).url", $ctx.HubUrlNorm)
        if ($gmUrl.ExitCode -ne 0) {
            Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The submodule URL could not be registered in .gitmodules.'
        }
        $cfgUrl = Invoke-Git -Arguments @('-C', $ctx.ProjectRoot, 'config', "submodule.$($script:SubmoduleName).url", $ctx.HubUrlNorm)
        if ($cfgUrl.ExitCode -ne 0) {
            Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The submodule URL could not be registered in the Git config.'
        }
        Assert-FailAt -Point 'AfterSubmoduleConfigCreated'
        # 4. Normalize the worktree gitfile to a relative link and set
        #    core.worktree in the module gitdir (the same layout
        #    `git submodule add` produces). The clone-created gitfile may be
        #    read-only on Windows; clear the attribute before rewriting.
        $depth = @($ctx.HubPathNorm -split '/').Count
        $relativeGitDir = ((@('..') * $depth) -join '/') + '/.git/modules/' + $script:SubmoduleName
        $gitfilePath = Join-Path $ctx.HubAbsPath '.git'
        $gitfileItem = Get-Item -LiteralPath $gitfilePath -Force -ErrorAction SilentlyContinue
        if ($null -ne $gitfileItem) {
            $gitfileItem.Attributes = [System.IO.FileAttributes]::Archive
        }
        [System.IO.File]::WriteAllBytes(
            $gitfilePath,
            $script:Utf8NoBom.GetBytes("gitdir: $relativeGitDir`n")
        )
        $relativeWorktree = '../../../' + $ctx.HubPathNorm
        $worktreeCfg = Invoke-Git -Arguments @('--git-dir', $moduleGitDir, 'config', 'core.worktree', $relativeWorktree)
        if ($worktreeCfg.ExitCode -ne 0) {
            Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The submodule worktree configuration could not be written.'
        }
        $headCheck = Invoke-Git -Arguments @('-C', $ctx.HubAbsPath, 'rev-parse', 'HEAD')
        if ($headCheck.ExitCode -ne 0 -or (Get-GitSingleLine -Result $headCheck).ToLowerInvariant() -cne $ctx.ResolvedCommit) {
            Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The submodule gitfile/worktree wiring could not be verified.'
        }
        # 5. Stage .gitmodules and the gitlink into the ALTERNATE index only.
        #    A plain pathspec add spawns no child Git process, so
        #    GIT_INDEX_FILE cannot leak here.
        $altEnv = @{ GIT_INDEX_FILE = $ctx.AlternateIndexPath }
        $restage = Invoke-Git -Arguments @(
            '-C', $ctx.ProjectRoot,
            '-c', 'advice.addEmbeddedRepo=false',
            'add', '--', '.gitmodules', $ctx.HubPathNorm
        ) -ExtraEnvironment $altEnv
        if ($restage.ExitCode -ne 0) {
            Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The gitlink could not be staged at the resolved commit.'
        }
        $altGitlink = Get-GitlinkCommit -RelPath $ctx.HubPathNorm -Env $altEnv
        if ($altGitlink -cne $ctx.ResolvedCommit) {
            Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The alternate index gitlink does not equal the resolved commit.'
        }
        Assert-FailAt -Point 'DuringSubmoduleMutation'
    }
    elseif ($ctx.SubmoduleAction -eq 'materialize') {
        # submodule update --init does not write the superproject index
        # (verified on the supported Git floor); it must run without
        # GIT_INDEX_FILE so the variable cannot leak into clone children.
        $update = Invoke-Git -Arguments @(
            '-C', $ctx.ProjectRoot,
            '-c', 'protocol.file.allow=always',
            'submodule', 'update', '--init', '--', $ctx.HubPathNorm
        )
        if ($update.ExitCode -ne 0) {
            Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'git submodule update --init failed.'
        }
        $head = Get-SubmoduleHead -HubAbsPath $ctx.HubAbsPath
        if ($head -cne $ctx.GitlinkCommit) {
            Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The materialized submodule HEAD does not equal the committed gitlink.'
        }
    }
    # Phase invariant: the real index must be byte-identical to its
    # pre-transaction state at the end of SubmoduleMutation.
    if ((Get-RealIndexHash) -cne $ctx.IndexPreHash) {
        Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The real index changed during the submodule mutation phase.'
    }
}

function Invoke-AdapterGeneration {
    $ctx = $script:Ctx
    $first = $true
    foreach ($def in $script:AdapterDefs) {
        $absPath = Join-Path $ctx.ProjectRoot ([string]$def.Path).Replace('/', '\')
        if ($def.Management -eq 'generated-file') {
            $content = Get-CanonicalContent -Block $def.Block
            $bytes = $script:Utf8NoBom.GetBytes($content)
            Write-FileAtomic -Path $absPath -Bytes $bytes
            [void]$ctx.CreatedPaths.Add($absPath)
        }
        else {
            $canonicalBlock = Get-CanonicalContent -Block $def.Block
            if (Test-Path -LiteralPath $absPath -PathType Leaf) {
                $fileInfo = Read-ExistingTextFile -Path $absPath -Label $def.Path
                $hostBlock = ConvertTo-HostNewline -CanonicalText $canonicalBlock -Newline $fileInfo.Newline
                $separator = ''
                if ($fileInfo.Text.Length -gt 0 -and -not $fileInfo.Text.EndsWith("`n")) {
                    $separator = if ($fileInfo.Newline -eq 'CRLF') { "`r`n" } else { "`n" }
                }
                $newText = $fileInfo.Text + $separator + $hostBlock
                $payload = $script:Utf8NoBom.GetBytes($newText)
                if ($fileInfo.HasBom) {
                    $bytes = New-Object byte[] ($payload.Length + 3)
                    $bytes[0] = 0xEF; $bytes[1] = 0xBB; $bytes[2] = 0xBF
                    [Array]::Copy($payload, 0, $bytes, 3, $payload.Length)
                }
                else {
                    $bytes = $payload
                }
                Write-FileAtomic -Path $absPath -Bytes $bytes
            }
            else {
                $bytes = $script:Utf8NoBom.GetBytes($canonicalBlock)
                Write-FileAtomic -Path $absPath -Bytes $bytes
                [void]$ctx.CreatedPaths.Add($absPath)
            }
        }
        if ($first) {
            $first = $false
            Assert-FailAt -Point 'AfterFirstAdapter'
        }
    }
}

function Invoke-ManifestGeneration {
    $ctx = $script:Ctx
    $adapters = @()
    foreach ($def in $script:AdapterDefs) {
        $adapters += [pscustomobject]@{
            Id = [string]$def.Id
            Path = [string]$def.Path
            Management = [string]$def.Management
            Hash = Get-ContentHash -Block $def.Block
        }
    }
    $mode = if ($HubMode -eq 'Submodule') { 'submodule' } else { 'external-path' }
    $canonicalIndex = $ctx.HubPathNorm.TrimEnd('/') + '/SKILLS_INDEX.md'
    $manifestText = New-ManifestText -Mode $mode -HubPathOut $ctx.HubPathNorm -HubUrlOut $ctx.HubUrlNorm `
        -RequestedRefOut $HubRef -ResolvedCommit $ctx.ResolvedCommit -CanonicalIndex $canonicalIndex -Adapters $adapters
    Write-FileAtomic -Path $ctx.ManifestPath -Bytes ($script:Utf8NoBom.GetBytes($manifestText))
    if (-not $ctx.ManifestExists) {
        [void]$ctx.CreatedPaths.Add($ctx.ManifestPath)
    }
}

function Invoke-ManifestHashMetadataMigration {
    $ctx = $script:Ctx
    $manifest = $ctx.Manifest
    $adapters = @()
    for ($i = 0; $i -lt $script:AdapterDefs.Count; $i++) {
        $def = $script:AdapterDefs[$i]
        $existing = $manifest.adapters[$i]
        $adapters += [pscustomobject]@{
            Id = [string]$existing.id
            Path = [string]$existing.path
            Management = [string]$existing.management
            Hash = Get-ContentHash -Block $def.Block
        }
    }
    $manifestText = New-ManifestText -Mode ([string]$manifest.hub.mode) `
        -HubPathOut ([string]$manifest.hub.path) -HubUrlOut ([string]$manifest.hub.url) `
        -RequestedRefOut ([string]$manifest.hub.requested_ref) `
        -ResolvedCommit ([string]$manifest.hub.resolved_commit) `
        -CanonicalIndex ([string]$manifest.routing.canonical_index) -Adapters $adapters
    Write-FileAtomic -Path $ctx.ManifestPath -Bytes ($script:Utf8NoBom.GetBytes($manifestText))
}

function Invoke-ManifestHashMigrationPlan {
    $ctx = $script:Ctx
    Add-PlanAction -Token "migrate-hash-normalization:$($script:ManifestRelPath)" -Mutating $true -WorktreeChange $true
    [void]$ctx.PlannedStageSet.Add($script:ManifestRelPath)
    Add-PlanAction -Token 'stage-index' -Mutating $true -WorktreeChange $false
    $script:Result.Planned_Actions = (($ctx.Plan | ForEach-Object { $_.Token }) -join ';')
    $script:Result.Changed_Count = @($ctx.Plan | Where-Object { $_.Mutating }).Count
}

function Invoke-PackValidation {
    $ctx = $script:Ctx
    $altEnv = @{ GIT_INDEX_FILE = $ctx.AlternateIndexPath }
    $manifest = Read-RuntimeManifest -ManifestPath $ctx.ManifestPath
    [void](Test-PackAdaptersCurrent -Manifest $manifest)
    if ($HubMode -eq 'Submodule') {
        $gitlink = Get-GitlinkCommit -RelPath $ctx.HubPathNorm -Env $altEnv
        if ($gitlink -cne $ctx.ResolvedCommit) {
            Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The staged gitlink does not equal the resolved commit.'
        }
        if ($ctx.SubmoduleAction -ne 'reuse') {
            $head = Get-SubmoduleHead -HubAbsPath $ctx.HubAbsPath
            if ($head -cne $ctx.ResolvedCommit) {
                Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The materialized submodule HEAD does not equal the resolved commit.'
            }
        }
        if (-not (Test-Path -LiteralPath (Join-Path $ctx.HubAbsPath 'SKILLS_INDEX.md') -PathType Leaf)) {
            Throw-PackError -Condition 'CANONICAL_INDEX_MISSING' -Message 'The canonical index is missing from the materialized hub checkout.'
        }
    }
    else {
        $head = Get-SubmoduleHead -HubAbsPath $ctx.HubAbsPath
        if ($head -cne $ctx.ResolvedCommit) {
            Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The external hub HEAD does not equal the resolved commit.'
        }
        if (-not (Test-Path -LiteralPath (Join-Path $ctx.HubAbsPath 'SKILLS_INDEX.md') -PathType Leaf)) {
            Throw-PackError -Condition 'CANONICAL_INDEX_MISSING' -Message 'The canonical index is missing from the external hub checkout.'
        }
    }
}

function Invoke-CommitReady {
    $ctx = $script:Ctx
    if ($ctx.PlannedStageSet.Count -eq 0) {
        return
    }
    $altEnv = @{ GIT_INDEX_FILE = $ctx.AlternateIndexPath }
    $addArgs = @('-C', $ctx.ProjectRoot, 'add', '--') + @($ctx.PlannedStageSet)
    $add = Invoke-Git -Arguments $addArgs -ExtraEnvironment $altEnv
    if ($add.ExitCode -ne 0) {
        Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'Staging the planned path set into the alternate index failed.'
    }
    $stagedSet = @(Get-GitPathList -Arguments @('-C', $ctx.ProjectRoot, 'diff', '--cached', '--name-only', '-z') -Env $altEnv)
    $expected = @($ctx.PlannedStageSet | Sort-Object -Unique)
    $actual = @($stagedSet | Sort-Object -Unique)
    if (($expected -join "`0") -cne ($actual -join "`0")) {
        Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The alternate index staged path set does not equal the planned set.'
    }
    if ([string](Get-TestTouchRealIndex) -eq '1') {
        # Test-only deterministic hook: simulate a concurrent actor rewriting
        # the real index (read-tree rewrites it without stat cache) so the
        # pre-swap concurrency check fires on every run without polling races.
        Invoke-Git -Arguments @('-C', $ctx.ProjectRoot, 'read-tree', 'HEAD') | Out-Null
    }
    if ((Get-RealIndexHash) -cne $ctx.IndexPreHash) {
        Throw-PackError -Condition 'CONCURRENT_STATE_CHANGE' -Message 'The real Git index changed during the transaction.'
    }
    Assert-FailAt -Point 'BeforeIndexSwap'
    $alternateBytes = [System.IO.File]::ReadAllBytes($ctx.AlternateIndexPath)
    Write-RealIndexBytesAtomic -Bytes $alternateBytes
    $ctx.IndexSwapped = $true
    if ((Get-RealIndexHash) -cne (Get-Sha256Bytes -Bytes $alternateBytes)) {
        Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The committed real index does not match the verified alternate index.'
    }
    Assert-FailAt -Point 'AfterIndexSwap'
}

function Invoke-FinalVerification {
    $ctx = $script:Ctx
    $stagedSet = @(Get-GitPathList -Arguments @('-C', $ctx.ProjectRoot, 'diff', '--cached', '--name-only', '-z'))
    $expected = @($ctx.PlannedStageSet | Sort-Object -Unique)
    $actual = @($stagedSet | Sort-Object -Unique)
    if (($expected -join "`0") -cne ($actual -join "`0")) {
        Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The real staged path set does not equal the planned set.'
    }
    $unstaged = @(Get-GitPathList -Arguments @('-C', $ctx.ProjectRoot, 'diff', '--name-only', '-z'))
    $untracked = @(Get-GitPathList -Arguments @('-C', $ctx.ProjectRoot, 'ls-files', '--others', '--exclude-standard', '-z'))
    if ($unstaged.Count -gt 0 -or $untracked.Count -gt 0) {
        Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'Unexpected unstaged or untracked changes remain after staging.'
    }
    $manifest = Read-RuntimeManifest -ManifestPath $ctx.ManifestPath
    [void](Test-PackAdaptersCurrent -Manifest $manifest)
    if ($HubMode -eq 'Submodule') {
        $gitlink = Get-GitlinkCommit -RelPath $ctx.HubPathNorm
        if ($gitlink -cne $ctx.ResolvedCommit) {
            Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The committed gitlink does not equal the resolved commit.'
        }
        $head = Get-SubmoduleHead -HubAbsPath $ctx.HubAbsPath
        if ($head -cne $ctx.ResolvedCommit) {
            Throw-PackError -Condition 'UNEXPECTED_ERROR' -Message 'The submodule HEAD does not equal the resolved commit.'
        }
    }
}

function Invoke-PackRollback {
    $ctx = $script:Ctx
    $verified = $true
    $failureNote = ''
    $failures = New-Object 'System.Collections.Generic.List[string]'
    # Test-only hook: deliberately skip one cleanup step so rollback
    # verification can be proven to detect the residue.
    $skip = [string](Get-TestRollbackSkip)
    $moduleDir = Join-Path $ctx.GitDir "modules\$($script:SubmoduleName)"
    $gitmodulesPath = Join-Path $ctx.ProjectRoot '.gitmodules'
    try {
        # Step 2: restore or clean index state.
        if ($ctx.IndexSwapped) {
            Write-RealIndexBytesAtomic -Bytes $ctx.IndexPreBytes
            if ((Get-RealIndexHash) -cne $ctx.IndexPreHash) {
                $verified = $false
                $failures.Add('real index restore failed')
            }
            if (-not [string]::IsNullOrEmpty($ctx.AlternateIndexPath) -and (Test-Path -LiteralPath $ctx.AlternateIndexPath -PathType Leaf)) {
                Remove-Item -LiteralPath $ctx.AlternateIndexPath -Force -ErrorAction SilentlyContinue
            }
        }
        else {
            if (-not [string]::IsNullOrEmpty($ctx.AlternateIndexPath) -and (Test-Path -LiteralPath $ctx.AlternateIndexPath -PathType Leaf)) {
                Remove-Item -LiteralPath $ctx.AlternateIndexPath -Force -ErrorAction SilentlyContinue
            }
            if ((Get-RealIndexHash) -cne $ctx.IndexPreHash) {
                # Defensive restoration when a concurrent actor touched the real index.
                Write-RealIndexBytesAtomic -Bytes $ctx.IndexPreBytes
                if ((Get-RealIndexHash) -cne $ctx.IndexPreHash) {
                    $verified = $false
                    $failures.Add('real index restore failed')
                }
            }
        }
        if ((Get-FailAt) -ceq 'DuringRollback') {
            throw (New-PackException -Condition 'UNEXPECTED_ERROR' -Message 'Injected rollback failure.')
        }
        # Step 3: restore backed-up human files, delete files created by this transaction.
        foreach ($path in $ctx.HumanFileBackups.Keys) {
            $backupBytes = [System.IO.File]::ReadAllBytes($ctx.HumanFileBackups[$path])
            [System.IO.File]::WriteAllBytes($path, $backupBytes)
            if ((Get-Sha256File -Path $path) -cne (Get-Sha256Bytes -Bytes $backupBytes)) {
                $verified = $false
                $failures.Add('human file restore failed')
            }
        }
        foreach ($created in $ctx.CreatedPaths) {
            if ((Test-PathInside -Candidate $created -Parent $ctx.ProjectRoot) -and (Test-Path -LiteralPath $created -PathType Leaf)) {
                Remove-Item -LiteralPath $created -Force -ErrorAction SilentlyContinue
            }
        }
        # Step 4: restore .gitmodules.
        if ($ctx.GitmodulesExistedPre) {
            [System.IO.File]::WriteAllBytes($gitmodulesPath, $ctx.GitmodulesPreBytes)
        }
        elseif (Test-Path -LiteralPath $gitmodulesPath -PathType Leaf) {
            Remove-Item -LiteralPath $gitmodulesPath -Force -ErrorAction SilentlyContinue
        }
        # Step 5: submodule artifacts. Decisions compare the journaled
        # pre-state with the re-probed CURRENT state, so residue created by a
        # partially completed mutation is cleaned even when the mutation phase
        # never returned.
        if ($HubMode -eq 'Submodule') {
            if ($ctx.HubPathCreated -and (Test-Path -LiteralPath $ctx.HubAbsPath)) {
                if (Test-PathInside -Candidate $ctx.HubAbsPath -Parent $ctx.ProjectRoot) {
                    Remove-Item -LiteralPath $ctx.HubAbsPath -Recurse -Force -ErrorAction SilentlyContinue
                }
                else {
                    $verified = $false
                    $failures.Add('hub path scope check failed')
                }
            }
            elseif (($ctx.HubPathPreState -eq 'empty') -and (Test-Path -LiteralPath $ctx.HubAbsPath -PathType Container)) {
                # The hub directory pre-existed empty; only content introduced
                # by this transaction (e.g. a partial materialize) is removed.
                $hubChildren = @(Get-ChildItem -LiteralPath $ctx.HubAbsPath -Force -ErrorAction SilentlyContinue)
                if ($hubChildren.Count -gt 0) {
                    if (Test-PathInside -Candidate $ctx.HubAbsPath -Parent $ctx.ProjectRoot) {
                        Get-ChildItem -LiteralPath $ctx.HubAbsPath -Force -ErrorAction SilentlyContinue |
                            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                    }
                    else {
                        $verified = $false
                        $failures.Add('hub path scope check failed')
                    }
                }
            }
            if ((-not $ctx.ModuleGitDirExisted) -and (Test-Path -LiteralPath $moduleDir) -and ($skip -cne 'module-gitdir')) {
                if (Test-PathInside -Candidate $moduleDir -Parent (Join-Path $ctx.GitDir 'modules')) {
                    Remove-Item -LiteralPath $moduleDir -Recurse -Force -ErrorAction SilentlyContinue
                }
                else {
                    $verified = $false
                    $failures.Add('module gitdir scope check failed')
                }
            }
            if ($skip -cne 'config') {
                $configNow = Invoke-Git -Arguments @('-C', $ctx.ProjectRoot, 'config', '--get-regexp', "^submodule\.$($script:SubmoduleName)\.")
                $configNowText = ''
                if ($configNow.ExitCode -eq 0) {
                    $configNowText = $configNow.StdOut
                }
                if ($configNowText -cne $ctx.ConfigSectionPreText) {
                    Invoke-Git -Arguments @('-C', $ctx.ProjectRoot, 'config', '--remove-section', "submodule.$($script:SubmoduleName)") -AllowNonZero | Out-Null
                    if (-not [string]::IsNullOrEmpty($ctx.ConfigSectionPreText)) {
                        foreach ($line in ($ctx.ConfigSectionPreText -split "`n")) {
                            $trimmed = $line.TrimEnd("`r")
                            if ([string]::IsNullOrWhiteSpace($trimmed)) {
                                continue
                            }
                            $splitAt = $trimmed.IndexOf(' ')
                            if ($splitAt -lt 1) {
                                continue
                            }
                            $cfgName = $trimmed.Substring(0, $splitAt)
                            $cfgValue = $trimmed.Substring($splitAt + 1)
                            Invoke-Git -Arguments @('-C', $ctx.ProjectRoot, 'config', '--add', $cfgName, $cfgValue) -AllowNonZero | Out-Null
                        }
                    }
                }
            }
        }
        # Step 5b: remove only directories this transaction explicitly created,
        # deepest first, and only while still empty. Pre-existing directories
        # (empty or not) are never touched.
        foreach ($dir in ($ctx.CreatedDirectories | Sort-Object { $_.Length } -Descending)) {
            if (-not (Test-PathInside -Candidate $dir -Parent $ctx.ProjectRoot)) {
                $verified = $false
                $failures.Add('created directory scope check failed')
                continue
            }
            if (Test-Path -LiteralPath $dir -PathType Container) {
                $dirChildren = @(Get-ChildItem -LiteralPath $dir -Force -ErrorAction SilentlyContinue)
                if ($dirChildren.Count -eq 0) {
                    Remove-Item -LiteralPath $dir -Force -ErrorAction SilentlyContinue
                }
                else {
                    $verified = $false
                    $failures.Add("transaction-created directory is not empty at rollback: $dir")
                }
            }
        }
        # Step 6: verify exact pre-state.
        $statusResult = Invoke-Git -Arguments @('-C', $ctx.ProjectRoot, 'status', '--porcelain=v2', '--untracked-files=all')
        $statusNow = $statusResult.StdOut.TrimEnd("`r", "`n")
        if ($statusNow -cne $ctx.StatusPre) {
            $verified = $false
            $failures.Add('worktree status differs from pre-state')
        }
        # The raw index byte hash is stat-cache sensitive (any legitimate Git
        # refresh rewrites it), so pre-state equality is verified on the staged
        # entry set (mode/OID/stage/path), which is the mutation-relevant
        # content. Byte-hash equality is enforced immediately after every
        # restore write above; here the entry set is authoritative.
        $entriesNow = (Invoke-Git -Arguments @('-C', $ctx.ProjectRoot, 'ls-files', '-s', '-z')).StdOut
        if ($entriesNow -cne $ctx.IndexEntriesPre) {
            $verified = $false
            $failures.Add('real index entries differ from pre-state')
        }
        if (-not [string]::IsNullOrEmpty($ctx.AlternateIndexPath) -and (Test-Path -LiteralPath $ctx.AlternateIndexPath -PathType Leaf)) {
            $verified = $false
            $failures.Add('alternate transaction index still present')
        }
        foreach ($path in $ctx.HumanFileBackups.Keys) {
            $backupBytes = [System.IO.File]::ReadAllBytes($ctx.HumanFileBackups[$path])
            if ((Get-Sha256File -Path $path) -cne (Get-Sha256Bytes -Bytes $backupBytes)) {
                $verified = $false
                $failures.Add('human file hash differs from pre-state')
            }
        }
        foreach ($created in $ctx.CreatedPaths) {
            if (Test-Path -LiteralPath $created) {
                $verified = $false
                $failures.Add("transaction-created path still present: $created")
            }
        }
        foreach ($dir in $ctx.CreatedDirectories) {
            if (Test-Path -LiteralPath $dir) {
                $verified = $false
                $failures.Add("transaction-created directory still present: $dir")
            }
        }
        $gitmodulesNow = Test-Path -LiteralPath $gitmodulesPath -PathType Leaf
        if ($ctx.GitmodulesExistedPre) {
            if (-not $gitmodulesNow -or (Get-Sha256File -Path $gitmodulesPath) -cne (Get-Sha256Bytes -Bytes $ctx.GitmodulesPreBytes)) {
                $verified = $false
                $failures.Add('.gitmodules differs from pre-state')
            }
        }
        elseif ($gitmodulesNow) {
            $verified = $false
            $failures.Add('.gitmodules was not restored to absent')
        }
        if ($HubMode -eq 'Submodule') {
            $configVerify = Invoke-Git -Arguments @('-C', $ctx.ProjectRoot, 'config', '--get-regexp', "^submodule\.$($script:SubmoduleName)\.")
            $configVerifyText = ''
            if ($configVerify.ExitCode -eq 0) {
                $configVerifyText = $configVerify.StdOut
            }
            if ($configVerifyText -cne $ctx.ConfigSectionPreText) {
                $verified = $false
                $failures.Add('submodule config section differs from pre-state')
            }
            $moduleDirNow = Test-Path -LiteralPath $moduleDir -PathType Container
            if ($moduleDirNow -ne $ctx.ModuleGitDirExisted) {
                $verified = $false
                $failures.Add('submodule module gitdir state differs from pre-state')
            }
            $hubNow = Test-Path -LiteralPath $ctx.HubAbsPath
            if ($hubNow -ne $ctx.HubPathExistedPre) {
                $verified = $false
                $failures.Add('hub worktree existence differs from pre-state')
            }
            elseif ($ctx.HubPathPreState -eq 'empty') {
                $hubChildrenNow = @(Get-ChildItem -LiteralPath $ctx.HubAbsPath -Force -ErrorAction SilentlyContinue)
                if ($hubChildrenNow.Count -gt 0) {
                    $verified = $false
                    $failures.Add('hub worktree was not restored to its empty pre-state')
                }
            }
        }
    }
    catch {
        $verified = $false
        $failures.Add('rollback raised an error')
    }
    if ($failures.Count -gt 0) {
        $failureNote = ($failures | Select-Object -Unique) -join '; '
    }
    return [pscustomobject]@{ Verified = $verified; Note = $failureNote }
}

function Invoke-PackMain {
    try {
        Invoke-Preflight

        if ($script:Ctx.ManifestExists) {
            Invoke-ManifestRerunEvaluation
            if ($script:Ctx.SubmoduleAction -ne 'materialize') {
                if (-not $script:Ctx.RequiresHashNormalizationMigration) {
                    $script:Result.Decision = $script:DecisionMap['NO_CHANGE']
                    $script:Result.Message = 'Project runtime pack is already current.'
                    Write-PackResult
                    return 0
                }
                Invoke-ManifestHashMigrationPlan
                if ($DryRun) {
                    $script:Result.Decision = $script:DecisionMap['DRY_RUN']
                    $script:Result.Message = 'DryRun completed with zero repository mutation.'
                    Write-PackResult
                    return 0
                }
            }
            else {
                # Materialize-only path: valid manifest, committed gitlink, missing checkout.
                Add-PlanAction -Token "submodule-materialize:$($script:Ctx.HubPathNorm)" -Mutating $true -WorktreeChange $true
                $script:Result.Planned_Actions = (($script:Ctx.Plan | ForEach-Object { $_.Token }) -join ';')
                $script:Result.Changed_Count = 1
                if ($DryRun) {
                    $script:Result.Decision = $script:DecisionMap['DRY_RUN']
                    $script:Result.Message = 'DryRun completed with zero repository mutation.'
                    Write-PackResult
                    return 0
                }
            }
        }
        else {
            Invoke-Plan
            if ($DryRun) {
                $script:Result.Decision = $script:DecisionMap['DRY_RUN']
                $script:Result.Message = 'DryRun completed with zero repository mutation.'
                Write-PackResult
                return 0
            }
        }

        # --- Transaction ------------------------------------------------------
        $ctx = $script:Ctx
        $ctx.JournalRoot = Join-Path $ctx.GitDir ('runtime-pack-journal-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $ctx.JournalRoot -Force | Out-Null
        $ctx.AlternateIndexPath = Join-Path $ctx.JournalRoot 'alternate.index'
        if ($ctx.IndexPreExisted) {
            [System.IO.File]::WriteAllBytes((Join-Path $ctx.JournalRoot 'index.pre'), $ctx.IndexPreBytes)
        }
        if ($ctx.GitmodulesExistedPre) {
            [System.IO.File]::WriteAllBytes((Join-Path $ctx.JournalRoot 'gitmodules.pre'), $ctx.GitmodulesPreBytes)
        }
        if ($ctx.ManifestExists) {
            $manifestBackupPath = Join-Path $ctx.JournalRoot ('backup-' + [guid]::NewGuid().ToString('N'))
            [System.IO.File]::WriteAllBytes($manifestBackupPath, [System.IO.File]::ReadAllBytes($ctx.ManifestPath))
            $ctx.HumanFileBackups[$ctx.ManifestPath] = $manifestBackupPath
        }
        foreach ($def in $script:AdapterDefs) {
            $absPath = Join-Path $ctx.ProjectRoot ([string]$def.Path).Replace('/', '\')
            if (Test-Path -LiteralPath $absPath -PathType Leaf) {
                $backupPath = Join-Path $ctx.JournalRoot ('backup-' + [guid]::NewGuid().ToString('N'))
                [System.IO.File]::WriteAllBytes($backupPath, [System.IO.File]::ReadAllBytes($absPath))
                $ctx.HumanFileBackups[$absPath] = $backupPath
            }
        }
        $ctx.HubPathCreated = ($ctx.SubmoduleAction -eq 'add')
        $ctx.MutationStarted = $true
        Write-JournalFile

        Invoke-SubmoduleMutation
        Assert-FailAt -Point 'AfterSubmodule'

        if (-not $ctx.ManifestExists) {
            Invoke-AdapterGeneration
            Invoke-ManifestGeneration
            Assert-FailAt -Point 'AfterManifest'
        }
        elseif ($ctx.RequiresHashNormalizationMigration) {
            Invoke-ManifestHashMetadataMigration
            Assert-FailAt -Point 'AfterManifest'
        }
        Invoke-PackValidation
        Invoke-CommitReady
        Invoke-FinalVerification

        Remove-Item -LiteralPath $ctx.JournalRoot -Recurse -Force -ErrorAction SilentlyContinue
        $script:Result.Decision = $script:DecisionMap['INITIALIZED']
        $script:Result.Manifest_Status = 'VALID'
        if ($ctx.PlannedStageSet.Count -gt 0) {
            $script:Result.Index_Change = 'YES'
        }
        if (@($ctx.Plan | Where-Object { $_.WorktreeChange }).Count -gt 0) {
            $script:Result.Working_Tree_Change = 'YES'
        }
        $script:Result.Message = 'Project runtime pack initialized and staged for commit.'
        Write-PackResult
        return 0
    }
    catch [System.Management.Automation.MethodInvocationException] {
        return (Invoke-PackFailure -ErrorRecord $_)
    }
    catch {
        return (Invoke-PackFailure -ErrorRecord $_)
    }
}

function Invoke-PackFailure {
    param([Parameter(Mandatory = $true)][System.Management.Automation.ErrorRecord]$ErrorRecord)
    $exception = $ErrorRecord.Exception
    $condition = 'UNEXPECTED_ERROR'
    if ($null -ne $exception -and $exception.Data.Contains('Condition')) {
        $condition = [string]$exception.Data['Condition']
    }
    $message = $exception.Message
    if (
        $null -ne $script:Ctx -and
        $script:Ctx.ManifestExists -and
        $script:Result.Manifest_Status -eq 'ABSENT'
    ) {
        $script:Result.Manifest_Status = 'INVALID'
    }
    $mutationStarted = ($null -ne $script:Ctx) -and $script:Ctx.MutationStarted
    Write-PackDiagnostic "ERROR: $message"
    if (-not $mutationStarted) {
        $script:Result.Decision = $script:DecisionMap[$condition]
        $script:Result.Message = $message
        Write-PackResult
        return 2
    }
    # Refresh the journal so created paths/directories registered by partially
    # completed phases are recorded before rollback (best effort evidence).
    try {
        Write-JournalFile
    }
    catch {
        # Journal refresh is best effort; rollback proceeds from in-memory state.
    }
    $rollback = Invoke-PackRollback
    if ($rollback.Verified) {
        Remove-Item -LiteralPath $script:Ctx.JournalRoot -Recurse -Force -ErrorAction SilentlyContinue
        $script:Result.Rollback_Status = 'RESTORED'
        if ($condition -eq 'CONCURRENT_STATE_CHANGE') {
            $script:Result.Decision = $script:DecisionMap['CONCURRENT_STATE_CHANGE']
            $script:Result.Message = $message
        }
        else {
            $script:Result.Decision = $script:DecisionMap['FAILED_APPLY_ROLLED_BACK']
            $script:Result.Message = 'Apply failed; the exact pre-state was restored and verified.'
        }
        Write-PackResult
        return 3
    }
    $script:Result.Rollback_Status = 'FAILED_EVIDENCE_RETAINED'
    $script:Result.Decision = $script:DecisionMap['ROLLBACK_FAILURE']
    $journalPath = [string]$script:Ctx.JournalRoot
    $script:Result.Message = "Rollback could not be verified ($($rollback.Note)); evidence retained at $journalPath"
    Write-PackDiagnostic "Rollback failure evidence retained at: $journalPath"
    Write-PackResult
    return 4
}

$exitCode = Invoke-PackMain
exit $exitCode
