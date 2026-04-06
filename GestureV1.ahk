;------------------------------------- Traits -------------------------------------
#NoEnv
#SingleInstance Force
SendMode, Input
SetWorkingDir, %A_ScriptDir%
#InstallMouseHook
;----------------------------------- Variables -----------------------------------

SysGet, screenWidth, 78
SysGet, screenHeight, 79
MoveThreshold := 30 ;

; Profile support
ActiveProfile := "dglider"

IniRead, _cfgProfile, %A_ScriptDir%\gesture_config.ini, Settings, ActiveProfile, %ActiveProfile%
if (_cfgProfile != "")
    ActiveProfile := _cfgProfile

IniRead, _cfgThreshold, %A_ScriptDir%\gesture_config.ini, Settings, MoveThreshold, %MoveThreshold%
if (_cfgThreshold != "")
    MoveThreshold := _cfgThreshold

VolOSD_Active := 0
ProdTimer_Running := 0
ProdTimer_TotalMs := 0
ProdTimer_LastStartTick := 0
ProdTimer_Visible := 0
ProdTimer_HideTick := 0
ProdTimer_GuiHwnd := 0
ProdTimerDisplayCtrl := ""

; Initialize mouse-button hotkeys based on current profile
SetupMouseButtonHotkeys()

; Initialize dynamic mouse-button hotkeys based on current profile
SetupMouseButtonHotkeys()

;--------------------------------- Key pickup ------------------------------------

^!1::HandleMouseAction("^!1")
^!2::HandleMouseAction("^!2")
^!3::HandleMouseAction("^!3")
^!4::HandleMouseAction("^!4")
^!5::HandleMouseAction("^!5")
^!6::HandleMouseAction("^!6")
^!7::HandleMouseAction("^!7")
^!8::HandleMouseAction("^!8")
^!9::HandleMouseAction("^!9")
^!0::HandleMouseAction("^!0")

; Mouse button gestures (managed dynamically by profile)
; Bindings are set via SetupMouseButtonHotkeys/ApplyProfileHotkeys.
; Labels for handlers are defined here:

MBUTTON_HOTKEY:
    HandleMouseAction("{mbutton}")
return

RBUTTON_HOTKEY:
    HandleMouseAction("{rbutton}")
return

; Navigation buttons
XButton1::HandleMouseAction("{xbutton1}")
XButton2::HandleMouseAction("{xbutton2}")

; Global wheel hotkeys when Volume OSD is active
#If (VolOSD_Active)
    WheelUp::VolumeOSD_Wheel(1)
    WheelDown::VolumeOSD_Wheel(-1)
#If

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
    global ActiveProfile
    ; 1) New scheme: section = Profile_<profile>_Hotkey_<hotkey>, key = <direction>
    section := "Profile_" ActiveProfile "_Hotkey_" hotkey
    IniRead, value, %A_ScriptDir%\gesture_config.ini, %section%, %direction%,
    if (value != "")
        return value
    ; 2) Old scheme (namespaced key inside Hotkey_ section): <profile>.<direction>
    IniRead, value2, %A_ScriptDir%\gesture_config.ini, Hotkey_%hotkey%, %ActiveProfile%.%direction%,
    if (value2 != "")
        return value2
    ; 3) Legacy fallback: plain <direction>
    IniRead, value3, %A_ScriptDir%\gesture_config.ini, Hotkey_%hotkey%, %direction%,
    return value3
}

