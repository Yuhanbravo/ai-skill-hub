[CmdletBinding()]
param(
    [ValidateSet('router', 'governance', 'smoke', 'all')]
    [string]$Checks = 'smoke',

    [AllowEmptyString()]
    [string]$CondaEnvName,

    [switch]$UsePyLauncher
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Section {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host ""
    Write-Host "[SECTION] $Message" -ForegroundColor Cyan
}

function Write-Info {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "[INFO] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "[PASS] $Message" -ForegroundColor Green
}

function Write-Failure {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Get-RepoRoot {
    $scriptFilePath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif ($MyInvocation.MyCommand.Path) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Could not determine script path.'
    }

    return (Resolve-Path -LiteralPath (Join-Path (Split-Path -Path $scriptFilePath -Parent) '..')).ProviderPath
}

function Test-ExecutorCandidate {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Candidate
    )

    try {
        $probeArguments = @($Candidate.base_arguments) + @('--version')
        $probeOutput = @(& $Candidate.program @probeArguments 2>&1)
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            return $false
        }

        $versionOutput = ($probeOutput | Out-String).Trim()
        return $versionOutput -match '(?i)\APython\s+\d+\.\d+(?:\.\d+)?(?:[a-z]+\d*)?\z'
    }
    catch {
        return $false
    }
}

function Get-ApplicationCandidates {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $seen = @{}
    $commands = @(Get-Command $Name -All -CommandType Application -ErrorAction SilentlyContinue)
    foreach ($command in $commands) {
        $program = [string]$command.Source
        if ([string]::IsNullOrWhiteSpace($program)) {
            continue
        }

        $key = $program.ToLowerInvariant()
        if ($seen.ContainsKey($key)) {
            continue
        }
        $seen[$key] = $true
        if (Test-Path -LiteralPath $program -PathType Leaf) {
            (Resolve-Path -LiteralPath $program).ProviderPath
        }
    }
}

function Test-CondaEnvironmentName {
    param(
        [AllowEmptyString()]
        [string]$Name
    )

    return (
        -not [string]::IsNullOrWhiteSpace($Name) -and
        $Name -cmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$'
    )
}

function Get-CondaEnvironmentExecutor {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentName
    )

    foreach ($condaProgram in @(Get-ApplicationCandidates -Name 'conda')) {
        try {
            $infoArguments = @('info', '--envs', '--json')
            $infoOutput = @(& $condaProgram @infoArguments 2>&1)
            $infoExitCode = $LASTEXITCODE
            if ($infoExitCode -ne 0) {
                continue
            }

            $info = ($infoOutput | Out-String) | ConvertFrom-Json
            $environmentRoots = @($info.envs)
            if (
                $EnvironmentName -ceq 'base' -and
                -not [string]::IsNullOrWhiteSpace([string]$info.root_prefix)
            ) {
                $environmentRoots = @([string]$info.root_prefix) + $environmentRoots
            }

            foreach ($environmentRootValue in $environmentRoots) {
                if ([string]::IsNullOrWhiteSpace([string]$environmentRootValue)) {
                    continue
                }

                $environmentRoot = [System.IO.Path]::GetFullPath(
                    ([string]$environmentRootValue).TrimEnd('\', '/')
                )
                $resolvedName = Split-Path -Path $environmentRoot -Leaf
                if (
                    $EnvironmentName -cne $resolvedName -and
                    -not (
                        $EnvironmentName -ceq 'base' -and
                        [string]$environmentRoot -ceq [string]$info.root_prefix
                    )
                ) {
                    continue
                }

                $pythonExecutable = Join-Path $environmentRoot 'python.exe'
                if (-not (Test-Path -LiteralPath $pythonExecutable -PathType Leaf)) {
                    continue
                }

                $resolvedPython = (Resolve-Path -LiteralPath $pythonExecutable).ProviderPath
                $candidate = [pscustomobject]@{
                    kind = 'conda'
                    display_name = $resolvedPython
                    program = $resolvedPython
                    base_arguments = @()
                    conda_env = $EnvironmentName
                }
                if (Test-ExecutorCandidate -Candidate $candidate) {
                    return $candidate
                }
            }
        }
        catch {
            continue
        }
    }

    throw "Environment issue: the explicit Conda environment '$EnvironmentName' did not resolve to an executable python.exe that returned version information."
}

