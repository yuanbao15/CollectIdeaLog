# Windows版收集脚本
# 前提：先在资源管理器中配置这个远程地址到本地，验证通过后，才可作上传文件到改地址
$logPath = "$env:USERPROFILE\.IntelliJIdea*\log\idea.log"
$serverPath = "\\10.1.8.137\workshare\"
$dateStr = Get-Date -Format "yyyy-MM-dd"
$metaInfo = "USER:$env:USERNAME`nHOST:$env:COMPUTERNAME`nIP:$(Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -like '*以太网*'}).IPAddress"

New-Item -Path "$serverPath\$dateStr" -ItemType Directory -Force
Add-Content -Path "$serverPath\$dateStr\$env:COMPUTERNAME.log" -Value "===BEGIN META===$metaInfo===END META==="
Get-Content $logPath | Add-Content -Path "$serverPath\$dateStr\$env:COMPUTERNAME.log"