;------------------------------------- Trait --------------------------------------
#NoEnv
#SingleInstance Force
SendMode, Input
SetWorkingDir, %A_ScriptDir%
#InstallMouseHook
;----------------------------------- Variables -----------------------------------

;cáº£m biáº¿n mÃ n hÃ¬nh (MoveWin)
SysGet, screenWidth, 78
SysGet, screenHeight, 79
MoveThreshold := 40 ; NgÆ°á»¡ng kÃ©o chuá»™t   

; Äá»c ngÆ°á»¡ng tá»« file cáº¥u hÃ¬nh náº¿u tá»“n táº¡i (khÃ´ng báº¯t buá»™c)
IniRead, _cfgThreshold, %A_ScriptDir%\gesture_config.ini, Settings, MoveThreshold, %MoveThreshold%
if (_cfgThreshold != "")
    MoveThreshold := _cfgThreshold

; Trạng thái OSD âm lượng đang mở để kích hoạt Wheel toàn cục
VolOSD_Active := 0

; Handle GUI Ã¢m lÆ°á»£ng



;------------------------------------- Links -------------------------------------

^!1::HandleMouseAction("^!1")
^!2::HandleMouseAction("^!2")
^!3::HandleMouseAction("^!3")
^!4::HandleMouseAction("^!4")
^!5::HandleMouseAction("^!5")
^!6::HandleMouseAction("^!6")
^!7::HandleMouseAction("^!7")
^!8::HandleMouseAction("^!8")

; Mouse button gestures
MButton::HandleMouseAction("{mbutton}")
RButton::HandleMouseAction("{rbutton}")

; Hotkey bánh xe chuột khi OSD đang hoạt động (toàn cục)
#If (VolOSD_Active)
WheelUp::VolumeOSD_Wheel(1)
WheelDown::VolumeOSD_Wheel(-1)
#If

;--------------------------------- Mouse Tracking --------------------------------

