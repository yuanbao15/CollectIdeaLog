# 在脚本最开头添加程序集引用（必须）
Add-Type -AssemblyName System.Windows.Forms

# 将弹窗相关函数定义提前到脚本开头-普通弹窗
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

# 将弹窗相关函数定义提前到脚本开头-带确认路径按钮
function Show-PathConfirmationDialog {
    param(
        [string]$Message,
        [string]$Title = "Confirm"
    )
    # 创建自定义表单
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(500, 250)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true

    # 创建标签
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Message
    $label.AutoSize = $false
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(460, 100)
    $label.TextAlign = 'TopLeft'
    $form.Controls.Add($label)

    # 创建确认路径按钮
    $confirmButton = New-Object System.Windows.Forms.Button
    $confirmButton.Text = "CONFIRM PATH"
    $confirmButton.Location = New-Object System.Drawing.Point(100, 150)
    $confirmButton.Size = New-Object System.Drawing.Size(120, 30)
    $confirmButton.Add_Click({ $form.Tag = $true; $form.Close() })
    $form.Controls.Add($confirmButton)

    # 创建修改路径按钮
    $changeButton = New-Object System.Windows.Forms.Button
    $changeButton.Text = "CHANGE PATH"
    $changeButton.Location = New-Object System.Drawing.Point(250, 150)
    $changeButton.Size = New-Object System.Drawing.Size(120, 30)
    $changeButton.Add_Click({ $form.Tag = $false; $form.Close() })
    $form.Controls.Add($changeButton)

    # 显示表单
    $form.ShowDialog() | Out-Null
    return $form.Tag
}

# PowerShell脚本收集用户idea.log - 本脚本已实现提取idea.log及用户相关信息写入到目标文件夹
# 路径：C:\Users\yuanbao\AppData\Local\JetBrains\IntelliJIdea2023.1\log\idea.log
#$logPath = Join-Path $env:USERPROFILE "AppData\Local\JetBrains\IntelliJIdea*\log\idea.log"  # IDEA默认日志路径
# 测试路径：
#$logPath = "C:\Users\yuanbao\AppData\Local\JetBrains\IntelliJIdea2023.1\log\idea-20250221.log"  # IDEA默认日志路径


# 查找最新版本的IntelliJIdea日志文件
# 定义日志文件路径模式（专业版和社区版）
$patterns = @(
    "$env:USERPROFILE\AppData\Local\JetBrains\IntelliJIdea*\log",
    "$env:USERPROFILE\AppData\Local\JetBrains\IdeaIC*\log"
)

# 获取所有符合条件的日志目录
$logDirs = $patterns | ForEach-Object {
    Get-ChildItem -Path $_ -ErrorAction SilentlyContinue
} | Where-Object { $_.FullName -match 'IntelliJIdea\d+\.\d+|IdeaIC\d+\.\d+' }

# 如果没有找到日志目录，提示用户选择路径
if (-not $logDirs) {
    # 提示未自动匹配日志路径，需手动选择路径 
    Write-Host "can't find IntelliJ log directory automatically, please select a directory manually."
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $result = $dialog.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $latestLogDir = @([PSCustomObject]@{ Path = $dialog.SelectedPath })
    } else {
        Write-Host "[ERROR] User cancelled directory selection." -ForegroundColor Red
        exit 1
    }
} else {
    # 从路径中提取版本号并排序，取版本号最新的，如果相同年月则专业版优先，无专业版再看社区版
    $latestLogDir = $logDirs | ForEach-Object {
        # 提取目录名中的版本号（例如：2023.2）
        $versionString = [regex]::Match($_.FullName, '(\d+\.\d+)').Groups[1].Value  # 增强正则表达式
        
        # 转换为 Version 对象以便排序
        $version = [version]$versionString

        # 返回自定义对象，包含版本和文件信息
        [PSCustomObject]@{
            Version = $version
            Path    = $_.FullName
            IsProfessional = $_.FullName -match 'IntelliJIdea'
        }
    } | Where-Object { $_ -ne $null } |  # 过滤无效版本号
    Sort-Object @{Expression = { $_.IsProfessional }; Descending = $true }, Version -Descending |
    Select-Object -First 1

    # 提示用户确认使用找到的最新路径
    $latestLogDirPath = $latestLogDir.Path
    $confirmUseDefault = Show-PathConfirmationDialog -Message "Found log directory: `n$latestLogDirPath `n`nDo you want to use this path?" -Title "Confirm Log Directory"
    # 如果用户关闭了弹窗，则退出
    if ($null -eq $confirmUseDefault) {
        Write-Host "[ERROR] User closed the dialog." -ForegroundColor Red
        exit 1
    }
    # 如果用户选择了路径，进行处理提取
    if (-not $confirmUseDefault) {
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $result = $dialog.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $latestLogDir = @([PSCustomObject]@{ Path = $dialog.SelectedPath })
        } else {
            Write-Host "[ERROR] User cancelled directory selection." -ForegroundColor Red
            exit 1
        }
    }
}

