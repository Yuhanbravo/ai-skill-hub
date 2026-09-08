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

function Get-RepoPythonExecutor {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepositoryRoot
    )

    $command = @(
        Get-Command 'repo-python' -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandType -in @('Application', 'ExternalScript') }
    ) | Select-Object -First 1

    if ($null -eq $command) {
        throw 'Environment issue: repo-python is unavailable. Python runtime selection is governed by AI_Workbench; no fallback interpreter will be used.'
    }

    $program = [string]$command.Source
    if ([string]::IsNullOrWhiteSpace($program)) {
        throw 'Environment issue: repo-python resolved without an invocable source path.'
    }

    try {
        $resolutionOutput = @(& $program -BrokerProjectRoot $RepositoryRoot -BrokerResolveOnly 2>&1)
        $resolutionExitCode = $LASTEXITCODE
    }
    catch {
        throw "Environment issue: repo-python broker resolution could not start: $($_.Exception.Message)"
    }

    if ($resolutionExitCode -ne 0) {
        $detail = ($resolutionOutput | Out-String).Trim()
        if ([string]::IsNullOrWhiteSpace($detail)) {
            $detail = 'no diagnostic output'
        }
        throw "Environment issue: repo-python broker resolution failed (exit $resolutionExitCode): $detail"
    }

    return [pscustomobject]@{
        kind = 'repo-python'
        display_name = 'repo-python (AI_Workbench runtime broker)'
        program = $program
        project_root = $RepositoryRoot
    }
}

function Get-CheckCatalog {
    $skillRouter = @{
        name = 'skill-router'
        args = @('tests\test_skill_router.py')
        expected_evidence = 'tests\test_skill_router.py'
    }
    $universalSkillRouting = @{
        name = 'universal-skill-routing'
        args = @('tests\test_ai_skill_hub_resolver.py')
        expected_evidence = 'tests\test_ai_skill_hub_resolver.py'
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
    $runtimeAuthority = @{
        name = 'runtime-authority'
        args = @('tests\test_runtime_authority.py')
        expected_evidence = 'tests\test_runtime_authority.py'
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
            $runtimeAuthority
            $hubAdapterContract
        )
        smoke = @(
            $skillRouter
            $universalSkillRouting
            $adapterConsistency
            $commitConvention
            $runtimeAuthority
            $hubAdapterContract
            $dryRunNoSideEffects
            $codexUserSkillsBootstrap
            $reseedAudit
            $projectRuntimePack
        )
        all = @(
            $skillRouter
            $universalSkillRouting
            $adapterConsistency
            $commitConvention
            $runtimeAuthority
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

function Invoke-Check {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Executor,

        [Parameter(Mandatory = $true)]
        [hashtable]$CheckDefinition,

        [Parameter(Mandatory = $true)]
        [string]$LauncherPath,

        [Parameter(Mandatory = $true)]
        [string]$MarkerRoot
    )

    $arguments = @($CheckDefinition.args)
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
            executor_failure = $false
            exit_code = -1
        }
    }

    $startedMarker = Join-Path $MarkerRoot ('.governed-python-{0}.started' -f ([guid]::NewGuid().ToString('N')))
    $brokerArguments = @(
        $LauncherPath
        '--started-marker'
        $startedMarker
        '--'
    ) + $arguments
    $executorFailure = $false
    $governedPythonStarted = $false
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $nativeOutput = @()
        & $Executor.program -BrokerProjectRoot $Executor.project_root -PythonArgs $brokerArguments 2>&1 |
            Tee-Object -Variable nativeOutput |
            Out-Host
        $exitCode = $LASTEXITCODE
        $output = ($nativeOutput | Out-String).TrimEnd()
    }
    catch {
        $output = $_.Exception.Message
        $exitCode = if ($LASTEXITCODE -gt 0) { $LASTEXITCODE } else { 1 }
        $executorFailure = $true
    }
    finally {
        $governedPythonStarted = Test-Path -LiteralPath $startedMarker -PathType Leaf
        if ($governedPythonStarted) {
            Remove-Item -LiteralPath $startedMarker -Force -ErrorAction SilentlyContinue
        }
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($executorFailure -and -not [string]::IsNullOrWhiteSpace($output)) {
        Write-Host $output
    }

    $executorFailure = -not $governedPythonStarted

    if ($exitCode -eq 0 -and -not $executorFailure) {
        return [pscustomobject]@{
            name = $CheckDefinition.name
            resolved_executor = $Executor.program
            exact_argument_array = @($arguments)
            expected_evidence = $expectedEvidence
            status = 'passed'
            failure_type = ''
            executor_failure = $false
            governed_python_started = $governedPythonStarted
            exit_code = 0
        }
    }

    return [pscustomobject]@{
        name = $CheckDefinition.name
        resolved_executor = $Executor.program
        exact_argument_array = @($arguments)
        expected_evidence = $expectedEvidence
        status = 'failed'
        failure_type = $(if ($executorFailure) { 'environment' } else { 'workload' })
        executor_failure = $executorFailure
        governed_python_started = $governedPythonStarted
        exit_code = $exitCode
    }
}

