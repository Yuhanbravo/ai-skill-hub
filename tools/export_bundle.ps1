<#
用途：
- 将当前 skill hub Git 仓库导出为 `.bundle` 文件，便于离线备份或跨机器分发。

适合什么时候用：
- 想把整个仓库打成可导入的 Git bundle
- 想同步一份“最新快照”到网盘或移动存储

最短调用示例：
- `\.\tools\export_bundle.ps1`
- `\.\tools\export_bundle.ps1 -RepoPath 'D:\dev\ai-skill-hub' -OutputDir 'D:\backup\Git_Bundle'`
- `\.\tools\export_bundle.ps1 -CommitMessage 'chore(bundle): export latest ai-skill-hub snapshot'`

注意：
- 导出前会自动检查仓库状态；若存在变更，会要求输入提交日志，然后自动提交并导出。
- 不传 `-RepoPath` 时，默认取当前脚本所在仓库根目录；当前 canonical 本地路径通常为 `D:\dev\ai-skill-hub`。
- 默认 bundle 输出目录为 `D:\BaiduSyncdisk\Python_Lib\Git_Bundle`。
#>
[CmdletBinding()]
param(
    [string]$RepoPath,
    [string]$OutputDir,
    [string]$CommitMessage
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RepoPath)) {
    $scriptDirectory = Split-Path -Path $PSCommandPath -Parent
    $RepoPath = (Resolve-Path -LiteralPath (Join-Path $scriptDirectory '..')).ProviderPath
}

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = 'D:\BaiduSyncdisk\Python_Lib\Git_Bundle'
}

function Write-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host ""
    Write-Host "[STEP] $Message" -ForegroundColor Cyan
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

    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Get-CommitMessage {
    param(
        [string]$ProvidedMessage
    )

    if (-not [string]::IsNullOrWhiteSpace($ProvidedMessage)) {
        return $ProvidedMessage
    }

    Write-Host "" 
    Write-Host '[INPUT] Working tree has changes and export requires a commit message.' -ForegroundColor Magenta
    $enteredMessage = Read-Host 'Enter commit message'
    if ([string]::IsNullOrWhiteSpace($enteredMessage)) {
        throw 'Commit message cannot be empty when exporting a dirty repository.'
    }

    return $enteredMessage.Trim()
}

function Assert-CommitMessageValid {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $validatorPath = Join-Path $RepositoryPath 'skills\skill-governance\scripts\commit_convention_check.py'
    if (-not (Test-Path -LiteralPath $validatorPath -PathType Leaf)) {
        throw "Commit validator not found: $validatorPath"
    }

    $messageFile = Join-Path ([System.IO.Path]::GetTempPath()) (
        '.ash-commit-message-{0}.txt' -f ([guid]::NewGuid().ToString('N'))
    )
    try {
        $utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
        [System.IO.File]::WriteAllText($messageFile, $Message, $utf8WithoutBom)
        & repo-python -BrokerProjectRoot $RepositoryPath -PythonArgs @($validatorPath, $messageFile)
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw 'Commit message does not satisfy docs/governance/COMMIT_CONVENTION.md.'
        }
    }
    finally {
        if (Test-Path -LiteralPath $messageFile -PathType Leaf) {
            Remove-Item -LiteralPath $messageFile -Force -ErrorAction Stop
        }
    }
}

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [switch]$CaptureOutput
    )

    if ($CaptureOutput) {
        $output = & git @Arguments 2>&1
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "git $($Arguments -join ' ') failed with exit code $exitCode.`n$($output -join [Environment]::NewLine)"
        }
        return $output
    }

    & git @Arguments
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "git $($Arguments -join ' ') failed with exit code $exitCode."
    }
}

try {
    Write-Step 'Checking git availability'
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'git was not found in PATH.'
    }

    Write-Step 'Checking repository'
    if (-not (Test-Path -LiteralPath $RepoPath -PathType Container)) {
        throw "Repository path not found: $RepoPath"
    }

    $resolvedRepoPath = (Resolve-Path -LiteralPath $RepoPath).ProviderPath
    $isWorkTree = @(Invoke-Git -Arguments @('-C', $resolvedRepoPath, 'rev-parse', '--is-inside-work-tree') -CaptureOutput)
    if ($isWorkTree.Count -eq 0 -or $isWorkTree[0].Trim() -ne 'true') {
        throw "Target path is not a git repository: $resolvedRepoPath"
    }

    Write-Step 'Checking working tree status'
    $statusLines = @(Invoke-Git -Arguments @('-C', $resolvedRepoPath, 'status', '--porcelain=v1') -CaptureOutput)
    if ($statusLines.Count -gt 0) {
        Write-Info 'Detected uncommitted changes. A commit message is required before export.'
        $resolvedCommitMessage = Get-CommitMessage -ProvidedMessage $CommitMessage
        Assert-CommitMessageValid -RepositoryPath $resolvedRepoPath -Message $resolvedCommitMessage

        Invoke-Git -Arguments @('-C', $resolvedRepoPath, 'add', '-A')
        Invoke-Git -Arguments @('-C', $resolvedRepoPath, 'commit', '-m', $resolvedCommitMessage)

        Write-Success "Auto-commit created: $resolvedCommitMessage"
    }
    else {
        Write-Info 'Working tree is clean. No auto-commit needed.'
    }

    $currentBranch = @(Invoke-Git -Arguments @('-C', $resolvedRepoPath, 'branch', '--show-current') -CaptureOutput)
    $branchName = if ($currentBranch.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($currentBranch[0])) {
        $currentBranch[0].Trim()
    }
    else {
        'main'
    }

    if (-not (Test-Path -LiteralPath $OutputDir -PathType Container)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }

    $resolvedOutputDir = (Resolve-Path -LiteralPath $OutputDir).ProviderPath
    $dateStamp = Get-Date -Format 'yyyy-MM-dd'
    $latestBundlePath = Join-Path $resolvedOutputDir 'ai-skill-hub_latest.bundle'
    $versionedBundlePath = Join-Path $resolvedOutputDir ("ai-skill-hub_{0}_v1.bundle" -f $dateStamp)

    Write-Step 'Creating latest bundle'
    Invoke-Git -Arguments @('-C', $resolvedRepoPath, 'bundle', 'create', $latestBundlePath, '--all')

    Write-Step 'Creating versioned bundle'
    Invoke-Git -Arguments @('-C', $resolvedRepoPath, 'bundle', 'create', $versionedBundlePath, '--all')

    Write-Step 'Verifying bundle'
    Invoke-Git -Arguments @('-C', $resolvedRepoPath, 'bundle', 'verify', $latestBundlePath)
    Invoke-Git -Arguments @('-C', $resolvedRepoPath, 'bundle', 'verify', $versionedBundlePath)

    Write-Info "Current branch: $branchName"
    Write-Info "Latest bundle: $latestBundlePath"
    Write-Info "Versioned bundle: $versionedBundlePath"
    Write-Success 'Bundle export completed'
}
catch {
    Write-Host ""
    Write-Error "[FAILED] $($_.Exception.Message)"
    exit 1
}
