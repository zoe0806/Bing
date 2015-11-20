# -*- coding: utf-8 -*-  
#---------------------------------------  
#   程序：python爬虫  
#   版本：0.4 
#   作者：zoe  
#   日期：2015-10-31  
#   语言：Python 2.7  
#   功能：下载多个页面，并从页面下载图片，保存到当前目录    
#--------------------------------------- 

import string, urllib2,re 

#定义抓取页面函数  
def getHtml(url,values):     
    for i in range(len(values)):  
        sName = string.zfill(values[i],5) + '.txt'#自动填充成六位的文件名  
        print '正在下载第' + str(i) + '个网页，并将其存储为' + sName + '......'  
        f = open(sName,'w+')  
        m = urllib2.urlopen(url + values[i]+ '.html').read()
	contectre = re.search(r'<div class="nrnn4_1">(.*)</div>',m)	
        f.write(contectre.group())  
        f.close()  
        getImg(m,values[i])
		
#定义抓取图片函数
def getImg(html,i):
    imgre = re.compile(r'(?i)src="(\/U.+?\.jpg)')
    imglist = imgre.findall(html)
    my_str =str(i)+ '_'	
    for num in range(len(imglist)):
        urllib2.urlretrieve("http://www.ulux.cn/"+imglist[num],'%s.jpg' % (my_str+str(num))) 
		
#----------- 在这里输入参数 ------------------  
  
url = 'http://www.ulux.cn/proshow_'
values = ["32","33"];
#------------- 结束输入参数 ------------------  

#调用  
getHtml(url,values)