# Write-Host "latestLogDir:" $latestLogDir

# 获取该目录下所有 idea*.log 文件（包括 idea*.log 和 idea.log.*，解决部分人员机器IDEA log 数字在最后面问题）
$logFiles = Get-ChildItem -Path "$($latestLogDir.Path)\idea*.log", "$($latestLogDir.Path)\idea.log.*" -File

# 如果没有日志文件，报错退出
if (-not $logFiles) {
    Write-Host "[ERROR] can't find IntelliJ log file in the path [$($latestLogDir.Path)], please confirm you have opened the IDE or the path is correct!" -ForegroundColor Red
    exit 1
}


# 优化展示信息 -合并弹窗确认
# 初始化结果变量
$global:resultMessage = @()
# 替换所有 Write-Host 为自定义函数
function Add-ResultMessage {
    param([string]$msg)
    $global:resultMessage += $msg
}
# 定义一个全局标记用于跟踪用户是否取消
$global:UserCancelled = $false


$logDir = $latestLogDir.Path # 版本年月最新的作为路径
#Write-Host "Log path: " $logDir
Add-ResultMessage "IDEA is checked OK!`n`n"


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
	LogDir = $latestLogDir.Path
}

# 弹框确认的信息
$contentTotal = "==== META-BEGIN ====`n"
foreach ($key in $metaData.Keys) {
	$contentTotal += "${key}: $($metaData[$key])`n"  # 重点：修正插值语法
}
$contentTotal += "==== META-END ====`n`n"
#Write-Host $contentTotal
Add-ResultMessage $contentTotal

# 新增：计算所有文件总大小（用于统一进度条）
$totalBytes = ($logFiles | Measure-Object -Property Length -Sum).Sum
$global:bytesUploaded = 0  # 全局变量记录已上传字节数


# 将日志文件上传到FTP服务器，可以支持公网
# FTP上传设置：
# 	自己-原始测试地址：ftp://10.1.8.137/		TEST/123456
# 	自己-云服务器公网：ftp://8.138.94.245/		ftpuser/pwd@2025
# 	换公司地址-内网：ftp://10.1.1.49/		ftpuser/pwd@2025
#	换公司地址-公网：ftp://61.183.71.118:9021/		ftpuser/pwd@2025		其他均默认为21端口，这个公网作了映射到9021
$ftpServer = "ftp://61.183.71.118:9021/"  # FTP服务器地址
$ftpUser = "ftpuser"  # FTP用户名
$ftpPassword = "pwd@2025"  # FTP密码

# 创建FTP日期目录路径
$ftpDateFolder = "$ftpServer$dateStr/"

# 函数：创建FTP目录（若不存在）
function Create-FtpDirectory {
	param([string]$ftpPath)
	try {
		$request = [System.Net.FtpWebRequest]::Create($ftpPath)
		$request.Credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPassword)
		$request.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
		$response = $request.GetResponse()
		#Write-Host "Date FtpDirectory created successfully: $ftpPath"
		Add-ResultMessage "Date FtpDirectory created successfully: $ftpPath"
	} catch [Net.WebException] {
		# 550错误通常表示目录已存在，忽略；其他错误抛出
        if ($_.Exception.Response.StatusCode -eq [System.Net.FtpStatusCode]::ActionNotTakenFileUnavailable) {
            #Write-Host "Date FtpDirectory already exists: $ftpPath"
			Add-ResultMessage "Date FtpDirectory exists: $ftpPath"
        } else {
			Write-Host "Failed to create FTP directory: $_" -ForegroundColor Red
			exit 1
        }
    } finally {
		if ($response) { $response.Close() }
	}
}
# 创建日期目录
Create-FtpDirectory -ftpPath $ftpDateFolder

