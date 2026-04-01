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
DebtOSD_Visible := 0
DebtOSD_GuiHwnd := 0
DebtOSD_BaseAmount := 0
DebtOSD_DeltaPerSecond := 0
DebtOSD_CurrencyPrefix := "$"
DebtOSD_CurrencySuffix := ""
DebtOSD_Decimals := 2
DebtOSD_PosX := 50
DebtOSD_PosY := 90
DebtOSD_Width := 240
DebtOSD_FontSize := 18
DebtOSD_TextColor := "FF8080"
DebtOSD_BackgroundColor := "1B1B1B"
DebtOSD_LastWholeSeconds := -1
DebtOSD_BaseTimestamp := A_Now

DebtOSD_LoadConfig()

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

    ;----------------------------------- Timer OSD Function -----------------------------------

    TimerToggle() {
        global Timer_State, Timer_StartTime, Timer_Accumulated, Timer_GuiHwnd, TimerDisplay, Timer_Visible

        ; Initialize variables
        if (Timer_State = "") {
            Timer_State := 0        ; 0: Stopped/Paused, 1: Running
            Timer_Accumulated := 0
            Timer_Visible := 0
        }

        ; --- LOGIC: STOPPED -> START ---
        if (Timer_State = 0 && Timer_Accumulated = 0) {
            Timer_State := 1
            Timer_StartTime := A_TickCount
            Timer_Show()
            Log("Timer Started")
            return
        }

        ; --- LOGIC: PAUSED -> RESUME ---
        if (Timer_State = 0 && Timer_Accumulated > 0) {
            Timer_State := 1
            Timer_StartTime := A_TickCount
            Timer_Show()
            Log("Timer Resumed")
            return
        }

        ; --- LOGIC: RUNNING ---
        if (Timer_State = 1) {
            if (Timer_Visible) {
                ; If Running AND Visible -> PAUSE
                Timer_State := 0
                Timer_Accumulated += (A_TickCount - Timer_StartTime)

                ; Visual feedback for Pause
                Gui, TimerOSD:Font, cYellow
                GuiControl, TimerOSD:Font, TimerDisplay
                GuiControl, TimerOSD:, TimerDisplay, % FormatTimer(Timer_Accumulated)

                ; Keep visible for a bit then hide
                SetTimer, TimerAutoHide, -4000
                Log("Timer Paused")
            } else {
                ; If Running AND Hidden -> PEEK (Show briefly)
                Timer_Show()
                Log("Timer Peek")
            }
        }
    }

    Timer_Show() {
        global Timer_GuiHwnd, TimerDisplay, Timer_Visible, Timer_State

        if (!Timer_GuiHwnd) {
            Gui, TimerOSD:New, +AlwaysOnTop +ToolWindow -Caption +HwndTimer_GuiHwnd
            Gui, TimerOSD:Color, 222222
            Gui, TimerOSD:Font, s16 w700, Segoe UI
            Gui, TimerOSD:Add, Text, vTimerDisplay c00FF00 Center w180, 00:00:00
        }

        ; Reset color to Green if running
        if (Timer_State = 1) {
            Gui, TimerOSD:Font, c00FF00
            GuiControl, TimerOSD:Font, TimerDisplay
        }

        ; Update immediately before showing
        GoSub, TimerUpdateLoop

        Gui, TimerOSD:Show, NoActivate x50 y50, TimerOSD
        Timer_Visible := 1

        ; Start updating loop
        SetTimer, TimerUpdateLoop, 100

        ; Auto hide after 3 seconds (Peek mode)
        SetTimer, TimerAutoHide, -3000
    }

TimerUpdateLoop:
    if (Timer_State = 1) {
        CurrentDuration := (A_TickCount - Timer_StartTime) + Timer_Accumulated
        GuiControl, TimerOSD:, TimerDisplay, % FormatTimer(CurrentDuration)
    }
return

TimerAutoHide:
    Gui, TimerOSD:Hide
    Timer_Visible := 0
    ; Don't stop the loop if running, just stop updating UI?
    ; Actually, we can keep loop running or stop it to save CPU.
    ; Let's stop UI updates to save resources if hidden.
    if (Timer_State = 1) {
        SetTimer, TimerUpdateLoop, Off
    }
return

FormatTimer(ms) {
    totalSec := Floor(ms / 1000)
    hours := Floor(totalSec / 3600)
    rem := Mod(totalSec, 3600)
    mins := Floor(rem / 60)
    secs := Mod(rem, 60)

    ; Format HH:MM:SS
    hrStr := (hours < 10) ? "0" . hours : hours
    minStr := (mins < 10) ? "0" . mins : mins
    secStr := (secs < 10) ? "0" . secs : secs
    return hrStr . ":" . minStr . ":" . secStr
}

