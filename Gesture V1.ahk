#SingleInstance Force
;----------------------------------- Variables -----------------------------------

;cảm biến màn hình (MoveWin)
SysGet, screenWidth, 78
SysGet, screenHeight, 79

;------------------------------------ Mapping ------------------------------------

MoveThreshold := 30 ; Ngưỡng kéo chuột    

sendMap := {}
sendMap["^!1"] := { right: "{Esc}", 	left: "!+{Tab}",	down: "#d", 		up: "^!{Tab}", 		default: "!{Tab}" }
sendMap["^!2"] := { right: "^v", 	left: "^x", 		down: "#v", 		up: "{Backspace}", 	default: "{Enter}" }
sendMap["^!3"] := { right: "^c", 	left: "#{a}", 		down: "#{1}", 		up: "^{s}", 		default: "#{2}" }
sendMap["^!4"] := { right: "^{y}", 	left: "", 		down: "#+s", 		up: "", 		default: "^{z}" }
sendMap["^!5"] := { right: "", 		left: "", 		down: "^m^r", 		up: "^w", 		default: "!{Right}" }
sendMap["^!6"] := { right: "^{Tab}", 	left: "^+{Tab}", 	down: "", 		up: "", 		default: "!{Left}" }
sendMap["^!7"] := { right: "#{right}", 	left: "", 		down: "#{down}", 	up: "#{up}", 		default: "" }

;------------------------------------ Hotkeys ------------------------------------


;------------------------------------- Links -------------------------------------

^!1::HandleMouseAction("^!1")
^!2::HandleMouseAction("^!2")
^!3::HandleMouseAction("^!3")	
^!4::HandleMouseAction("^!4")
^!5::HandleMouseAction("^!5")
^!6::HandleMouseAction("^!6")
^!7::HandleMouseAction("^!7")

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

    if (action = "MoveWinR") {
        MoveWindowRight()
    } else if (action = "MoveWinL") {
        MoveWindowLeft()
    } else if (action = "MaxWin") {
        MaximizeActiveWindow()
    } else if (action != "") {
        Send, %action%
    }
}

;----------------------------------- Functions -----------------------------------

MoveWindowRight() {
    global
    WinGet, windowID, ID, A
    if !windowID
        return
    WinGet, state, MinMax, ahk_id %windowID%
    if (state = 1)
        WinRestore, ahk_id %windowID%
    WinMove, ahk_id %windowID%, , screenWidth//2, 0, screenWidth//2+10, screenHeight+7
}


MoveWindowLeft() {
    global
    WinGet, window, ID, A
    if !window
        return
    WinGet, state, MinMax, ahk_id %window%
    if (state = 1)
        WinRestore, ahk_id %window%
    WinMove, ahk_id %window%, , -7, 0, screenWidth//2+20, screenHeight +7
}


MaximizeActiveWindow() {
    WinMaximize, A
}