; Ghi log táº­p trung
Log(msg) {
    static logFile
    if (!logFile) {
        logDir := A_Desktop "\Log"
        IfNotExist, %logDir%
            FileCreateDir, %logDir%
        logFile := logDir "\gesture_log.txt"
    }
    FileAppend, %A_Now% - %msg%`n, %logFile%
}

; Äá»c hÃ nh Ä‘á»™ng tá»« file cáº¥u hÃ¬nh
getAction(hotkey, direction) {
    IniRead, value, %A_ScriptDir%\gesture_config.ini, Hotkey_%hotkey%, %direction%,
    return value
}

; Chá» nháº£ phÃ­m/nÃºt theo kiá»ƒu hotkey Ä‘ang dÃ¹ng
WaitHotkeyRelease(hotkey) {
    if (hotkey = "{mbutton}") {
        KeyWait, MButton
    } else if (hotkey = "{rbutton}") {
        KeyWait, RButton
    } else {
        StringTrimLeft, key, hotkey, 2
        KeyWait, %key%
    }
}

; XÃ¡c Ä‘á»‹nh hÆ°á»›ng dá»±a trÃªn chuyá»ƒn Ä‘á»™ng vÃ  ngÆ°á»¡ng
ResolveDirection(dx, dy, threshold) {
    if (Abs(dx) > Abs(dy)) {
        if (dx > threshold)
            return "right"
        else if (dx < -threshold)
            return "left"
        else
            return "default"
    } else {
        if (dy > threshold)
            return "down"
        else if (dy < -threshold)
            return "up"
        else
            return "default"
    }
}

; Xá»­ lÃ½ toÃ n bá»™ vÃ²ng Ä‘á»i má»™t gesture
HandleMouseAction(hotkey) {
    global MoveThreshold

    MouseGetPos, x0, y0
    WaitHotkeyRelease(hotkey)
    MouseGetPos, x1, y1

    dx := x1 - x0
    dy := y1 - y0

    Log("Hotkey: " hotkey " | dx: " dx " | dy: " dy)

    direction := ResolveDirection(dx, dy, MoveThreshold)
    action := getAction(hotkey, direction)

    Log("Direction: " direction " | Action: " action)

    if (SubStr(action, 1, 3) = "fn:") {
        funcName := SubStr(action, 4)
        Log("Call function: " funcName)
        %funcName%()
    } else if (action != "") {
        Log("Send: " action)
        Send, %action%
    }
}

;----------------------------------- Functions -----------------------------------

SCI() {
    FormatTime, timestamp,, yyyy-MM-dd_HH-mm-ss
    savePath := "C:\EpsteinBackupDrive\SavedPictures\" . timestamp . ".png"
    FileCreateDir, C:\EpsteinBackupDrive\SavedPictures
    StringReplace, savePathPS, savePath, \, \\, All
    psCommand =
    (
    Add-Type -AssemblyName System.Windows.Forms
    if ([Windows.Forms.Clipboard]::ContainsImage()) {
        $img = [Windows.Forms.Clipboard]::GetImage()
        $img.Save('%savePathPS%', 'Png')
    } else {
        Write-Host 'NO_IMAGE'
    }
    )
    tmpPS := A_Temp "\clip_save.ps1"
    FileDelete, %tmpPS%
    FileAppend, %psCommand%, %tmpPS%
    RunWait, powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -File "%tmpPS%",, Hide
    if !FileExist(savePath)
        MsgBox, Unable to detect File.
}

TypeText() {
    ; Hiá»ƒn thá»‹ há»™p thoáº¡i Ä‘á»ƒ ngÆ°á»i dÃ¹ng nháº­p text
    InputBox, userText, Type Text, Enter text to type:, , 400, 150

    ; Kiá»ƒm tra náº¿u ngÆ°á»i dÃ¹ng khÃ´ng há»§y vÃ  cÃ³ nháº­p text
    if (ErrorLevel = 0 && userText != "") {
        ; Ghi log
        Log("TypeText function called - Text: " userText)

        ; Gá»­i text ra bÃ n phÃ­m
        SendRaw, %userText%
    }
}


; (removed) work area variant

; Hien thi OSD am luong o goc duoi ben trai. Lan chuot de thay doi am luong.
; Khi kich hoat, focus vao OSD; tu dong dong khi mat focus (click sang cua so khac).
VolumeOSD(wParam:="", lParam:="", msg:="", hwnd:="") {
    global VolOSD_Active
    global OSDBar
    static osdHwnd := 0
    ; minimal state
    ; Constants
    static STEP := 3          ; buoc tang/giam (%) khi wheel
    static PAD  := 10         ; le trai/duoi OSD
    static BAR_W := 200       ; chieu rong progress bar
    static BAR_H := 12        ; chieu cao progress bar

    ; Xu ly message tu OnMessage
    if (msg != "") {
        ; Chi nhan message thuoc GUI OSD
        if (hwnd != osdHwnd)
            return

        ; (Wheel được xử lý bằng hotkey toàn cục khi OSD active)

        ; Mat focus -> dong OSD (WM_ACTIVATE: 0 = inactive)
        if (msg = 0x0006) {
            if ((wParam & 0xFFFF) = 0) {
                Gui, OSDVol:Destroy
                osdHwnd := 0
                VolOSD_Active := 0
            }
            return
        }
        return
    }

    ; Goi truc tiep de mo/hien OSD va focus vao no
    SoundGet, curVol
    if (curVol = "")
        curVol := 50

    if (!osdHwnd) {
        Gui, OSDVol:New, +AlwaysOnTop +ToolWindow -Caption +HwndhOSD
        osdHwnd := hOSD
        Gui, OSDVol:Margin, %PAD%, % PAD-2
        Gui, OSDVol:Font, s9
        Gui, OSDVol:Add, Progress, vOSDBar w%BAR_W% h%BAR_H% Range0-100, %curVol%
        OnMessage(0x0006, "VolumeOSD") ; WM_ACTIVATE
    } else {
        GuiControl, OSDVol:, OSDBar, %curVol%
    }

    Gui, OSDVol:Show, Hide AutoSize
    WinGetPos,,, w, h, ahk_id %osdHwnd%
    posX := 10
    posY := A_ScreenHeight - h - 10
    Gui, OSDVol:Show
    WinMove, ahk_id %osdHwnd%,, %posX%, %posY%
    WinActivate, ahk_id %osdHwnd%
    VolOSD_Active := 1
    Log("VolumeOSD opened and activated at " curVol "%")
}

; Xử lý cuộn chuột toàn cục khi OSD đang hoạt động
VolumeOSD_Wheel(dir) {
    global OSDBar
    ; dir: 1 = up, -1 = down
    step := (dir > 0) ? 3 : -3
    SoundGet, cur
    if (cur = "")
        cur := 50
    newVal := cur + step
    if (newVal > 100)
        newVal := 100
    if (newVal < 0)
        newVal := 0
    SoundSet, %newVal%
    ; Cập nhật OSD nếu đang mở
    GuiControl, OSDVol:, OSDBar, %newVal%
}



