$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir "Common.ps1")

$excludeProfileNames = @()
$excludeProxyServer = @("183.232.248.73:7890", "210.16.160.222:7890")
$profileNames = @(Get-ChildItem -Path $WEB_BROWSER_DATA_DIR -Directory | Where-Object { $_.Name -like "Profile*" } | ForEach-Object { $_.Name })

# profile上下文字典
$profileInfos = @()
for ($i = 0; $i -lt $profileNames.Count; $i++) {
    $profileName = $profileNames[$i]
    $proxyServer = $PROXY_SERVERS[$i % $PROXY_SERVERS.Count]
    if ($excludeProfileNames -contains $profileName) {
        continue
    }
    if ($excludeProxyServer -contains $proxyServer) {
        continue
    }
    $profileInfos += [PSCustomObject]@{
        Number      = $i
        ProfileName = $profileNames[$i]
        ProxyServer = $proxyServer
        CurDuation  = 0
        MaxDuation  = (30 + (0..10 | Get-Random)) * $INTERVAL
    }
}

while ($profileInfos) {
    $profileInfo = $profileInfos | Get-Random
    $randomDuration = (1..3 | Get-Random) * $INTERVAL
    $restDuration = $profileInfo.MaxDuation - $profileInfo.CurDuation
    $duration = [Math]::Min($randomDuration, $restDuration)

    if ($duration -gt 0) {
        Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - No.$($profileInfo.Number)($($profileInfo.ProfileName)): start, proxy by $($profileInfo.ProxyServer)"
        & $WEB_BROWSER_EXE_PATH `
            --profile-directory=$($profileInfo.ProfileName) `
            --proxy-server=$($profileInfo.ProxyServer) `
            $BING_URL `
            > /dev/null 2>&1 &
        Start-Sleep -Seconds $duration
        $profileInfo.CurDuation += $duration
        pkill -f $WEB_BROWSER
    }
    else {
        Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - No.$($profileInfo.Number)($($profileInfo.ProfileName)): done"
        $profileInfos = $profileInfos | Where-Object { $_ -ne $profileInfo }
    }
}
Write-Host "所有任务已完成!!"