TimerReset() {
    global Timer_State, Timer_Accumulated, Timer_Visible
    Timer_State := 0
    Timer_Accumulated := 0
    GuiControl, TimerOSD:, TimerDisplay, 00:00:00
    Gui, TimerOSD:Hide
    Timer_Visible := 0
    SetTimer, TimerUpdateLoop, Off
    Log("Timer reset")
}

DebtOSDToggle() {
    global DebtOSD_Visible

    if (DebtOSD_Visible) {
        DebtOSD_Hide()
        Log("DebtOSD hidden")
    } else {
        DebtOSD_Show()
        Log("DebtOSD shown")
    }
}

DebtOSD_Show() {
    global DebtOSD_GuiHwnd, DebtOSD_Visible, DebtOSD_PosX, DebtOSD_PosY, DebtOSD_Width
    global DebtOSD_FontSize, DebtOSD_TextColor, DebtOSD_BackgroundColor
    global DebtOSD_LastWholeSeconds

    if (!DebtOSD_GuiHwnd) {
        Gui, DebtOSD:New, +AlwaysOnTop +ToolWindow -Caption +HwndDebtOSD_GuiHwnd
        Gui, DebtOSD:Color, %DebtOSD_BackgroundColor%
        Gui, DebtOSD:Margin, 14, 10
        Gui, DebtOSD:Font, s%DebtOSD_FontSize% w700 c%DebtOSD_TextColor%, Segoe UI
        Gui, DebtOSD:Add, Text, vDebtOSD_Value Center w%DebtOSD_Width%, $0.00
    }

    DebtOSD_Visible := 1
    DebtOSD_LastWholeSeconds := -1
    GoSub, DebtOSD_UpdateLoop
    Gui, DebtOSD:Show, NoActivate x%DebtOSD_PosX% y%DebtOSD_PosY%, DebtOSD
    SetTimer, DebtOSD_UpdateLoop, 250
}

DebtOSD_Hide() {
    global DebtOSD_Visible

    Gui, DebtOSD:Hide
    DebtOSD_Visible := 0
    SetTimer, DebtOSD_UpdateLoop, Off
}

DebtOSD_LoadConfig() {
    global DebtOSD_BaseAmount, DebtOSD_DeltaPerSecond, DebtOSD_CurrencyPrefix, DebtOSD_CurrencySuffix
    global DebtOSD_Decimals, DebtOSD_PosX, DebtOSD_PosY, DebtOSD_Width, DebtOSD_FontSize
    global DebtOSD_TextColor, DebtOSD_BackgroundColor, DebtOSD_BaseTimestamp

    IniRead, DebtOSD_BaseAmount, %A_ScriptDir%\gesture_config.ini, DebtOSD, InitialAmount, 0
    IniRead, DebtOSD_DeltaPerSecond, %A_ScriptDir%\gesture_config.ini, DebtOSD, DeltaPerSecond, 0
    IniRead, DebtOSD_BaseTimestamp, %A_ScriptDir%\gesture_config.ini, DebtOSD, BaseTimestamp, %A_Now%
    IniRead, DebtOSD_CurrencyPrefix, %A_ScriptDir%\gesture_config.ini, DebtOSD, CurrencyPrefix, $
    IniRead, DebtOSD_CurrencySuffix, %A_ScriptDir%\gesture_config.ini, DebtOSD, CurrencySuffix,
    IniRead, DebtOSD_Decimals, %A_ScriptDir%\gesture_config.ini, DebtOSD, Decimals, 2
    IniRead, DebtOSD_PosX, %A_ScriptDir%\gesture_config.ini, DebtOSD, PosX, 50
    IniRead, DebtOSD_PosY, %A_ScriptDir%\gesture_config.ini, DebtOSD, PosY, 90
    IniRead, DebtOSD_Width, %A_ScriptDir%\gesture_config.ini, DebtOSD, Width, 240
    IniRead, DebtOSD_FontSize, %A_ScriptDir%\gesture_config.ini, DebtOSD, FontSize, 18
    IniRead, DebtOSD_TextColor, %A_ScriptDir%\gesture_config.ini, DebtOSD, TextColor, FF8080
    IniRead, DebtOSD_BackgroundColor, %A_ScriptDir%\gesture_config.ini, DebtOSD, BackgroundColor, 1B1B1B

    DebtOSD_BaseAmount += 0
    DebtOSD_DeltaPerSecond += 0
    DebtOSD_Decimals += 0
    DebtOSD_PosX += 0
    DebtOSD_PosY += 0
    DebtOSD_Width += 0
    DebtOSD_FontSize += 0
    if (DebtOSD_BaseTimestamp = "")
        DebtOSD_BaseTimestamp := A_Now
}