if ($PSBoundParameters.ContainsKey('CondaEnvName')) {
    [Console]::Error.WriteLine(
        '[FAIL] Runtime selection is governed by repo-python / AI_Workbench. -CondaEnvName is no longer supported.'
    )
    exit 2
}

if ($PSBoundParameters.ContainsKey('UsePyLauncher')) {
    [Console]::Error.WriteLine(
        '[FAIL] Runtime selection is governed by repo-python / AI_Workbench. -UsePyLauncher is no longer supported.'
    )
    exit 2
}

$repoRoot = Get-RepoRoot
$launcherPath = Join-Path $repoRoot 'tools\run_governed_python_workload.py'
if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf)) {
    throw "Governed workload launcher not found: $launcherPath"
}
$catalog = Get-CheckCatalog
$selectedChecks = @($catalog[$Checks])

if ($selectedChecks.Count -eq 0) {
    throw "No checks configured for group: $Checks"
}

$tempParent = Join-Path $repoRoot '.tmp'
$ownedTempRoot = Join-Path $tempParent ('r{0}' -f ([guid]::NewGuid().ToString('N').Substring(0, 8)))
New-Item -ItemType Directory -Path $ownedTempRoot -Force | Out-Null

$originalTemp = $env:TEMP
$originalTmp = $env:TMP
$originalTmpDir = $env:TMPDIR
$originalPythonUtf8 = $env:PYTHONUTF8
$originalPythonIoEncoding = $env:PYTHONIOENCODING

$env:TEMP = $ownedTempRoot
$env:TMP = $ownedTempRoot
$env:TMPDIR = $ownedTempRoot
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'

$results = @()
$executor = $null
$executorIssue = ''
$locationPushed = $false
$tempCleanup = 'PASS'

try {
    Push-Location $repoRoot
    $locationPushed = $true

    Write-Section 'Local validation setup'
    Write-Info "Repository root: $repoRoot"
    Write-Info "Check group: $Checks"
    Write-Info "Temp root: $ownedTempRoot"

    try {
        $executor = Get-RepoPythonExecutor -RepositoryRoot $repoRoot
    }
    catch {
        $executorIssue = $_.Exception.Message
    }

    if (-not [string]::IsNullOrWhiteSpace($executorIssue)) {
        Write-Failure $executorIssue
    }
    else {
        Write-Info "Executor: $($executor.display_name)"
    }
    Write-Info ("Selected checks: {0}" -f (($selectedChecks | ForEach-Object { $_.name }) -join ', '))

    if ([string]::IsNullOrWhiteSpace($executorIssue)) {
        Write-Section 'Running checks'
        foreach ($checkDefinition in $selectedChecks) {
            $result = Invoke-Check -Executor $executor -CheckDefinition $checkDefinition -LauncherPath $launcherPath -MarkerRoot $ownedTempRoot
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
    if ($locationPushed) {
        Pop-Location
    }
    $env:TEMP = $originalTemp
    $env:TMP = $originalTmp
    $env:TMPDIR = $originalTmpDir
    $env:PYTHONUTF8 = $originalPythonUtf8
    $env:PYTHONIOENCODING = $originalPythonIoEncoding

    if (Test-Path -LiteralPath $ownedTempRoot) {
        try {
            $resolvedTempParent = (Resolve-Path -LiteralPath $tempParent).ProviderPath.TrimEnd('\')
            $resolvedOwnedTempRoot = (Resolve-Path -LiteralPath $ownedTempRoot).ProviderPath
            if (-not $resolvedOwnedTempRoot.StartsWith(
                "$resolvedTempParent\",
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
                throw "Owned temp root escaped repository temp parent: $resolvedOwnedTempRoot"
            }
            Remove-Item -LiteralPath $resolvedOwnedTempRoot -Recurse -Force -ErrorAction Stop
        }
        catch {
            $tempCleanup = 'WARNING'
            Write-Warning "Could not clean owned temp root '$ownedTempRoot': $($_.Exception.Message)"
        }
    }
}

Write-Section 'Summary'
$passed = @($results | Where-Object { $_.status -eq 'passed' })
$failed = @($results | Where-Object { $_.status -eq 'failed' })

Write-Info "Passed: $($passed.Count)"
Write-Info "Failed: $($failed.Count)"
Write-Info "Temp cleanup: $tempCleanup"

if (-not [string]::IsNullOrWhiteSpace($executorIssue)) {
    Write-Failure "Executor setup: environment"
    exit 2
}

if ($failed.Count -gt 0) {
    foreach ($failure in $failed) {
        Write-Failure ("{0}: {1}" -f $failure.name, $failure.failure_type)
    }
    if (@($failed | Where-Object { $_.executor_failure }).Count -gt 0) {
        exit 2
    }
    exit 1
}

Write-Success 'All selected checks passed.'
