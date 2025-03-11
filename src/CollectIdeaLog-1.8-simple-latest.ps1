# PowerShell脚本收集用户idea.log - 本脚本已实现提取idea.log及用户相关信息写入到目标文件夹
# 路径：C:\Users\yuanbao\AppData\Local\JetBrains\IntelliJIdea2023.1\log\idea.log
#$logPath = Join-Path $env:USERPROFILE "AppData\Local\JetBrains\IntelliJIdea*\log\idea.log"  # IDEA默认日志路径
# 测试路径：
#$logPath = "C:\Users\yuanbao\AppData\Local\JetBrains\IntelliJIdea2023.1\log\idea-20250221.log"  # IDEA默认日志路径


# 查找最新版本的IntelliJIdea日志文件
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
#Write-Host "Had find the latest IDEA log:" -ForegroundColor Green $latestLog.File.FullName

# 优化展示信息 -合并弹窗确认
# 在脚本开头添加程序集引用（必须）
Add-Type -AssemblyName System.Windows.Forms
# 初始化结果变量
$global:resultMessage = @()
# 替换所有 Write-Host 为自定义函数
function Add-ResultMessage {
    param([string]$msg)
    $global:resultMessage += $msg
}
# 定义一个全局标记用于跟踪用户是否取消
$global:UserCancelled = $false
# 创建带取消按钮的弹窗函数
function Show-ConfirmationDialog {
    param(
        [string]$Message,
        [string]$Title = "Confirm"
    )
    $result = [System.Windows.Forms.MessageBox]::Show(
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OKCancel,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) {
        $global:UserCancelled = $true
        return $false
    }
    return $true
}


$logPath = $latestLog.File.FullName # 版本年月最新的作为路径
#Write-Host "Log path: " $logPath
Add-ResultMessage "IDEA is checked OK!`n`n"

# 创建临时副本以避免文件锁定问题
$tempLogFile = [System.IO.Path]::GetTempFileName()
Copy-Item -Path $logPath -Destination $tempLogFile



# 修复2：获取IPv4地址时兼容多语言系统（如中文/英文） -但获取到了多个，不确定如何筛选为准确那个，将多个拼接
$ipv4Addresses = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.IPAddress -ne '127.0.0.1'
} | Select-Object -ExpandProperty IPAddress

# 处理多个IPv4地址的情况，用逗号分隔
$ipv4 = $ipv4Addresses -join ", "

# ADD: 用户交互输入姓名
do {
    $userName = Read-Host "please input your whole chinese name (2-10 characters)"
	if ($userName.Length -eq 0) {
        Write-Host "[WARN] User cancelled." -ForegroundColor Yellow
        exit 0
    }
} while ($userName.Length -lt 2 -or $userName.Length -gt 10)
# 处理特殊字符（替换非法字符为X）
$userInputName = $userName

$dateStr = Get-Date -Format "yyyy-MM-dd"

$metaData = @{
    UserName = $env:USERNAME  # 直接获取当前用户名
    HostName = $env:COMPUTERNAME  # 直接获取主机名
    IPv4 = $ipv4  # 处理后的IPv4地址
	InputName = $userInputName
	CollectDate = $dateStr
	LogPath = $logPath
}

# 创建带元数据的日志文件 -远端地址还是本地，二选一
#$serverPath = "\\10.1.8.137\workshare\"  # 公司服务器共享目录，由于只能是内网，且需要提前配置网络地址，比较麻烦
#$targetDir = New-Item -Path "$serverPath\$dateStr" -ItemType Directory -Force
#$targetFile = Join-Path $targetDir.FullName "$($metaData.HostName)_$($metaData.UserName)_$userInputName.log"

# 后停掉上传到远端，先保存到本地
$localBackupPath = "$env:USERPROFILE\AppData\Local\JetBrains\IDEA Logs-backup\$dateStr"  # 本地备份路径，请根据实际情况调整
New-Item -Path $localBackupPath -ItemType Directory -Force | Out-Null  # 确保目录存在
$targetFile = Join-Path $localBackupPath "$($metaData.HostName)_$($metaData.UserName)_$userInputName.log"


# 构建要写入的内容
$content = "==== META-BEGIN ====`n"
foreach ($key in $metaData.Keys) {
	$content += "${key}: $($metaData[$key])`n"  # 重点：修正插值语法
}
$content += "==== META-END ====`n`n"
#Write-Host $content
Add-ResultMessage $content