DebtOSDConfig() {
    global DebtOSD_BaseAmount, DebtOSD_DeltaPerSecond, DebtOSD_CurrencyPrefix, DebtOSD_CurrencySuffix
    global DebtOSD_Visible, DebtOSD_LastWholeSeconds, DebtOSD_BaseTimestamp

    currentAmount := DebtOSD_GetCurrentAmount()

    InputBox, newAmount, Debt OSD, Starting amount from right now:, , 360, 150,,,,, %currentAmount%
    if (ErrorLevel)
        return
    if newAmount is not number
    {
        MsgBox, 48, DGlider, Starting amount must be numeric.
        return
    }

    InputBox, newDelta, Debt OSD, Change per second:`nUse negative to count down., , 360, 170,,,,, %DebtOSD_DeltaPerSecond%
    if (ErrorLevel)
        return
    if newDelta is not number
    {
        MsgBox, 48, DGlider, Change per second must be numeric.
        return
    }

    InputBox, newPrefix, Debt OSD, Currency prefix (example: $):, , 360, 150,,,,, %DebtOSD_CurrencyPrefix%
    if (ErrorLevel)
        return

    InputBox, newSuffix, Debt OSD, Currency suffix (optional):, , 360, 150,,,,, %DebtOSD_CurrencySuffix%
    if (ErrorLevel)
        return

    DebtOSD_BaseAmount := newAmount + 0
    DebtOSD_DeltaPerSecond := newDelta + 0
    DebtOSD_CurrencyPrefix := newPrefix
    DebtOSD_CurrencySuffix := newSuffix
    DebtOSD_BaseTimestamp := A_Now
    DebtOSD_LastWholeSeconds := -1

    IniWrite, %DebtOSD_BaseAmount%, %A_ScriptDir%\gesture_config.ini, DebtOSD, InitialAmount
    IniWrite, %DebtOSD_DeltaPerSecond%, %A_ScriptDir%\gesture_config.ini, DebtOSD, DeltaPerSecond
    IniWrite, %DebtOSD_BaseTimestamp%, %A_ScriptDir%\gesture_config.ini, DebtOSD, BaseTimestamp
    IniWrite, %DebtOSD_CurrencyPrefix%, %A_ScriptDir%\gesture_config.ini, DebtOSD, CurrencyPrefix
    IniWrite, %DebtOSD_CurrencySuffix%, %A_ScriptDir%\gesture_config.ini, DebtOSD, CurrencySuffix

    if (DebtOSD_Visible)
        GoSub, DebtOSD_UpdateLoop

    Log("DebtOSD config updated: amount=" DebtOSD_BaseAmount " delta=" DebtOSD_DeltaPerSecond)
}

DebtOSD_GetCurrentAmount() {
    global DebtOSD_BaseAmount, DebtOSD_DeltaPerSecond

    elapsedWholeSeconds := DebtOSD_GetElapsedWholeSeconds()
    return DebtOSD_BaseAmount + (elapsedWholeSeconds * DebtOSD_DeltaPerSecond)
}

DebtOSD_GetElapsedWholeSeconds() {
    global DebtOSD_BaseTimestamp

    nowStamp := A_Now
    EnvSub, nowStamp, %DebtOSD_BaseTimestamp%, Seconds
    if nowStamp is not number
        return 0
    return Floor(nowStamp)
}

DebtOSD_FormatAmount(amount) {
    global DebtOSD_CurrencyPrefix, DebtOSD_CurrencySuffix, DebtOSD_Decimals

    sign := (amount < 0) ? "-" : ""
    absValue := Abs(amount)
    formattedAbs := Format("{:." DebtOSD_Decimals "f}", absValue)
    dotPos := InStr(formattedAbs, ".")

    if (dotPos > 0) {
        intPart := SubStr(formattedAbs, 1, dotPos - 1)
        fracPart := SubStr(formattedAbs, dotPos + 1)
        return sign . DebtOSD_CurrencyPrefix . DebtOSD_AddThousandsSeparators(intPart) . "." . fracPart . DebtOSD_CurrencySuffix
    }

    return sign . DebtOSD_CurrencyPrefix . DebtOSD_AddThousandsSeparators(formattedAbs) . DebtOSD_CurrencySuffix
}

DebtOSD_AddThousandsSeparators(intPart) {
    out := ""
    len := StrLen(intPart)

    Loop, %len%
    {
        idx := len - A_Index + 1
        digit := SubStr(intPart, idx, 1)
        if (A_Index > 1 && Mod(A_Index - 1, 3) = 0)
            out := "," . out
        out := digit . out
    }

    return out
}

DebtOSD_UpdateLoop:
    if (!DebtOSD_Visible)
        return

    elapsedWholeSeconds := DebtOSD_GetElapsedWholeSeconds()
    if (elapsedWholeSeconds = DebtOSD_LastWholeSeconds)
        return

    DebtOSD_LastWholeSeconds := elapsedWholeSeconds
    currentAmount := DebtOSD_GetCurrentAmount()
    GuiControl, DebtOSD:, DebtOSD_Value, % DebtOSD_FormatAmount(currentAmount)
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
+Space:: send _