function Get-Executor {
    param(
        [AllowEmptyString()]
        [string]$PreferredCondaEnv,

        [switch]$PreferPyLauncher
    )

    if (-not [string]::IsNullOrWhiteSpace($PreferredCondaEnv)) {
        return Get-CondaEnvironmentExecutor -EnvironmentName $PreferredCondaEnv
    }

    if (-not $PreferPyLauncher) {
        foreach ($program in @(Get-ApplicationCandidates -Name 'python')) {
            $candidate = [pscustomobject]@{
                kind = 'python'
                display_name = $program
                program = $program
                base_arguments = @()
                conda_env = ''
            }
            if (Test-ExecutorCandidate -Candidate $candidate) {
                return $candidate
            }
        }
    }

    foreach ($program in @(Get-ApplicationCandidates -Name 'py')) {
        $candidate = [pscustomobject]@{
            kind = 'py'
            display_name = "$program -3"
            program = $program
            base_arguments = @('-3')
            conda_env = ''
        }
        if (Test-ExecutorCandidate -Candidate $candidate) {
            return $candidate
        }
    }

    if (
        -not [string]::IsNullOrWhiteSpace($env:CONDA_DEFAULT_ENV) -and
        (Test-CondaEnvironmentName -Name $env:CONDA_DEFAULT_ENV)
    ) {
        try {
            return Get-CondaEnvironmentExecutor -EnvironmentName $env:CONDA_DEFAULT_ENV
        }
        catch {
            # Continue to the single environment error below.
        }
    }

    if (@(Get-ApplicationCandidates -Name 'conda').Count -gt 0) {
        throw 'Environment issue: no executable Python candidate was found, and Conda has no provided or active environment. Pass -CondaEnvName explicitly.'
    }

    throw 'Environment issue: no Python executor candidate successfully returned version information.'
}

function Get-CheckCatalog {
    $skillRouter = @{
        name = 'skill-router'
        args = @('tests\test_skill_router.py')
        expected_evidence = 'tests\test_skill_router.py'
    }
    $adapterConsistency = @{
        name = 'adapter-consistency-smoke'
        args = @('tests\test_adapter_consistency_smoke.py')
        expected_evidence = 'tests\test_adapter_consistency_smoke.py'
    }
    $commitConvention = @{
        name = 'commit-convention'
        args = @('tests\test_commit_convention_check.py')
        expected_evidence = 'tests\test_commit_convention_check.py'
    }
    $hubAdapterContract = @{
        name = 'hub-adapter-contract'
        args = @('tools\check_adapter_consistency.py', '.', '--mode', 'hub')
        expected_evidence = 'tools\check_adapter_consistency.py'
    }
    $dryRunNoSideEffects = @{
        name = 'dryrun-no-side-effects'
        args = @('tests\test_dryrun_no_side_effects.py')
        expected_evidence = 'tests\test_dryrun_no_side_effects.py'
    }
    $codexUserSkillsBootstrap = @{
        name = 'codex-user-skills-bootstrap'
        args = @('-m', 'pytest', 'tests\test_codex_user_skills_bootstrap.py', '-q', '-p', 'no:cacheprovider')
        expected_evidence = 'tests\test_codex_user_skills_bootstrap.py'
    }
    $reseedAudit = @{
        name = 'reseed-audit'
        args = @('tests\test_audit_reseed_targets.py')
        expected_evidence = 'tests\test_audit_reseed_targets.py'
    }
    $syncSmoke = @{
        name = 'sync-smoke'
        args = @('tests\test_sync_skills_to_nongit_project.py')
        expected_evidence = 'tests\test_sync_skills_to_nongit_project.py'
    }
    $skillStructure = @{
        name = 'skill-structure'
        args = @('tests\test_skill_structure.py')
        expected_evidence = 'tests\test_skill_structure.py'
    }
    $projectRuntimePack = @{
        name = 'project-runtime-pack'
        args = @('-m', 'pytest', 'tests\test_init_project_runtime_pack.py', '-q', '-p', 'no:cacheprovider')
        expected_evidence = 'tests\test_init_project_runtime_pack.py'
    }

    return [ordered]@{
        router = @($skillRouter)
        governance = @(
            $adapterConsistency
            $commitConvention
            $hubAdapterContract
        )
        smoke = @(
            $skillRouter
            $adapterConsistency
            $commitConvention
            $hubAdapterContract
            $dryRunNoSideEffects
            $codexUserSkillsBootstrap
            $reseedAudit
            $projectRuntimePack
        )
        all = @(
            $skillRouter
            $adapterConsistency
            $commitConvention
            $hubAdapterContract
            $dryRunNoSideEffects
            $codexUserSkillsBootstrap
            $reseedAudit
            $syncSmoke
            $skillStructure
            $projectRuntimePack
        )
    }
}

function Classify-Failure {
    param(
        [AllowEmptyString()]
        [string]$Output
    )

    if (
        $Output -match 'PermissionError' -or
        $Output -match 'Access is denied' -or
        $Output -match '拒绝访问' -or
        $Output -match 'ShellExecuteExW failed'
    ) {
        return 'permission'
    }

    if (
        $Output -match 'No module named' -or
        $Output -match 'ModuleNotFoundError' -or
        $Output -match 'not recognized as the name of a cmdlet' -or
        $Output -match 'Environment issue:'
    ) {
        return 'environment'
    }

    return 'logic'
}

