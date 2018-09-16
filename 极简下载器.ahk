#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance force ;当脚本前一个实例正在运行时, 启动该脚本会跳过对话框并自动替换旧实例
#NoTrayIcon ;TO DO: 点击任务栏图标唤醒下载器

saved_path = 
dl_addr = 

;创建主窗口
GUI, main:new,,极简下载器
GUI, main:Default
GUI, Font,c2E5C6E s11,Microsoft YAHEI
GUI, Add, text, y+20 w500,下载地址
GUI, Add, Edit, xp+70 yp-3 w480 r1 vurl
GUI, Add, text,xp-70 yp+53 w500,保存位置
GUI, Add, Edit,xp+70 yp-3 w450 r1 vsavedpathbox
;GuiControl,text,savedpathbox,C:\Users\Vincent\Desktop\1.zip ;调试专用快捷填充
GUI, Add, Button,-Default yp xp+450 w30,...
GUI, Add, Button,Default xp-450 yp+50 w480,开始下载(&S) ;允许用户按下 Alt+S 作为其快捷键
GUI, Font, s9
Gui, Add, Link,xp-74 yp+7, <a href="https://github.com/vincentcheny/AHK-Scripts">Github Link</a>
GUI, Show

dl_addr := clipboard
;dl_addr = https://atom-installer.github.com/v1.30.0/AtomSetup-x64.exe?s=1535142947&ext=.exe ;调试专用快捷填充
if isURLValid(dl_addr,0) = 2
{
	GuiControl,Text, url, % dl_addr ;自动将剪贴板中的有效URL粘贴到下载地址
	;To be implemented in the future
	;file_name := GetFileName(dl_addr)
	;GuiControl,Text, savedpathbox, %A_Desktop%%file_name%
}
return

mainGuiClose:
msgbox, 36, 极简下载器-退出提示,确定退出极简下载器？
IfMsgBox, Yes
	ExitApp
return

mainButton...:
	FileSelectFile, saved_path, S31
	if ErrorLevel
		return ;未选择任何地址
	GuiControl, Text, savedpathbox,% saved_path
return

