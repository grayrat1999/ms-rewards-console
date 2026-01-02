# ===============================
# macOS 下 HTTP 代理可访问性检测
# ===============================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir "Common.ps1")

function CheckProxyServer {
    param(
        [string]$ProxyServerUrl
    )
    Write-Host "检测代理: $proxy" -ForegroundColor Cyan
    try {
        # 使用 macOS 自带 curl 检测
        $cmd = "curl -s -o /dev/null -w '%{http_code}' -x http://$ProxyServerUrl --connect-timeout 5 $PROXY_SERVER_TEST_URL"
        $statusCode = & bash -c $cmd

        if ($statusCode -eq "200") {
            Write-Host "  ✔ 访问通畅" -ForegroundColor Green
            return [PSCustomObject]@{
                Proxy   = $proxy
                Status  = "OK"
                Message = ""
            }
        }
        else {
            Write-Host "  ✘ HTTP 状态码 $statusCode" -ForegroundColor Red
            return [PSCustomObject]@{
                Proxy   = $proxy
                Status  = "FAIL"
                Message = "HTTP 状态码 $statusCode"
            }
        }
    }
    catch {
        return [PSCustomObject]@{
            Proxy   = $proxy
            Status  = "FAIL"
            Message = $_.Exception.Message
        }
        Write-Host "  ✘ 失败: $($_.Exception.Message)" -ForegroundColor Red
    }

}


if ($MyInvocation.InvocationName -eq ".") {
    # 被 dot-source 或 Import-Module 时不执行
}
elseif ($PSCommandPath -eq $MyInvocation.MyCommand.Path) {
    $Results = @()
    foreach ($proxy in $PROXY_SERVERS) {
        $Results += CheckProxyServer -ProxyServerUrl $proxy
    }
    Write-Host "`n检测结果汇总: " -ForegroundColor Yellow
    $Results | Format-Table -AutoSize
}