function Invoke-Check {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Executor,

        [Parameter(Mandatory = $true)]
        [hashtable]$CheckDefinition
    )

    $arguments = @($Executor.base_arguments) + @($CheckDefinition.args)
    $expectedEvidence = [string]$CheckDefinition.expected_evidence
    Write-Info ("Running {0}: {1} {2}" -f $CheckDefinition.name, $Executor.display_name, ($CheckDefinition.args -join ' '))

    if ([string]::IsNullOrWhiteSpace($expectedEvidence) -or $arguments -cnotcontains $expectedEvidence) {
        return [pscustomobject]@{
            name = $CheckDefinition.name
            resolved_executor = $Executor.program
            exact_argument_array = @($arguments)
            expected_evidence = $expectedEvidence
            status = 'failed'
            failure_type = 'logic'
            exit_code = -1
        }
    }

    try {
        $nativeOutput = @(& $Executor.program @arguments 2>&1)
        $exitCode = $LASTEXITCODE
        $output = ($nativeOutput | Out-String).TrimEnd()
    }
    catch {
        $output = $_.Exception.Message
        $exitCode = 1
    }

    if (-not [string]::IsNullOrWhiteSpace($output)) {
        Write-Host $output
    }

    if ($exitCode -eq 0) {
        return [pscustomobject]@{
            name = $CheckDefinition.name
            resolved_executor = $Executor.program
            exact_argument_array = @($arguments)
            expected_evidence = $expectedEvidence
            status = 'passed'
            failure_type = ''
            exit_code = 0
        }
    }

    return [pscustomobject]@{
        name = $CheckDefinition.name
        resolved_executor = $Executor.program
        exact_argument_array = @($arguments)
        expected_evidence = $expectedEvidence
        status = 'failed'
        failure_type = (Classify-Failure -Output $output)
        exit_code = $exitCode
    }
}

if ($PSBoundParameters.ContainsKey('CondaEnvName')) {
    if (-not (Test-CondaEnvironmentName -Name $CondaEnvName)) {
        [Console]::Error.WriteLine(
            '[FAIL] Invalid CondaEnvName. Use 1-128 characters matching ^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$; paths, whitespace, quotes, shell characters, and extra arguments are not allowed.'
        )
        exit 2
    }
}

$repoRoot = Get-RepoRoot
$catalog = Get-CheckCatalog
$selectedChecks = @($catalog[$Checks])

if ($selectedChecks.Count -eq 0) {
    throw "No checks configured for group: $Checks"
}

$localTempRoot = Join-Path $repoRoot '.tmp\run_local_checks'
New-Item -ItemType Directory -Path $localTempRoot -Force | Out-Null

$originalTemp = $env:TEMP
$originalTmp = $env:TMP
$originalTmpDir = $env:TMPDIR
$originalPythonUtf8 = $env:PYTHONUTF8
$originalPythonIoEncoding = $env:PYTHONIOENCODING

$env:TEMP = $localTempRoot
$env:TMP = $localTempRoot
$env:TMPDIR = $localTempRoot
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'

$results = @()
$executor = $null
$executorIssue = ''

try {
    Push-Location $repoRoot

    Write-Section 'Local validation setup'
    Write-Info "Repository root: $repoRoot"
    Write-Info "Check group: $Checks"
    Write-Info "Temp root: $localTempRoot"

    try {
        $executor = Get-Executor -PreferredCondaEnv $CondaEnvName -PreferPyLauncher:$UsePyLauncher
    }
    catch {
        $executorIssue = $_.Exception.Message
    }

    if (-not [string]::IsNullOrWhiteSpace($executorIssue)) {
        Write-Failure $executorIssue
    }
    else {
        Write-Info "Executor: $($executor.display_name)"
        if ($executor.kind -eq 'conda') {
            Write-Info "Conda environment: $($executor.conda_env)"
        }
        else {
            Write-Info 'Conda environment: n/a'
        }
    }
    Write-Info ("Selected checks: {0}" -f (($selectedChecks | ForEach-Object { $_.name }) -join ', '))

    if ([string]::IsNullOrWhiteSpace($executorIssue)) {
        Write-Section 'Running checks'
        foreach ($checkDefinition in $selectedChecks) {
            $result = Invoke-Check -Executor $executor -CheckDefinition $checkDefinition
            $results += $result

            if ($result.status -eq 'passed') {
                Write-Success $checkDefinition.name
            }
            else {
                Write-Failure ("{0} ({1}, exit={2})" -f $checkDefinition.name, $result.failure_type, $result.exit_code)
            }
        }
    }
}
finally {
    Pop-Location
    $env:TEMP = $originalTemp
    $env:TMP = $originalTmp
    $env:TMPDIR = $originalTmpDir
    $env:PYTHONUTF8 = $originalPythonUtf8
    $env:PYTHONIOENCODING = $originalPythonIoEncoding
}

Write-Section 'Summary'
$passed = @($results | Where-Object { $_.status -eq 'passed' })
$failed = @($results | Where-Object { $_.status -eq 'failed' })

Write-Info "Passed: $($passed.Count)"
Write-Info "Failed: $($failed.Count)"

if (-not [string]::IsNullOrWhiteSpace($executorIssue)) {
    Write-Failure "Executor setup: environment"
    exit 2
}

if ($failed.Count -gt 0) {
    foreach ($failure in $failed) {
        Write-Failure ("{0}: {1}" -f $failure.name, $failure.failure_type)
    }
    exit 1
}

Write-Success 'All selected checks passed.'
