# YB-本脚本实现交互输入

# 用户交互获取用户名（带校验）
do {
    $userName = Read-Host "please input your whole chinese name (2-10 characters)"
} while ($userName.Length -lt 2 -or $userName.Length -gt 10)


Write-Host "input name is: " $userName