mainButton开始下载(S):
	GuiControlGet, dl_addr,, url
	GuiControlGet, saved_path,, savedpathbox ;使用经用户修改过的地址
	StringReplace, saved_path, saved_path,`n,, All
	if isURLValid(dl_addr,1) != 2
		return
	if isSavedPathValid(saved_path,1) != 2
		return
	DownloadFile(dl_addr,saved_path)
return 

isURLValid(dl_addr,show_info)
{
	if dl_addr =
	{
		if show_info
			msgbox, 16, Warning,下载地址为空，请检查后重试 
		return 0 ;为空
	}
	else if RegExMatch(dl_addr, "^((((H|h)(T|t)|(F|f))(T|t)(P|p)((S|s)?))\://)?(www.|[a-zA-Z0-9].)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,6}(\:[0-9]{1,5})*(/($|[a-zA-Z0-9\.\,\;\?\'\\\+&amp;%\$#\=~_\-]+))*$") != 1
	{
		if show_info
			msgbox, 16, Warning,下载地址无效，请检查后重试
		return 1 ;非空不匹配
	}
	else
		return 2 ;匹配
}

isSavedPathValid(saved_path,show_info)
{
	if saved_path =
	{
		if show_info
			msgbox, 16, Warning,保存路径为空，请检查后重试 
		return 0 ;为空
	}
	else if RegExMatch(saved_path, "^(?:[a-zA-Z]\:|\\\\[\w\.]+\\[\w.$]+)\\(?:[\w]+\\)*\w([\w.])+$") != 1
	{
		if show_info
			msgbox, 16, Warning,保存路径无效，请检查后重试
		return 1 ;非空不匹配
	}
	else
		return 2 ;匹配
}

GetFileName(url)
{
	;To be implemented in the future
}

DownloadFile(UrlToFile, SaveFileAs, Overwrite := True, UseProgressBar := True) 
{
	If (!Overwrite && FileExist(SaveFileAs))
		Return
	if (UseProgressBar = False)
	{
		UrlDownloadToFile, %UrlToFile%, %SaveFileAs%
		return
	}
	WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1") ;初始化WinHttpRequest Object
	WebRequest.Open("HEAD", UrlToFile) ;下载header
	WebRequest.Send()
	;Store the header which holds the file size in a variable:
	FinalSize := WebRequest.GetResponseHeader("Content-Length")
	FinalSizeShort := GetShortSize(FinalSize)
	
	Gosub,CreatProgressBarOn ;创建进度条窗口
	StartTime := A_TickCount
	TotalTime := 0
	global isOn := 1
	UrlDownloadToFile, %UrlToFile%, %SaveFileAs% ;下载文件

	;计算下载用时
	TotalTime := (TotalTime+A_TickCount-StartTime)/1000
	Second := Round(Mod(TotalTime,60))
	Minute := Round(Mod(TotalTime-Second,3600)) 
	Hour := Round((TotalTime-Second-Minute*60)/3600)

	;计算平均速度
	FinalSize := FileOpen(SaveFileAs,"r").Length
	AverageSpeed := (FinalSize/1024)/TotalTime
	if AverageSpeed > 1000
		AverageSpeed := Round(AverageSpeed/1000, 1) . " MB/s"
	else
		AverageSpeed .= " KB/s"
	
	;更新界面
	GuiControl,pbar_on:, ProgressBarOn,100
	GuiControl,pbar_on:, ProgressTextOn,大小: %FinalSizeShort%      平均速度: %AverageSpeed%      用时: %Hour%时%Minute%分%Second%秒
	GuiControl,pbar_on:Hide, ButtonPauseOn
	GuiControl,pbar_on:Hide, ButtonStopOn
	global ButtonExit = 
	Gui, pbar_on:Add, Button, Default vButtonExit h60 xm+2 ym+5, 关闭(&C)
	SetTimer, UpdateProgress, Off
	Return

	CreatProgressBarOn:
		;在暂停窗口处创建下载窗口
		WinGetPos, X, Y, , , 极简下载器-暂停
		GUI, pbar_on:new,,极简下载器-正在下载
		global ProgressBarOn = 
		global ProgressTextOn = 
		global ButtonPauseOn =
		global ButtonStopOn = 
		GUI, Font,c2E5C6E s10,Microsoft YAHEI
		Gui, Add, Button, Default vButtonPauseOn y+13, 暂停(&P)
		Gui, Add, Button, vButtonStopOn, 停止(&S)
		Gui, Add, GroupBox, xp+70 yp-40 w500 h65 vProgressTextOn
		Gui, Add, Progress, yp+25 xp+10 w480 h30 cA8D8B9 vProgressBarOn
		GUI, Show
		WinMove, 极简下载器-正在下载,,X, Y

		isOn := 1
		SetTimer, UpdateProgress, 200
		GUI, pbar_off:Destroy
	return

	CreatProgressBarOff:
		;在下载窗口处创建暂停窗口
		WinGetPos, X, Y, , , 极简下载器-正在下载
		GUI, pbar_off:new,,极简下载器-暂停
		global ProgressBarOff = 
		global ProgressTextOff = 
		global ButtonPauseOff =
		global ButtonStopOff = 
		GUI, Font,c2E5C6E s10,Microsoft YAHEI
		Gui, Add, Button, Default vButtonPauseOff y+13, 开始(&P)
		Gui, Add, Button, vButtonStopOff, 停止(&S)
		Gui, Add, GroupBox, xp+70 yp-40 w500 h65 vProgressTextOff
		Gui, Add, Progress, yp+25 xp+10 w480 h30 cA8D8B9 vProgressBarOff
		GUI, Show
		WinMove, 极简下载器-暂停,,X, Y
		SetTimer, UpdateProgress, Off

		isOn := 0
		Gosub, UpdateProgress 
		GUI, pbar_on:Destroy
		TotalTime += A_TickCount - StartTime
		Pause
	return

	pbar_onGuiClose:
		;非空代表未完成下载(不明机理?)
		if FinalSize = 
		{
			GUI, pbar_on:Destroy
			GuiControl, main:, savedpathbox,
			GuiControl, main:, url, ;清空文本框
			return
		}
	pbar_offGuiClose:
	pbar_onButton停止(S):
	pbar_offButton停止(S):
		msgbox, 36,, 确定取消此下载任务？
		IfMsgBox, Yes
			Reload
	return 

	pbar_onButton暂停(P):
		Gosub, CreatProgressBarOff
	return

	pbar_offButton开始(P):
		Gosub,CreatProgressBarOn
		StartTime := A_TickCount
		Pause ;暂停当前线程，等待点击激活
	return
	
	pbar_onButton关闭(C):
		GUI, pbar_on:Destroy
		GuiControl, main:, savedpathbox,
		GuiControl, main:, url,
	return

	UpdateProgress:
		CurrentSize := FileOpen(SaveFileAs,"r").Length ;FileGetSize wouldn't return reliable results
		CurrentSizeTick := A_TickCount
		;Calculate the downloadspeed
		Speed := Round((CurrentSize/1024-LastSize/1024)/((CurrentSizeTick-LastSizeTick)/1000))
		if Speed > 1000
			Speed := Round(speed/1000, 2) . " MB/s"
		else
			Speed .= " KB/s"
		;Save the current filesize and tick for the next time
		LastSizeTick := CurrentSizeTick
		LastSize := FileOpen(SaveFileAs,"r").Length
		;Calculate percent done
		PercentDone := Round(CurrentSize/FinalSize*100,1)
		if PercentDone < 10
			PercentDone = % Format("{:5}", PercentDone) ;十位为空时用空格补位，避免文本整体平移
		LastSizeShort := GetShortSize(LastSize)
		;Update the ProgressBar
		if isOn
		{
			GuiControl,pbar_on:, ProgressBarOn,% PercentDone
			GuiControl,pbar_on:, ProgressTextOn, 大小: %LastSizeShort%/%FinalSizeShort%      进度: %PercentDone%`%      速度: %Speed%
		}
		else
		{
			GuiControl,pbar_off:, ProgressBarOff,% PercentDone
			GuiControl,pbar_off:, ProgressTextOff, 大小:  %LastSizeShort%/%FinalSizeShort%      进度: %PercentDone%`%      速度: %Speed%
		}
	Return
}

GetShortSize(size)
{
	if size < %KB%
		size := size . "B"
	else if size < % 1024*1024
		size := Round(size/1024, 1) . "KB"
	else if size < % 1024*1024*1024
		size := Round(size/1024/1024, 1) . "MB"
	else
		size := Round(size/1024/1024/1024, 1) . "GB"
	return size
}
