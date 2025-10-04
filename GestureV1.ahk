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

; Initialize gesture hotkeys based on current profile
SetupMouseButtonHotkeys()

;--------------------------------- Key pickup ------------------------------------

; Labels for dynamic hotkeys (Ctrl+Alt+1..8)
HK_CTRLALT_1:
    HandleMouseAction("^!1")
return

HK_CTRLALT_2:
    HandleMouseAction("^!2")
return

HK_CTRLALT_3:
    HandleMouseAction("^!3")
return

HK_CTRLALT_4:
    HandleMouseAction("^!4")
return

HK_CTRLALT_5:
    HandleMouseAction("^!5")
return

HK_CTRLALT_6:
    HandleMouseAction("^!6")
return

HK_CTRLALT_7:
    HandleMouseAction("^!7")
return

HK_CTRLALT_8:
    HandleMouseAction("^!8")
return

; Mouse button gestures (managed dynamically by profile)
; Bindings are set via SetupMouseButtonHotkeys/ApplyProfileHotkeys.
; Labels for handlers are defined here:

MBUTTON_HOTKEY:
    HandleMouseAction("{mbutton}")
return

RBUTTON_HOTKEY:
    HandleMouseAction("{rbutton}")
return

; Navigation buttons (dynamic)
XBUTTON1_HOTKEY:
    HandleMouseAction("{xbutton1}")
return

XBUTTON2_HOTKEY:
    HandleMouseAction("{xbutton2}")
return

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
    ; Mouse buttons
    Hotkey, MButton, MBUTTON_HOTKEY
    Hotkey, RButton, RBUTTON_HOTKEY
    ; Navigation buttons
    Hotkey, XButton1, XBUTTON1_HOTKEY
    Hotkey, XButton2, XBUTTON2_HOTKEY
    ; Ctrl+Alt+1..8
    Hotkey, ^!1, HK_CTRLALT_1
    Hotkey, ^!2, HK_CTRLALT_2
    Hotkey, ^!3, HK_CTRLALT_3
    Hotkey, ^!4, HK_CTRLALT_4
    Hotkey, ^!5, HK_CTRLALT_5
    Hotkey, ^!6, HK_CTRLALT_6
    Hotkey, ^!7, HK_CTRLALT_7
    Hotkey, ^!8, HK_CTRLALT_8
    ApplyProfileHotkeys()
}

ApplyProfileHotkeys() {
    global ActiveProfile
    disabled := GetProfileDisabledKeys(ActiveProfile)
    ; Mouse buttons
    Hotkey, MButton, % ShouldDisable(disabled, "{mbutton}") ? "Off" : "On"
    Hotkey, RButton, % ShouldDisable(disabled, "{rbutton}") ? "Off" : "On"
    ; Navigation buttons
    Hotkey, XButton1, % ShouldDisable(disabled, "{xbutton1}") ? "Off" : "On"
    Hotkey, XButton2, % ShouldDisable(disabled, "{xbutton2}") ? "Off" : "On"
    ; Ctrl+Alt+1..8
    Hotkey, ^!1, % ShouldDisable(disabled, "^!1") ? "Off" : "On"
    Hotkey, ^!2, % ShouldDisable(disabled, "^!2") ? "Off" : "On"
    Hotkey, ^!3, % ShouldDisable(disabled, "^!3") ? "Off" : "On"
    Hotkey, ^!4, % ShouldDisable(disabled, "^!4") ? "Off" : "On"
    Hotkey, ^!5, % ShouldDisable(disabled, "^!5") ? "Off" : "On"
    Hotkey, ^!6, % ShouldDisable(disabled, "^!6") ? "Off" : "On"
    Hotkey, ^!7, % ShouldDisable(disabled, "^!7") ? "Off" : "On"
    Hotkey, ^!8, % ShouldDisable(disabled, "^!8") ? "Off" : "On"
}

ShouldDisable(disabledList, key) {
    ; disabledList: comma-separated list (case-insensitive match)
    ; key: literal like "^!1" or "{mbutton}"
    StringLower, lk, key
    StringLower, dl, disabledList
    return InStr("," dl ",", "," lk ",")
}

; Return a comma-separated, lowercase list of disabled keys for a given profile
GetProfileDisabledKeys(profile) {
    IniRead, raw, %A_ScriptDir%\gesture_config.ini, Profile_%profile%_Disabled, Keys,
    if (raw = "")
        return ""
    ; normalize separators and spaces, to lowercase
    raw := StrReplace(raw, "|", ",")
    raw := StrReplace(raw, ";", ",")
    raw := StrReplace(raw, A_Space, "")
    StringLower, raw, raw
    return raw
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
