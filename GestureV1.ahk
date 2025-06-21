;------------------------------------- Trait --------------------------------------
#SingleInstance Force
;----------------------------------- Variables -----------------------------------

;cảm biến màn hình (MoveWin)
SysGet, screenWidth, 78
SysGet, screenHeight, 79

;------------------------------------ Mapping ------------------------------------

MoveThreshold := 40 ; Ngưỡng kéo chuột    

sendMap := {}
sendMap["^!1"] := { right: "!+{Tab}", 	left: "{Esc}",		down: "#d", 		up: "^!{Tab}", 		default: "!{Tab}" }
sendMap["^!2"] := { right: "^v", 	left: "^x", 		down: "#v", 		up: "{Backspace}", 	default: "{Enter}" }
sendMap["^!3"] := { right: "^c", 	left: "#{a}", 		down: "#{1}", 		up: "{delete}", 	default: "#{2}" }
sendMap["^!4"] := { right: "^{y}", 	left: "", 		down: "#+s", 		up: "fn:SaveClipboardImage", 		default: "^{z}" }
sendMap["^!5"] := { right: "^+{Tab}", 	left: "", 		down: "^+{t}", 		up: "^{w}", 		default: "!{Right}" }
sendMap["^!6"] := { right: "^{Tab}", 	left: "", 		down: "^{s}", 		up: "", 		default: "!{Left}" }
sendMap["^!7"] := { right: "#{right}", 	left: "", 	down: "#{down}", 	up: "#{up}", 		default: "{f5}" }
sendMap["^!8"] := { right: "",            left: "",    down: "",            up: "",              default: "{mbutton}" }

;------------------------------------ Hotkeys ------------------------------------


;------------------------------------- Links -------------------------------------

^!1::HandleMouseAction("^!1")
^!2::HandleMouseAction("^!2")
^!3::HandleMouseAction("^!3")	
^!4::HandleMouseAction("^!4")
^!5::HandleMouseAction("^!5")
^!6::HandleMouseAction("^!6")
^!7::HandleMouseAction("^!7")
^!8::HandleMouseAction("^!8")

;--------------------------------- Mouse Tracking --------------------------------

HandleMouseAction(hotkey) {
    global sendMap, MoveThreshold
    MouseGetPos, x0, y0
    StringTrimLeft, key, hotkey, 2
    KeyWait, %key%
    MouseGetPos, x1, y1

    dx := x1 - x0
    dy := y1 - y0

    if (Abs(dx) > Abs(dy)) {
        if (dx > MoveThreshold)
            action := sendMap[hotkey].right
        else if (dx < -MoveThreshold)
            action := sendMap[hotkey].left
        else
            action := sendMap[hotkey].default
    } else {
        if (dy > MoveThreshold)
            action := sendMap[hotkey].down
        else if (dy < -MoveThreshold)
            action := sendMap[hotkey].up
        else
            action := sendMap[hotkey].default
    }

    ;------------------------------------ Fn Call -----------------------------------

    if (SubStr(action, 1, 3) = "fn:") {
        funcName := SubStr(action, 4)
        ; Gọi hàm theo tên
        %funcName%()
    } else if (action != "") {
        Send, %action%
    }
}

;----------------------------------- Functions -----------------------------------

SaveClipboardImage() {
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
        MsgBox, ❌ Clipboard không chứa ảnh hoặc PowerShell không thể truy cập ảnh.
}

