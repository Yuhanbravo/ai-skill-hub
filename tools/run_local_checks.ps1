[CmdletBinding()]
param(
    [ValidateSet('router', 'governance', 'smoke', 'all')]
    [string]$Checks = 'smoke',

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

    $stdoutPath = [System.IO.Path]::GetTempFileName()
    $stderrPath = [System.IO.Path]::GetTempFileName()

    try {
        $probeArguments = @($Candidate.base_arguments + '--version')
        $process = Start-Process `
            -FilePath $Candidate.program `
            -ArgumentList $probeArguments `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath

        if ($process.ExitCode -ne 0) {
            return $false
        }

        $stdout = if (Test-Path -LiteralPath $stdoutPath) {
            [string](Get-Content -LiteralPath $stdoutPath -Raw -Encoding UTF8)
        }
        else {
            ''
        }
        $stderr = if (Test-Path -LiteralPath $stderrPath) {
            [string](Get-Content -LiteralPath $stderrPath -Raw -Encoding UTF8)
        }
        else {
            ''
        }
        $versionOutput = [string]$stdout + [string]$stderr
        return $versionOutput -match '(?i)\bPython\s+\d+\.\d+'
    }
    catch {
        return $false
    }
    finally {
        if (Test-Path -LiteralPath $stdoutPath) {
            Remove-Item -LiteralPath $stdoutPath -Force
        }
        if (Test-Path -LiteralPath $stderrPath) {
            Remove-Item -LiteralPath $stderrPath -Force
        }
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
        $program
    }
}

function Get-Executor {
    param(
        [AllowEmptyString()]
        [string]$PreferredCondaEnv,

        [switch]$PreferPyLauncher
    )

    $resolvedCondaEnv = ''
    if (-not [string]::IsNullOrWhiteSpace($PreferredCondaEnv)) {
        $resolvedCondaEnv = $PreferredCondaEnv.Trim()
        foreach ($program in @(Get-ApplicationCandidates -Name 'conda')) {
            $candidate = [pscustomobject]@{
                kind = 'conda'
                display_name = "$program run -n $resolvedCondaEnv python"
                program = $program
                base_arguments = @('run', '-n', $resolvedCondaEnv, 'python')
                conda_env = $resolvedCondaEnv
            }
            if (Test-ExecutorCandidate -Candidate $candidate) {
                return $candidate
            }
        }

        throw "Environment issue: the explicit Conda environment '$resolvedCondaEnv' did not provide an executable Python that returned version information."
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

    if (-not [string]::IsNullOrWhiteSpace($env:CONDA_DEFAULT_ENV)) {
        $resolvedCondaEnv = $env:CONDA_DEFAULT_ENV.Trim()
    }

    $condaPrograms = @(Get-ApplicationCandidates -Name 'conda')
    if (-not [string]::IsNullOrWhiteSpace($resolvedCondaEnv)) {
        foreach ($program in $condaPrograms) {
            $candidate = [pscustomobject]@{
                kind = 'conda'
                display_name = "$program run -n $resolvedCondaEnv python"
                program = $program
                base_arguments = @('run', '-n', $resolvedCondaEnv, 'python')
                conda_env = $resolvedCondaEnv
            }
            if (Test-ExecutorCandidate -Candidate $candidate) {
                return $candidate
            }
        }
    }

    if (($condaPrograms.Count -gt 0) -and [string]::IsNullOrWhiteSpace($resolvedCondaEnv)) {
        throw 'Environment issue: no executable Python candidate was found, and Conda has no provided or active environment. Pass -CondaEnvName explicitly.'
    }

    throw 'Environment issue: no Python executor candidate successfully returned version information.'
}

function Get-CheckCatalog {
    return [ordered]@{
        router = @(
            @{
                name = 'skill-router'
                args = @('tests\test_skill_router.py')
            }
        )
        governance = @(
            @{
                name = 'adapter-consistency-smoke'
                args = @('tests\test_adapter_consistency_smoke.py')
            }
            @{
                name = 'commit-convention'
                args = @('tests\test_commit_convention_check.py')
            }
            @{
                name = 'hub-adapter-contract'
                args = @('tools\check_adapter_consistency.py', '.', '--mode', 'hub')
            }
        )
        smoke = @(
            @{
                name = 'skill-router'
                args = @('tests\test_skill_router.py')
            }
            @{
                name = 'adapter-consistency-smoke'
                args = @('tests\test_adapter_consistency_smoke.py')
            }
            @{
                name = 'commit-convention'
                args = @('tests\test_commit_convention_check.py')
            }
            @{
                name = 'hub-adapter-contract'
                args = @('tools\check_adapter_consistency.py', '.', '--mode', 'hub')
            }
            @{
                name = 'dryrun-no-side-effects'
                args = @('tests\test_dryrun_no_side_effects.py')
            }
            @{
                name = 'codex-user-skills-bootstrap'
                args = @('-m', 'pytest', 'tests\test_codex_user_skills_bootstrap.py', '-q', '-p', 'no:cacheprovider')
            }
            @{
                name = 'reseed-audit'
                args = @('tests\test_audit_reseed_targets.py')
            }
        )
        all = @(
            @{
                name = 'skill-router'
                args = @('tests\test_skill_router.py')
            }
            @{
                name = 'adapter-consistency-smoke'
                args = @('tests\test_adapter_consistency_smoke.py')
            }
            @{
                name = 'commit-convention'
                args = @('tests\test_commit_convention_check.py')
            }
            @{
                name = 'hub-adapter-contract'
                args = @('tools\check_adapter_consistency.py', '.', '--mode', 'hub')
            }
            @{
                name = 'dryrun-no-side-effects'
                args = @('tests\test_dryrun_no_side_effects.py')
            }
            @{
                name = 'codex-user-skills-bootstrap'
                args = @('-m', 'pytest', 'tests\test_codex_user_skills_bootstrap.py', '-q', '-p', 'no:cacheprovider')
            }
            @{
                name = 'reseed-audit'
                args = @('tests\test_audit_reseed_targets.py')
            }
            @{
                name = 'sync-smoke'
                args = @('tests\test_sync_skills_to_nongit_project.py')
            }
            @{
                name = 'skill-structure'
                args = @('tests\test_skill_structure.py')
            }
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

    $arguments = @($Executor.base_arguments + $CheckDefinition.args)
    Write-Info ("Running {0}: {1} {2}" -f $CheckDefinition.name, $Executor.display_name, ($CheckDefinition.args -join ' '))

    $stdoutPath = [System.IO.Path]::GetTempFileName()
    $stderrPath = [System.IO.Path]::GetTempFileName()

    try {
        $process = Start-Process `
            -FilePath $Executor.program `
            -ArgumentList $arguments `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath

        $stdout = if (Test-Path -LiteralPath $stdoutPath) {
            [string](Get-Content -LiteralPath $stdoutPath -Raw -Encoding UTF8)
        }
        else {
            ''
        }
        $stderr = if (Test-Path -LiteralPath $stderrPath) {
            [string](Get-Content -LiteralPath $stderrPath -Raw -Encoding UTF8)
        }
        else {
            ''
        }
        $output = ([string]$stdout + [string]$stderr).TrimEnd()
        $exitCode = $process.ExitCode
    }
    finally {
        if (Test-Path -LiteralPath $stdoutPath) {
            Remove-Item -LiteralPath $stdoutPath -Force
        }
        if (Test-Path -LiteralPath $stderrPath) {
            Remove-Item -LiteralPath $stderrPath -Force
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($output)) {
        Write-Host $output
    }

    if ($exitCode -eq 0) {
        return [pscustomobject]@{
            name = $CheckDefinition.name
            status = 'passed'
            failure_type = ''
            exit_code = 0
        }
    }

    return [pscustomobject]@{
        name = $CheckDefinition.name
        status = 'failed'
        failure_type = (Classify-Failure -Output $output)
        exit_code = $exitCode
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