WaitHotkeyRelease(hotkey) {
    if (hotkey = "{mbutton}") {
        KeyWait, MButton
    } else if (hotkey = "{rbutton}") {
        KeyWait, RButton
    } else if (hotkey = "{xbutton1}") {
        KeyWait, XButton1
    } else if (hotkey = "{xbutton2}") {
        KeyWait, XButton2
    } else {
        StringTrimLeft, key, hotkey, 2
        KeyWait, %key%
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
    global ActiveProfile

    MouseGetPos, x0, y0
    WaitHotkeyRelease(hotkey)
    MouseGetPos, x1, y1

    dx := x1 - x0
    dy := y1 - y0

    Log("Hotkey: " hotkey " | Profile: " ActiveProfile " | dx: " dx " | dy: " dy)

    direction := ResolveDirection(dx, dy, MoveThreshold)
    action := getAction(hotkey, direction)

    Log("Direction: " direction " | Action: " action)

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

; Hotkey setup/toggle for mouse buttons (MButton/RButton) based on profile
SetupMouseButtonHotkeys() {
    ; Assign labels once, then toggle On/Off per profile
    Hotkey, MButton, MBUTTON_HOTKEY
    Hotkey, RButton, RBUTTON_HOTKEY
    ApplyProfileHotkeys()
}

ApplyProfileHotkeys() {
    global ActiveProfile
    if (ActiveProfile = "Off") {
        Hotkey, MButton, Off
        Hotkey, RButton, Off
    } else {
        Hotkey, MButton, On
        Hotkey, RButton, On
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
    InputBox, userText, Type Text, Enter text to type:, , 400, 150

    if (ErrorLevel = 0 && userText != "") {
        Log("TypeText function called - Text: " userText)

        SendRaw, %userText%
    }
}

; Show a simple Volume OSD at middle-left. Use mouse wheel to adjust volume.
; When activated, focus goes to the OSD; auto-closes when it loses focus.
VolumeOSD(wParam:="", lParam:="", msg:="", hwnd:="") {
    global VolOSD_Active
    global OSDBar
    static osdHwnd := 0
    static STEP := 1 ; Step volume change per wheel notch
    static PAD := 10 ; Left/Right padding of OSD
    static BAR_W := 200 ; Width of progress bar
    static BAR_H := 12 ; Height of progress bar

    ; Handle messages from OnMessage
    if (msg != "") {
        if (hwnd != osdHwnd)
            return
        ; Mouse wheel is handled by global hotkeys when OSD is active
        ; Lose focus -> destroy OSD (WM_ACTIVATE: 0 = inactive)
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

    ; Open/show OSD and focus it
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

    ; Enable wheel hotkeys immediately before showing the GUI
    VolOSD_Active := 1

    Gui, OSDVol:Show, Hide AutoSize
    WinGetPos,,, w, h, ahk_id %osdHwnd%
    posX := 10
    posY := A_ScreenHeight - h - 10
    Gui, OSDVol:Show
    WinMove, ahk_id %osdHwnd%,, %posX%, %posY%
    WinActivate, ahk_id %osdHwnd%
    Log("VolumeOSD opened and activated at " curVol "%")
}

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
    ; Update OSD if it's visible
    GuiControl, OSDVol:, OSDBar, %newVal%
}

WorkTimerToggle() {
    global ProdTimer_Running, ProdTimer_TotalMs, ProdTimer_LastStartTick
    global ProdTimer_Visible

    nowTick := A_TickCount

    if (!ProdTimer_Visible) {
        Log("Work timer OSD shown")
        WorkTimer_ShowForDuration(3000)
        return
    }

    if (ProdTimer_Running) {
        ProdTimer_TotalMs += (nowTick - ProdTimer_LastStartTick)
        ProdTimer_Running := 0
        Log("Work timer paused at " WorkTimer_FormatElapsed(ProdTimer_TotalMs))
    } else {
        ProdTimer_LastStartTick := nowTick
        ProdTimer_Running := 1
        Log("Work timer started")
    }

    WorkTimer_ShowForDuration(3000)
}

WorkTimerShow() {
    Log("Work timer OSD shown (show-only key)")
    WorkTimer_ShowForDuration(3000)
}

WorkTimerShowAltTab() {
    WorkTimerShow()
    Send, !{Tab}
    Log("Work timer OSD shown + AltTab")
}

WorkTimerReset() {
    global ProdTimer_Running, ProdTimer_TotalMs, ProdTimer_LastStartTick, ProdTimer_Visible

    ; Reset is allowed only when OSD is visible and timer is paused.
    if (ProdTimer_Visible && !ProdTimer_Running) {
        ProdTimer_Running := 0
        ProdTimer_TotalMs := 0
        ProdTimer_LastStartTick := 0
        Log("Work timer reset")
        WorkTimer_ShowForDuration(3000)
        return
    }

    ; While running, this key acts as "-10 seconds".
    if (!ProdTimer_Running) {
        Log("Work timer reset skipped (OSD hidden or timer not running)")
        return
    }

    currentMs := WorkTimer_GetElapsedMs()
    newMs := currentMs - 10000
    if (newMs < 0)
        newMs := 0

    ProdTimer_TotalMs := newMs
    if (ProdTimer_Running)
        ProdTimer_LastStartTick := A_TickCount
    else
        ProdTimer_LastStartTick := 0

    Log("Work timer -10s -> " WorkTimer_FormatElapsed(newMs))
    if (ProdTimer_Visible)
        WorkTimer_ShowForDuration(3000)
}

WorkTimer_ShowForDuration(durationMs:=3000) {
    global ProdTimer_GuiHwnd, ProdTimer_Visible, ProdTimer_HideTick, ProdTimerDisplayCtrl

    if (!ProdTimer_GuiHwnd) {
        Gui, ProdTimerOSD:New, +AlwaysOnTop +ToolWindow -Caption +HwndhProdTimer
        ProdTimer_GuiHwnd := hProdTimer
        Gui, ProdTimerOSD:Color, 1B1B1B
        Gui, ProdTimerOSD:Margin, 14, 10
        Gui, ProdTimerOSD:Font, s15 w700 c9CFFAA, Segoe UI
        Gui, ProdTimerOSD:Add, Text, vProdTimerDisplayCtrl Center w340, Timer 00:00:00 [Paused]
    }

    ProdTimer_Visible := 1
    ProdTimer_HideTick := A_TickCount + durationMs
    GoSub, WorkTimerUpdateLoop
    Gui, ProdTimerOSD:Show, NoActivate x50 y50, ProdTimerOSD
    SetTimer, WorkTimerUpdateLoop, 100
}

WorkTimer_Hide() {
    global ProdTimer_Visible

    Gui, ProdTimerOSD:Hide
    ProdTimer_Visible := 0
    SetTimer, WorkTimerUpdateLoop, Off
}

WorkTimer_GetElapsedMs() {
    global ProdTimer_Running, ProdTimer_TotalMs, ProdTimer_LastStartTick

    if (ProdTimer_Running)
        return ProdTimer_TotalMs + (A_TickCount - ProdTimer_LastStartTick)
    return ProdTimer_TotalMs
}

WorkTimer_FormatElapsed(totalMs) {
    totalSeconds := Floor(totalMs / 1000)
    hours := Floor(totalSeconds / 3600)
    minutes := Floor(Mod(totalSeconds, 3600) / 60)
    seconds := Mod(totalSeconds, 60)
    return Format("{:02}:{:02}:{:02}", hours, minutes, seconds)
}

WorkTimerUpdateLoop:
    if (!ProdTimer_Visible)
        return

    elapsedMs := WorkTimer_GetElapsedMs()
    state := ProdTimer_Running ? "Running" : "Paused"
    GuiControl, ProdTimerOSD:, ProdTimerDisplayCtrl, % "Timer " WorkTimer_FormatElapsed(elapsedMs) " [" state "]"

    if (A_TickCount >= ProdTimer_HideTick)
        WorkTimer_Hide()
return

; Screen rotation by timed mouse movement sample (no GUI).
ScreenRotateOSD() {
    global MoveThreshold

    ; Sample A immediately, wait 500ms, then sample B.
    MouseGetPos, xA, yA
    Sleep, 500
    MouseGetPos, xB, yB

    dx := xB - xA
    dy := yB - yA
    direction := ResolveDirection(dx, dy, MoveThreshold)

    targetDisplay := GetMonitorNameFromPoint(xB, yB)
    Log("ScreenRotate gesture dx: " dx " dy: " dy " dir: " direction " display: " targetDisplay)

    ; Map gesture direction to rotation angle.
    if (direction = "up") {
        RotateDisplay(180, targetDisplay)
    } else if (direction = "right") {
        result := RotateDisplay(90, targetDisplay)
        if (result = 2) {
            Log("ScreenRotateOSD: portrait unsupported, fallback right -> 0")
            RotateDisplay(0, targetDisplay)
        }
    } else if (direction = "down") {
        RotateDisplay(0, targetDisplay)
    } else if (direction = "left") {
        result := RotateDisplay(270, targetDisplay)
        if (result = 2) {
            Log("ScreenRotateOSD: portrait unsupported, fallback left -> 180")
            RotateDisplay(180, targetDisplay)
        }
    } else {
        Log("ScreenRotateOSD: no significant movement")
    }
}

GetMonitorNameFromPoint(x, y) {
    SysGet, monCount, MonitorCount
    Loop, %monCount% {
        idx := A_Index
        SysGet, mon, Monitor, %idx%
        if (x >= monLeft && x < monRight && y >= monTop && y < monBottom) {
            SysGet, monName, MonitorName, %idx%
            return monName
        }
    }
    return ""
}

RotateDisplay(angle, deviceName:="") {
    ; angle: 0, 90, 180, 270
    static DM_DISPLAYORIENTATION := 0x80
    static DM_PELSWIDTH := 0x80000
    static DM_PELSHEIGHT := 0x100000

    if (angle != 0 && angle != 90 && angle != 180 && angle != 270) {
        Log("RotateDisplay invalid angle: " angle)
        return 3
    }

    dmSize := (A_PtrSize = 8) ? 220 : 156
    VarSetCapacity(dm, dmSize, 0)
    NumPut(dmSize, dm, 68, "UShort") ; dmSize

    if (deviceName = "") {
        enumOk := DllCall("EnumDisplaySettings", "ptr", 0, "uint", -1, "ptr", &dm)
    } else {
        enumOk := DllCall("EnumDisplaySettings", "str", deviceName, "uint", -1, "ptr", &dm)
    }
    if (!enumOk) {
        Log("RotateDisplay: EnumDisplaySettings failed")
        return 3
    }

    orientMap := {0: 0, 90: 1, 180: 2, 270: 3}
    newOrient := orientMap[angle]
    curOrient := NumGet(dm, 84, "UInt")
    if (curOrient = newOrient) {
        Log("RotateDisplay: already at " angle)
        return 0
    }

    curW := NumGet(dm, 108, "UInt")
    curH := NumGet(dm, 112, "UInt")
    curPortrait := (curOrient = 1 || curOrient = 3)
    newPortrait := (newOrient = 1 || newOrient = 3)

    dmFields := NumGet(dm, 72, "UInt")
    dmFields |= DM_DISPLAYORIENTATION

    if (curPortrait != newPortrait) {
        ; Swap width/height when rotating between landscape/portrait
        NumPut(curH, dm, 108, "UInt")
        NumPut(curW, dm, 112, "UInt")
        dmFields |= DM_PELSWIDTH | DM_PELSHEIGHT
    }

    NumPut(dmFields, dm, 72, "UInt")
    NumPut(newOrient, dm, 84, "UInt")

    if (deviceName = "") {
        result := DllCall("ChangeDisplaySettings", "ptr", &dm, "uint", 0)
    } else {
        result := DllCall("ChangeDisplaySettingsEx", "str", deviceName, "ptr", &dm, "ptr", 0, "uint", 0, "ptr", 0)
    }
    Log("RotateDisplay result: " result " -> angle " angle)
    if (result = 1) {
        MsgBox, 48, DGlider, Display rotation applied. A restart may be required.
    } else if (result = 2) {
        MsgBox, 48, DGlider, Rotation not supported for this display/driver (portrait mode may be unavailable).
    } else if (result != 0) {
        MsgBox, 16, DGlider, Display rotation failed. Result code: %result%
    }
    return result
}

;------------------------------- Profile Management ------------------------------

GetProfiles() {
    ; Return a list string of profiles (comma/pipe/semicolon separated). Defaults to "default".
    IniRead, names, %A_ScriptDir%\gesture_config.ini, Profiles, Names, default
    if (names = "")
        names := "default"
    return names
}

ProfileSet(name) {
    global ActiveProfile
    if (name = "")
        return
    ActiveProfile := name
    IniWrite, %name%, %A_ScriptDir%\gesture_config.ini, Settings, ActiveProfile
    TrayTip, DGlider, Active profile: %name%, 1500
    Log("Switched profile -> " name)
    ; Ensure mouse-button hotkeys reflect current profile state
    ApplyProfileHotkeys()
}

; Backward-compatible entry point: show selector instead of cycling
ProfileNext() {
    SelectProfile()
}

ProfilePrompt() {
    global ActiveProfile
    names := GetProfiles()
    ; Show current and accept new name
    InputBox, newProf, Switch Profile, Available: %names%`nCurrent: %ActiveProfile%`nEnter profile name:, , 420, 180
    if (ErrorLevel)
        return
    if (newProf != "")
        ProfileSet(newProf)
}

; Show a small two-column GUI to select a profile
SelectProfile() {
    names := GetProfiles()
    ; Normalize separators to comma and strip spaces
    names := StrReplace(names, "|", ",")
    names := StrReplace(names, ";", ",")
    names := StrReplace(names, A_Space, "")
    arr := StrSplit(names, ",")
    if (arr.MaxIndex() < 1)
        return

    Gui, ProfSel:Destroy
    Gui, ProfSel:New, +AlwaysOnTop +ToolWindow, Select Profile
    Gui, ProfSel:Margin, 10, 10

    rows := Ceil(arr.MaxIndex()/2.0)
    btnW := 140
    btnH := 28
    gap := 6
    col1x := 10
    col2x := col1x + btnW + 10

    Loop % arr.MaxIndex()
    {
        idx := A_Index
        name := arr[idx]
        col := (idx <= rows) ? 1 : 2
        rowIdx := (col=1) ? idx : (idx - rows)
        x := (col=1) ? col1x : col2x
        y := 10 + (rowIdx-1)*(btnH+gap)
        ctrlVar := "ProfBtn" idx
        opts := "x" x " y" y " w" btnW " h" btnH " gSelectProfile_Click"
        Gui, ProfSel:Add, Button, %opts%, %name%
    }

    Gui, ProfSel:Show, AutoSize, Select Profile
}

SelectProfile_Click:
    GuiControlGet, prof, ProfSel:, %A_GuiControl%, Text
    if (prof != "")
        ProfileSet(prof)
    Gui, ProfSel:Destroy
return

ProfSelGuiEscape:
    Gui, ProfSel:Destroy
return

ProfSelGuiClose:
    Gui, ProfSel:Destroy
return

; ----------------------------------------------------------------------

; This is for my personal use, delete it if you want, This sections should be keep at the bottom
; Japanese keyboard remappings
SC07B::Send, {Space}        ; First key = Spacebar
SC079::Send, {Space}        ; Second key = Spacebar

SC070::Send, {Backspace}    ; Always send Ctrl+Backspace
+SC070::Send, {Backspace}  ; Always send Ctrl+Backspace
^SC070::Send, ^{Backspace}  ; Always send Ctrl+Backspace

^SC07D::Send, ^{Backspace}  ; Always send Ctrl+Backspace
SC07D::Send, {Backspace}    ; Always send Ctrl+Backspace
+SC07D::Send, {Backspace}  ; Always send Ctrl+Backspace

SC073::Send, ^v             ; Fifth key = Ctrl+V
^Space:: send _

