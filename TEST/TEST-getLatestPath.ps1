# 定义日志文件路径模式（专业版和社区版）
$patterns = @(
    "$env:USERPROFILE\AppData\Local\JetBrains\IntelliJIdea*\log\idea.log",
    "$env:USERPROFILE\AppData\Local\JetBrains\IdeaIC*\log\idea.log"
)

# 获取所有符合条件的日志文件路径
$logPaths = $patterns | ForEach-Object {
    Get-ChildItem -Path $_ -ErrorAction SilentlyContinue
} | Where-Object { $_.PSParentPath -match 'IntelliJIdea\d+\.\d+|IdeaIC\d+\.\d+' }

# 如果没有找到日志文件，报错退出
if (-not $logPaths) {
    Write-Host "[ERROR] can't find IntelliJ log, please confirm you have opened the IDE!" -ForegroundColor Red
    exit 1
}

# 从路径中提取版本号并排序
$latestLog = $logPaths | ForEach-Object {
    # 提取目录名中的版本号（例如：2023.2）
    $versionString = [regex]::Match($_.PSParentPath, '(\d+\.\d+)').Groups[1].Value
    # 转换为 Version 对象以便排序
    $version = [version]$versionString
    # 返回自定义对象，包含版本和文件信息
    [PSCustomObject]@{
        Version = $version
        File    = $_
    }
} | Sort-Object Version -Descending | Select-Object -First 1

# 输出最新日志路径
Write-Host "Had find the latest IDEA log:" -ForegroundColor Green $latestLog.File.FullName