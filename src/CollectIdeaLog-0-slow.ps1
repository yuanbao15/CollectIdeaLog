# PowerShell脚本收集用户idea.log
# 路径：C:\Users\yuanbao\AppData\Local\JetBrains\IntelliJIdea2023.1\log\idea.log
#$logPath = Join-Path $env:USERPROFILE "AppData\Local\JetBrains\IntelliJIdea*\log\idea.log"  # IDEA默认日志路径
$logPath = "C:\Users\yuanbao\AppData\Local\JetBrains\IntelliJIdea2023.1\log\idea-20250221.log"
$serverPath = "\\10.1.8.137\workshare\"  # 公司服务器共享目录
$dateStr = Get-Date -Format "yyyy-MM-dd"
$metaData = @{
    UserName = $env:USERNAME
    HostName = $env:COMPUTERNAME
    IPv4 = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
        $_.InterfaceAlias -match '以太网|Wi-Fi' -and $_.IPAddress -ne '127.0.0.1'
    }).IPAddress
}

# 创建带元数据的日志文件
$targetDir = New-Item -Path "$serverPath\$dateStr" -ItemType Directory -Force
$targetFile = Join-Path $targetDir.FullName "$($metaData.HostName)_$($metaData.UserName).log"

"==== META-BEGIN ====" | Out-File $targetFile -Encoding UTF8
$metaData.GetEnumerator() | ForEach-Object {
    "$($_.Key):$($_.Value)" | Out-File $targetFile -Append -Encoding UTF8
}
"==== META-END ====`n" | Out-File $targetFile -Append -Encoding UTF8
Get-Content $logPath | Out-File $targetFile -Append -Encoding UTF8

