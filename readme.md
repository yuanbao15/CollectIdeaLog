### 简介：本工具用于收集IDEA日志用于分析通义灵码插件的使用信息。

created by yuanbao at 20250228



### 要求：

1. 本工具支持IDEA专业版和社区版，会自动优先适用版本年月最高的那个IDEA，若年月相同则优先适用专业版，其次社区版。
2. 使用本工具前，应确保在IDEA内，Help->Diagnostic Tools->Debug Log Settings，有输入：#com.alibaba.lingma.plugin。配置好后重启IDEA才可生效。
3. 触发本工具前，要求停用HTTP网络代理，关闭VPN。
4. 本工具运行时，需输入本人的真实中文姓名。
5. 看到进度条100%，才表示上传成功。





### 实现功能：

1. 提取执行机器上的IDEA日志，自动匹配路径；
2. 机器名、用户名、IP等信息写入日志文件，并命名日志文件；
3. 上传到远程文件地址，后改作长传FTP实现；
4. 新增用户交互操作输入用户正式姓名，放入日志文件名；
5. ~~尝试钉钉消息推送，实现了机器人推送文本信息，但中文乱码且无法推送文件，放弃。~~
6. ps1脚本转化为exe可执行程序；
7. 适配在IDEA专业版、社区版多版本时，按年月取最新版、专业版优先；
8. 上传全部日志文件，包含历史的（支持idea.log、idea.1.log及idea.log.1），并显示整体进度条；





### 软件操作截图：

![image-20250227102124941](https://yuanbao-oss.oss-cn-shenzhen.aliyuncs.com/img/public_imgs/PicGo/202502271021028.png)

<img src="https://yuanbao-oss.oss-cn-shenzhen.aliyuncs.com/img/public_imgs/PicGo/202503111120246.png" alt="image-20250311112016351" style="zoom: 80%;" />

![image-20250227102044691](https://yuanbao-oss.oss-cn-shenzhen.aliyuncs.com/img/public_imgs/PicGo/202502271020989.png)

![lQLPJwVg0rKT5-fM2s0EqrDRL9AeJtU8TQeoHqw1Wg8B_1194_218.png](https://yuanbao-oss.oss-cn-shenzhen.aliyuncs.com/img/public_imgs/PicGo/202503111102206.png)

![lQLPKG-wAJFqt-fM-80CirA-_9CRZXhD3geoHqw1Wg8A_650_251.png](https://yuanbao-oss.oss-cn-shenzhen.aliyuncs.com/img/public_imgs/PicGo/202503111102067.png)







### 其他：

多版本情况：(自动取年月最新的)

![image-20250311110623347](https://yuanbao-oss.oss-cn-shenzhen.aliyuncs.com/img/public_imgs/PicGo/202503111106106.png)

日志文件列表：

![image-20250311111506102](https://yuanbao-oss.oss-cn-shenzhen.aliyuncs.com/img/public_imgs/PicGo/202503111115481.png)

![image-20250311111440383](https://yuanbao-oss.oss-cn-shenzhen.aliyuncs.com/img/public_imgs/PicGo/202503111114516.png)



采集后文件名列表：

<img src="https://yuanbao-oss.oss-cn-shenzhen.aliyuncs.com/img/public_imgs/PicGo/202503111124177.png" alt="image-20250311112450869" style="zoom:80%;" />

内容：

![image-20250311112343433](https://yuanbao-oss.oss-cn-shenzhen.aliyuncs.com/img/public_imgs/PicGo/202503111123259.png)