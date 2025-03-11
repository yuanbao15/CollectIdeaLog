# YB-本脚本实现调用钉钉群机器人的方式，能实现发送文本消息，但存在中文乱码未解决，且不支持发送文件。
# 加载必要的.NET类库
Add-Type -AssemblyName System.Web

# 定义Webhook URL和Secret
$webhook = "https://oapi.dingtalk.com/robot/send?access_token=eb33906ed90b029a3e086c2a7516c9a412fbdb8b8e1165bf36d228ee488ec6b0"
$secret = "SEC269a654ab6d5f7f21437a55b05fce889913b990c1bb0bef0da492e5e59a495d0"

# 生成签名
$timestamp = [Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime() -uformat "%s")) * 1000 # 获取当前时间戳（毫秒）
$stringToSign = "$timestamp`n$secret"
$hmacsha256 = New-Object System.Security.Cryptography.HMACSHA256
$hmacsha256.key = [Text.Encoding]::UTF8.GetBytes($secret)
$hash = $hmacsha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($stringToSign))
$signature = [System.Web.HttpUtility]::UrlEncode([Convert]::ToBase64String($hash))

# 更新Webhook URL以包含签名和时间戳
$webhookWithSignature = "$webhook&timestamp=$timestamp&sign=$signature"

# 定义要发送的消息内容
$message = @{
    msgtype = "text"
    text = @{
        content = "TEST-LOG IS COLLECTED 张三"
    }
}

# 将消息内容转换为压缩的JSON格式，并确保使用UTF-8编码
$json = $message | ConvertTo-Json -Depth 4 -Compress

# 发送消息
try {
    # 直接发送JSON字符串 - 请求和结果中都发生了中文乱码 未搞定
    $response = Invoke-RestMethod -Uri $webhookWithSignature -Method Post -Body $json -ContentType 'application/json; charset=utf-8'
    
    # 使用Out-File保存响应信息，确保使用UTF-8编码
    $response | Out-File -FilePath "a.txt" -Encoding utf8
    Write-Host "Send succeeded: " $response

} catch {
    Write-Host "Send failed with error: $_" -ForegroundColor Red
}