# 初始化统一进度条（提前显示）
Write-Progress -Activity "Uploading" -Status "ready..." -PercentComplete 0

# 统一弹窗提示信息作确认：
$confirmResult = Show-ConfirmationDialog -Message $global:resultMessage -join "`n"
if (-not $confirmResult) {
    Write-Host "User Cancelled!" -ForegroundColor Yellow
    exit 0
}

# 遍历所有日志文件并处理
foreach ($logFile in $logFiles) {
    # 创建临时副本
    $tempLogFile = [System.IO.Path]::GetTempFileName()
    Copy-Item -Path $logFile.FullName -Destination $tempLogFile

    # 构建元数据内容
    $content = "==== META-BEGIN ====`n"
    foreach ($key in $metaData.Keys) {
        $content += "${key}: $($metaData[$key])`n"
    }
    $content += "LogPath: $($logFile.FullName)`n"
    $content += "==== META-END ====`n`n"

	# 修复4：改作从临时文件中读取内容，避免文件占用。临时文件读完后删除临时文件。
	if (Test-Path $tempLogFile) {
		$content += [System.IO.File]::ReadAllText($tempLogFile)
		Remove-Item -Path $tempLogFile # 删除临时文件
	} else {
		#Write-Host "Temporary log file not found at $tempLogFile"
	}

    # 保存到本地备份
    $localBackupPath = "$env:USERPROFILE\AppData\Local\JetBrains\IDEA Logs-backup\$dateStr"
    New-Item -Path $localBackupPath -ItemType Directory -Force | Out-Null
    $targetFile = Join-Path $localBackupPath "$($metaData.HostName)_$($metaData.UserName)_$userName`_$($logFile.Name)"
    [System.IO.File]::WriteAllText($targetFile, $content)
	#Write-Host "Log file collected and uploaded successfully." "fileName:$($metaData.HostName)_$($metaData.UserName)_$userInputName.log"


    # 打开FTP连接并上传文件
    $ftpUri = "$ftpDateFolder$(Split-Path -Path $targetFile -Leaf)"
	#Write-Host "ftpUri is:" $ftpUri
	try {
		# 初始化FTP请求
        $ftpRequest = [System.Net.FtpWebRequest]::Create($ftpUri)
        $ftpRequest.Credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPassword)
        $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile

        $fileStream = [System.IO.File]::OpenRead($targetFile)
        $requestStream = $ftpRequest.GetRequestStream()
        
        # 分块上传参数（兼容统一进度条）
        $bufferSize = 4KB  # 分块大小
        $buffer = New-Object byte[] $bufferSize
        $fileBytesUploaded = 0  # 当前文件已上传字节

        while (($readBytes = $fileStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $requestStream.Write($buffer, 0, $readBytes)
            
            # 更新全局和当前文件进度
            $global:bytesUploaded += $readBytes
            $fileBytesUploaded += $readBytes
            
            # 计算整体进度百分比
            $totalProgress = [Math]::Min(100, [Math]::Round(($global:bytesUploaded / $totalBytes) * 100, 2))
            
            # 更新统一进度条（显示整体进度和当前文件）
            Write-Progress -Activity "Uploading" `
                -Status "Overall progress: $totalProgress% | current file: $($logFile.Name)" `
                -PercentComplete $totalProgress `
                -CurrentOperation "uploaded: $($global:bytesUploaded.ToString('N0')) / $($totalBytes.ToString('N0')) bytes"
        }

        #Write-Host "uploaded successfully: $($logFile.Name)" -ForegroundColor Green
    } catch {
        #Write-Host "failed to upload: $($logFile.Name) - $_" -ForegroundColor Red
    } finally {
        if ($fileStream) { $fileStream.Close() }
        if ($requestStream) { $requestStream.Close() }
		
		# 清理生成的本地文件（可选）
		Remove-Item -Path $targetFile
    }
}
# 上传完成后关闭进度条
Write-Progress -Activity "Uploading" -Completed


# 最终确认弹窗（显示总完成状态）
$confirmResult = [System.Windows.Forms.MessageBox]::Show(
    "All log files have uploaded successfully!(total $($logFiles.Count) files, $([Math]::Round($totalBytes/1MB,2)) MB)",
    "Done",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
)