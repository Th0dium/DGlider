;------------------------------------- Trait --------------------------------------
#SingleInstance Force
;----------------------------------- Variables -----------------------------------

;cảm biến màn hình (MoveWin)
SysGet, screenWidth, 78
SysGet, screenHeight, 79
MoveThreshold := 40 ; Ngưỡng kéo chuột   

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

;--------------------------------- Mouse Tracking --------------------------------

getAction(hotkey, direction) {
    IniRead, value, %A_ScriptDir%\gesture_config.ini, Hotkey_%hotkey%, %direction%,
    return value
}

HandleMouseAction(hotkey) {
    global MoveThreshold
    MouseGetPos, x0, y0

    ; Xử lý các loại hotkey khác nhau
    if (hotkey = "{mbutton}") {
        KeyWait, MButton
    } else if (hotkey = "{rbutton}") {
        KeyWait, RButton
    } else {
        StringTrimLeft, key, hotkey, 2
        KeyWait, %key%
    }

    MouseGetPos, x1, y1

    dx := x1 - x0
    dy := y1 - y0

    logDir := A_Desktop "\Log"
    IfNotExist, %logDir%
        FileCreateDir, %logDir%
    logFile := logDir "\gesture_log.txt"

    FileAppend, %A_Now% - Hotkey: %hotkey% | dx: %dx% | dy: %dy%`n, %logFile%

    if (Abs(dx) > Abs(dy)) {
        if (dx > MoveThreshold)
            action := getAction(hotkey, "right")
        else if (dx < -MoveThreshold)
            action := getAction(hotkey, "left")
        else
            action := getAction(hotkey, "default")
    } else {
        if (dy > MoveThreshold)
            action := getAction(hotkey, "down")
        else if (dy < -MoveThreshold)
            action := getAction(hotkey, "up")
        else
            action := getAction(hotkey, "default")
    }

    FileAppend, %A_Now% - Action: %action%`n, %logFile%

    if (SubStr(action, 1, 3) = "fn:") {
        funcName := SubStr(action, 4)
        FileAppend, %A_Now% - Call function: %funcName%`n, %logFile%
        %funcName%()
    } else if (action != "") {
        FileAppend, %A_Now% - Send: %action%`n, %logFile%
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
    ; Hiển thị hộp thoại để người dùng nhập text
    InputBox, userText, Type Text, Enter text to type:, , 400, 150

    ; Kiểm tra nếu người dùng không hủy và có nhập text
    if (ErrorLevel = 0 && userText != "") {
        ; Ghi log
        logDir := A_Desktop "\Log"
        IfNotExist, %logDir%
            FileCreateDir, %logDir%
        logFile := logDir "\gesture_log.txt"
        FileAppend, %A_Now% - TypeText function called - Text: %userText%`n, %logFile%

        ; Gửi text ra bàn phím
        SendRaw, %userText%
    }
}

