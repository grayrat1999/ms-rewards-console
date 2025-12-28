# ===============================
# macOS 下 HTTP 代理可访问性检测（百度）
# ===============================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir "Common.ps1")

$Results = @()

foreach ($proxy in $PROXY_SERVERS) {
    Write-Host "检测代理: $proxy" -ForegroundColor Cyan

    try {
        # 使用 macOS 自带 curl 检测
        $cmd = "curl -s -o /dev/null -w '%{http_code}' -x http://$proxy --connect-timeout 5 $PROXY_SERVER_TEST_URL"
        $statusCode = & bash -c $cmd

        if ($statusCode -eq "200") {
            $Results += [PSCustomObject]@{
                Proxy   = $proxy
                Status  = "OK"
                Message = ""
            }
            Write-Host "  ✔ 访问通畅" -ForegroundColor Green
        } else {
            $Results += [PSCustomObject]@{
                Proxy   = $proxy
                Status  = "FAIL"
                Message = "HTTP 状态码 $statusCode"
            }
            Write-Host "  ✘ HTTP 状态码 $statusCode" -ForegroundColor Red
        }
    }
    catch {
        $Results += [PSCustomObject]@{
            Proxy   = $proxy
            Status  = "FAIL"
            Message = $_.Exception.Message
        }
        Write-Host "  ✘ 失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 输出汇总
Write-Host "`n检测结果汇总：" -ForegroundColor Yellow
$Results | Format-Table -AutoSize