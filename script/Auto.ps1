$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir "Common.ps1")

# 获取所有包含 "Profile" 的文件夹
$profiles = Get-ChildItem -Path $WEB_BROWSER_DATA_DIR -Directory | Where-Object { $_.Name -like "Profile*" } | ForEach-Object { $_.Name }

# 要排除的列表
$exclude_list = @("")

for ($i = 0; $i -lt $profiles.Count; $i++) {
    $item = $profiles[$i]
    $proxy_server = $PROXY_SERVERS[$i % $PROXY_SERVERS.Count]

    if ($exclude_list -contains $item) {
        continue
    }
    Write-Host "No.$i $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - $item - 使用代理[$proxy_server]"
    pkill -f "Microsoft Edge"

    & $WEB_BROWSER_EXE_PATH `
    --profile-directory="$item" `
    --proxy-server="$proxy_server" `
    $BING_URL `
    > /dev/null 2>&1 &

    Start-Sleep -Seconds 10
}

pkill -f "Microsoft Edge"
Write-Host "所有任务已完成!!"