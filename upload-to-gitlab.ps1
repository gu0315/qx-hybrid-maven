# 在【公司电脑 Windows】(内网、能访问 GitLab)运行,把自己电脑构建好、拷过来的产物
# 上传到 GitLab Package Registry。无需 Android SDK / gradle。
#
# 首次使用前(在 PowerShell 里设置认证):
#   $env:GITLAB_TOKEN='<deploy-token 或 personal access token>'
#   # 若用 Personal Access Token,改用 Private-Token 头:
#   #   $env:GITLAB_TOKEN_HEADER='Private-Token'
#   $env:GITLAB_PROJECT_ID='<android-sdk-maven 项目的 ID>'   # 见该项目 Settings→General
#
# 运行(在本目录下,PowerShell):
#   powershell -ExecutionPolicy Bypass -File .\upload-to-gitlab.ps1 -Version 0.1.8

param(
    [Parameter(Mandatory=$true)][string]$Version,
    [string]$RepoRoot = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$GitlabBase  = 'https://paas-gitlab.mychery.com'
$ProjectId   = if ($env:GITLAB_PROJECT_ID) { $env:GITLAB_PROJECT_ID } else { '11998' }  # android-sdk-maven
$GroupPath   = 'com/energy/sdk/qx-hybrid'
$TokenHeader = if ($env:GITLAB_TOKEN_HEADER) { $env:GITLAB_TOKEN_HEADER } else { 'Deploy-Token' }
$Token       = $env:GITLAB_TOKEN
if (-not $Token) { throw '请先设置认证: $env:GITLAB_TOKEN=<deploy-token 或 PAT>' }

$BaseApi = "$GitlabBase/api/v4/projects/$ProjectId/packages/maven"
$VDir    = Join-Path $RepoRoot "$GroupPath\$Version"

function Put-File($LocalFile, $RemotePath) {
    if (-not (Test-Path $LocalFile)) { Write-Host "  跳过(不存在): $LocalFile"; return }
    $url = "$BaseApi/$RemotePath"
    Write-Host "PUT $RemotePath ..." -NoNewline
    Invoke-WebRequest -Method Put -Uri $url -InFile $LocalFile `
        -Headers @{ $TokenHeader = $Token } -ContentType 'application/octet-stream' `
        -UseBasicParsing | Out-Null
    Write-Host " OK"
}

Write-Host "==> 上传 qx-hybrid $Version 到 GitLab 项目 #$ProjectId"
Put-File "$VDir\qx-hybrid-$Version.aar"            "$GroupPath/$Version/qx-hybrid-$Version.aar"
Put-File "$VDir\qx-hybrid-$Version.pom"            "$GroupPath/$Version/qx-hybrid-$Version.pom"
Put-File "$VDir\qx-hybrid-$Version-sources.jar"    "$GroupPath/$Version/qx-hybrid-$Version-sources.jar"
Put-File "$VDir\qx-hybrid-$Version.module"         "$GroupPath/$Version/qx-hybrid-$Version.module"
Put-File (Join-Path $RepoRoot "$GroupPath\maven-metadata.xml") "$GroupPath/maven-metadata.xml"

Write-Host ""
Write-Host "OK 上传完成: com.energy.sdk:qx-hybrid:$Version"
Write-Host "   到 GitLab 项目 Deploy -> Package Registry 可看到该包"