# 修复4：改作从临时文件中读取内容，避免文件占用。临时文件读完后删除临时文件。
if (Test-Path $tempLogFile) {
    $content += [System.IO.File]::ReadAllText($tempLogFile)
    Remove-Item -Path $tempLogFile # 删除临时文件
} else {
    #Write-Host "Temporary log file not found at $tempLogFile"
}

# 修复5：一次性写入所有内容-优化写入效率
[System.IO.File]::WriteAllText($targetFile, $content)
#Write-Host "Log file collected and uploaded successfully." "fileName:$($metaData.HostName)_$($metaData.UserName)_$userInputName.log"

# 将日志文件上传到FTP服务器，可以支持公网
# FTP上传设置：
# 	自己-原始测试地址：ftp://10.1.8.137/		TEST/123456
$ftpServer = "ftp://xxxx"  # FTP服务器地址
$ftpUser = "xxxx"  # FTP用户名
$ftpPassword = "pwd@2025"  # FTP密码


# 创建FTP日期目录路径
$ftpDateFolder = "$ftpServer$dateStr/"

# 函数：创建FTP目录（若不存在）
function Create-FtpDirectory {
    param(
        [string]$ftpPath,
        [string]$username,
        [string]$password
    )
    try {
        $request = [System.Net.FtpWebRequest]::Create($ftpPath)
        $request.Credentials = New-Object System.Net.NetworkCredential($username, $password)
        $request.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
        $response = $request.GetResponse()
        #Write-Host "Date FtpDirectory created successfully: $ftpPath"
		Add-ResultMessage "Date FtpDirectory created successfully: $ftpPath"
    } catch [Net.WebException] {
        # 550错误通常表示目录已存在，忽略；其他错误抛出
        if ($_.Exception.Response.StatusCode -eq [System.Net.FtpStatusCode]::ActionNotTakenFileUnavailable) {
            #Write-Host "Date FtpDirectory already exists: $ftpPath"
			Add-ResultMessage "Date FtpDirectory already exists: $ftpPath"
        } else {
			Write-Host "Failed to create FTP directory: $_" -ForegroundColor Red
			exit 1
        }
    } finally {
		if ($response) { $response.Close() }
	}
}

# 创建日期目录
Create-FtpDirectory -ftpPath $ftpDateFolder -username $ftpUser -password $ftpPassword


# 统一弹窗提示信息作确认：
$confirmResult = Show-ConfirmationDialog -Message $global:resultMessage -join "`n"
if (-not $confirmResult) {
    Write-Host "User Cancelled!" -ForegroundColor Yellow
    exit 0
}



# 打开FTP连接并上传文件
$ftpUri = "$ftpDateFolder$(Split-Path -Path $targetFile -Leaf)"
#Write-Host "ftpUri is:" $ftpUri
# 初始化FTP请求
$ftpRequest = [System.Net.FtpWebRequest]::Create($ftpUri)
$ftpRequest.Credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPassword)
$ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile

try {
    $fileStream = [System.IO.File]::OpenRead($targetFile)
	# 一般的FTP文件上传		-暂时停用，废弃
	#$webClient = New-Object System.Net.WebClient
	#$webClient.Credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPassword)
    #$webClient.UploadFile($ftpUri, $targetFile)
	
	# ADD增加上传进度条显示
	# 分块传输参数
	$chunkSize = 4kb  # 可调节分块大小，会影响进度条精度
	$totalBytes = $fileStream.Length
	$bytesUploaded = 0
	# 获取请求流并开始上传
	$requestStream = $ftpRequest.GetRequestStream()
	$buffer = New-Object byte[] $chunkSize
    while (($readBytes = $fileStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $requestStream.Write($buffer, 0, $readBytes)
        $bytesUploaded += $readBytes
        
        # 计算并更新进度条
        $progress = [Math]::Round(($bytesUploaded / $totalBytes) * 100, 2)
        Write-Progress -Activity "Uploading" -Status "$progress% Complete:" `
            -PercentComplete $progress -CurrentOperation "$bytesUploaded/$totalBytes byte"
    }
	
	
    Write-Host "Log file collected and uploaded successfully via FTP. fileName: $(Split-Path -Path $targetFile -Leaf)"
} catch {
    Write-Host "Failed to upload log file via FTP. Error: $_" -ForegroundColor Red
} finally {
    if ($fileStream) { $fileStream.Close() }
	if ($requestStream) { $requestStream.Close() }
}


# 清理生成的本地文件（可选）
Remove-Item -Path $targetFile