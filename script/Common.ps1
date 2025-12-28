# 代理服务器列表
$PROXY_SERVERS = @(
    "39.185.41.193:5911",
    "183.232.248.73:7890",
    "210.16.160.222:7890",
    "223.159.210.130:7890"
)

# 测试网址
$PROXY_SERVER_TEST_URL = "https://cn.bing.com/"

# 浏览器
$WEB_BROWSER = "Microsoft Edge"

# 浏览器数据目录
$WEB_BROWSER_DATA_DIR = "${Home}/Library/Application Support/$WEB_BROWSER"

# 浏览器可执行文件路径
$WEB_BROWSER_EXE_PATH = "/Applications/${WEB_BROWSER}.app/Contents/MacOS/$WEB_BROWSER"

# BING地址
$BING_URL = "https://cn.bing.com/"

# 单个profile的执行周期
$INTERVAL = 60 * 4