;------------------------------------- Traits -------------------------------------
#NoEnv
#SingleInstance Force
SendMode, Input
SetWorkingDir, %A_ScriptDir%
#InstallMouseHook

;----------------------------------- Variables -----------------------------------

SysGet, screenWidth, 78
SysGet, screenHeight, 79
MoveThreshold := 30

;--------------------------------- Key pickup ------------------------------------

; Mouse button gestures
RButton:: HandleMouseAction("{rbutton}")

; Navigation buttons
XButton1:: HandleMouseAction("{xbutton1}")
XButton2:: HandleMouseAction("{xbutton2}")

;------------------------------- Gesture Dispatch --------------------------------

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

getAction(hotkey, direction) {
    ; Read from gesture_config.ini
    section := "Hotkey_" hotkey
    IniRead, value, %A_ScriptDir%\gesture_config.ini, %section%, %direction%,
    return value
}

getButtonMode(hotkey) {
    ; Read button mode: gesture, click, or aim
    section := "Hotkey_" hotkey
    IniRead, mode, %A_ScriptDir%\gesture_config_dev.ini, %section%, mode, gesture
    return mode
}

getAimDelay(hotkey) {
    ; Read aim mode repeat delay in ms
    section := "Hotkey_" hotkey
    IniRead, delay, %A_ScriptDir%\gesture_config_dev.ini, %section%, aim_delay, 100
    return delay
}

WaitHotkeyRelease(hotkey) {
    if (hotkey = "{rbutton}") {
        KeyWait, RButton
    } else if (hotkey = "{xbutton1}") {
        KeyWait, XButton1
    } else if (hotkey = "{xbutton2}") {
        KeyWait, XButton2
    }
}

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

HandleMouseAction(hotkey) {
    global MoveThreshold

    mode := getButtonMode(hotkey)
    Log("Hotkey: " hotkey " | Mode: " mode)

    if (mode = "click") {
        HandleClickMode(hotkey)
    } else if (mode = "aim") {
        HandleAimMode(hotkey)
    } else {
        HandleGestureMode(hotkey)
    }
}

HandleClickMode(hotkey) {
    ; Click mode: just execute default action without gesture detection
    action := getAction(hotkey, "default")
    Log("Click mode - Action: " action)

    if (SubStr(action, 1, 3) = "fn:") {
        funcName := SubStr(action, 4)
        if (IsFunc(funcName)) {
            %funcName%()
        }
    } else if (action != "") {
        Send, %action%
    }
}

HandleGestureMode(hotkey) {
    ; Original gesture mode: hold + drag + release
    global MoveThreshold

    MouseGetPos, x0, y0
    WaitHotkeyRelease(hotkey)
    MouseGetPos, x1, y1

    dx := x1 - x0
    dy := y1 - y0

    Log("Gesture mode | dx: " dx " | dy: " dy)

    direction := ResolveDirection(dx, dy, MoveThreshold)
    action := getAction(hotkey, direction)

    Log("Direction: " direction " | Action: " action)

    ExecuteAction(action)
}

HandleAimMode(hotkey) {
    ; Aim mode: repeat action while dragging and holding
    global MoveThreshold
    
    MouseGetPos, x0, y0
    delay := getAimDelay(hotkey)
    lastDirection := ""
    
    ; Determine which key to check
    if (hotkey = "{rbutton}") {
        keyName := "RButton"
    } else if (hotkey = "{xbutton1}") {
        keyName := "XButton1"
    } else if (hotkey = "{xbutton2}") {
        keyName := "XButton2"
    } else {
        return
    }
    
    ; Monitor mouse position while button is held
    Loop {
        if (!GetKeyState(keyName, "P"))
            break
            
        MouseGetPos, x1, y1
        dx := x1 - x0
        dy := y1 - y0
        
        direction := ResolveDirection(dx, dy, MoveThreshold)
        
        ; Only trigger if direction changed or on first detection
        if (direction != "default" && direction != lastDirection) {
            action := getAction(hotkey, direction)
            Log("Aim mode | Direction: " direction " | Action: " action)
            
            ExecuteAction(action)
            lastDirection := direction
        }
        
        Sleep, %delay%
    }
    
    Log("Aim mode released")
}ExecuteAction(action) {
    if (SubStr(action, 1, 3) = "fn:") {
        funcName := SubStr(action, 4)
        if (IsFunc(funcName)) {
            Log("Call function: " funcName)
            %funcName%()
        } else {
            Log("Function not found: " funcName)
        }
    } else if (action != "") {
        Log("Send: " action)
        Send, %action%
    }
}
