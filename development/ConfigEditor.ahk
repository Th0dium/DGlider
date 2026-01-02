#NoEnv
#SingleInstance Force
SendMode, Input
SetWorkingDir, %A_ScriptDir%

global ConfigFile := A_ScriptDir "\gesture_config.ini"
global CurrentHotkey := ""
global HotkeyList := []
global PendingChanges := {}

Gosub, BuildGUI
return

BuildGUI:
    Gui, Config:New, +Resize, DGlider Config Editor
    Gui, Config:Color, F0F0F0

    Gui, Config:Add, Text, x10 y10 w200, Buttons:
    Gui, Config:Add, ListBox, x10 y30 w200 h350 vHotkeyListBox gOnHotkeySelect, 

    Gui, Config:Add, GroupBox, x10 y390 w200 h80, Settings
    Gui, Config:Add, Text, x20 y410, Move Threshold:
    Gui, Config:Add, Edit, x20 y430 w80 vMoveThreshold Number
    Gui, Config:Add, UpDown, Range10-100, 30

    Gui, Config:Add, GroupBox, x220 y10 w380 h340, Button Properties

    Gui, Config:Add, Text, x230 y35, Button Mode:
    Gui, Config:Add, DropDownList, x330 y32 w150 vButtonMode gOnModeChange, Pull and Release|On Tap|Pull and Hold

    Gui, Config:Add, Text, x230 y65 vAimDelayLabel Hidden, Aim Delay (ms):
    Gui, Config:Add, Edit, x330 y62 w80 vAimDelay Number Hidden
    Gui, Config:Add, UpDown, vAimDelayUpDown Range50-1000 Hidden, 150

    Gui, Config:Add, GroupBox, x230 y105 w360 h210, Direction Actions

    yPos := 130
    Gui, Config:Add, Text, x250 y%yPos%, Up:
    Gui, Config:Add, Edit, x320 y%yPos% w260 vActionUp

    yPos += 30
    Gui, Config:Add, Text, x250 y%yPos%, Left:
    Gui, Config:Add, Edit, x320 y%yPos% w260 vActionLeft

    yPos += 30
    Gui, Config:Add, Text, x250 y%yPos%, Right:
    Gui, Config:Add, Edit, x320 y%yPos% w260 vActionRight

    yPos += 30
    Gui, Config:Add, Text, x250 y%yPos%, Down:
    Gui, Config:Add, Edit, x320 y%yPos% w260 vActionDown

    yPos += 30
    Gui, Config:Add, Text, x250 y%yPos%, Default:
    Gui, Config:Add, Edit, x320 y%yPos% w260 vActionDefault

    Gui, Config:Add, Button, x220 y380 w90 h35 gSaveConfig Default, Save Config
    Gui, Config:Add, Button, x320 y380 w90 h35 gReloadConfig, Reload
    Gui, Config:Add, Button, x420 y380 w90 h35 gAddHotkey, Add Button
    Gui, Config:Add, Button, x520 y380 w80 h35 gDeleteHotkey cRed, Delete

    Gui, Config:Add, Text, x220 y425 w380 cGray, Tip: Use {key} syntax for keys, ^=Ctrl !=Alt +=Shift #=Win

    LoadConfig()

    Gui, Config:Show, w610 h490
return

OnHotkeySelect:
    Gui, Config:Submit, NoHide

    if (CurrentHotkey != "") {
        SaveCurrentChanges()
    }

    GuiControlGet, selectedIndex, Config:, HotkeyListBox
    if (selectedIndex > 0) {
        GuiControlGet, selectedText, Config:, HotkeyListBox
        spacePos := InStr(selectedText, " ")
        if (spacePos > 0)
            CurrentHotkey := SubStr(selectedText, 1, spacePos - 1)
        else
            CurrentHotkey := selectedText
        LoadHotkeyData(CurrentHotkey)
    }
return

OnModeChange:
    Gui, Config:Submit, NoHide
    if (ButtonMode = "Pull and Hold") {
        GuiControl, Config:Show, AimDelayLabel
        GuiControl, Config:Show, AimDelay
        GuiControl, Config:Show, AimDelayUpDown
    } else {
        GuiControl, Config:Hide, AimDelayLabel
        GuiControl, Config:Hide, AimDelay
        GuiControl, Config:Hide, AimDelayUpDown
    }
return

SaveConfig:
    Gui, Config:Submit, NoHide

    if (CurrentHotkey = "") {
        MsgBox, 48, Warning, Please select a button first!
        return
    }

    SaveCurrentChanges()

    IniWrite, %MoveThreshold%, %ConfigFile%, Settings, MoveThreshold

    for hotkey, data in PendingChanges {
        section := "Hotkey_" . hotkey
        storedMode := ConvertModeToStored(data.mode)
        IniWrite, %storedMode%, %ConfigFile%, %section%, mode

        if (storedMode = "H") {
            IniWrite, % data.aim_delay, %ConfigFile%, %section%, aim_delay
        }

        IniWrite, % data.up, %ConfigFile%, %section%, up
        IniWrite, % data.down, %ConfigFile%, %section%, down
        IniWrite, % data.left, %ConfigFile%, %section%, left
        IniWrite, % data.right, %ConfigFile%, %section%, right
        IniWrite, % data.default, %ConfigFile%, %section%, default
    }

    PendingChanges := {}

    RefreshHotkeyList()
return

ReloadConfig:
    PendingChanges := {}

    LoadConfig()
    if (CurrentHotkey != "") {
        LoadHotkeyData(CurrentHotkey)
    }
return

AddHotkey:
    Gosub, OpenKeyDetectionDialog
return

DeleteHotkey:
    global CurrentHotkey, HotkeyList, ConfigFile

    if (CurrentHotkey = "") {
        MsgBox, 48, Warning, Please select a button first!
        return
    }

    MsgBox, 4, Confirm Delete, Delete button "%CurrentHotkey%"?
    if (ErrorLevel = 2)
        return

    for index, hk in HotkeyList {
        if (hk = CurrentHotkey) {
            HotkeyList.RemoveAt(index)
            break
        }
    }

    section := "Hotkey_" . CurrentHotkey
    IniDelete, %ConfigFile%, %section%

    CurrentHotkey := ""
    GuiControl, Config:, HotkeyListBox, 
    GuiControl, Config:, ActionUp, 
    GuiControl, Config:, ActionDown, 
    GuiControl, Config:, ActionLeft, 
    GuiControl, Config:, ActionRight, 
    GuiControl, Config:, ActionDefault, 

    RefreshHotkeyList()
return

OpenKeyDetectionDialog:
    global DetectedKey, DetectCtrl, DetectShift, DetectAlt, DetectWin

    DetectedKey := ""
    DetectCtrl := 0
    DetectShift := 0
    DetectAlt := 0
    DetectWin := 0

    Gui, KeyDetect:New, +AlwaysOnTop, Key Detection
    Gui, KeyDetect:Color, F0F0F0

    Gui, KeyDetect:Add, Text, x20 y15 w260 h40 cBlue, Press a button or key...
    Gui, KeyDetect:Add, Edit, x20 y60 w260 h35 vDetectedKeyDisplay cGray ReadOnly

    Gui, KeyDetect:Add, Text, x20 y105 w260, Modifiers:
    Gui, KeyDetect:Add, CheckBox, x20 y125 w60 vDetectCtrl, Ctrl
    Gui, KeyDetect:Add, CheckBox, x90 y125 w60 vDetectShift, Shift
    Gui, KeyDetect:Add, CheckBox, x160 y125 w60 vDetectAlt, Alt
    Gui, KeyDetect:Add, CheckBox, x230 y125 w50 vDetectWin, Win

    Gui, KeyDetect:Add, Button, x20 y165 w120 h35 gConfirmKey Default, Confirm
    Gui, KeyDetect:Add, Button, x150 y165 w130 h35 gCancelKey, Cancel

    Gui, KeyDetect:Add, Text, x20 y210 w260 cGray, Press any button/key below
    Gui, KeyDetect:Add, Text, x20 y228 w260 cGray, to detect it, then confirm

    Gui, KeyDetect:Show, w300 h280

    gosub, StartKeyListener
return

StartKeyListener:
    global DetectedKey, DetectedKeyDisplay

    Hotkey, RButton, OnKeyDetected, On
    Hotkey, MButton, OnKeyDetected, On
    Hotkey, XButton1, OnKeyDetected, On
    Hotkey, XButton2, OnKeyDetected, On

    Loop, 26 {
        key := Chr(64 + A_Index)
        Hotkey, %key%, OnKeyDetected, On
    }

    Loop, 10 {
        key := A_Index - 1
        Hotkey, %key%, OnKeyDetected, On
    }

    Loop, 12 {
        key := "F" . A_Index
        Hotkey, %key%, OnKeyDetected, On
    }

    specialKeys := ["Space", "Enter", "Escape", "Tab", "BackSpace", "Delete", "Insert", "Home", "End", "PgUp", "PgDn", "Up", "Down", "Left", "Right", "PrintScreen", "Pause", "CapsLock", "NumLock", "ScrollLock"]
    for index, key in specialKeys {
        Hotkey, %key%, OnKeyDetected, On
    }
return

OnKeyDetected:
    global DetectedKey, DetectCtrl, DetectShift, DetectAlt, DetectWin, DetectedKeyDisplay

    DetectedKey := A_ThisHotkey

    displayStr := ""
    if (GetKeyState("LCtrl") || GetKeyState("RCtrl")) {
        displayStr .= "Ctrl + "
        DetectCtrl := 1
    }
    if (GetKeyState("LShift") || GetKeyState("RShift")) {
        displayStr .= "Shift + "
        DetectShift := 1
    }
    if (GetKeyState("LAlt") || GetKeyState("RAlt")) {
        displayStr .= "Alt + "
        DetectAlt := 1
    }
    if (GetKeyState("LWin") || GetKeyState("RWin")) {
        displayStr .= "Win + "
        DetectWin := 1
    }
    displayStr .= DetectedKey

    GuiControl, KeyDetect:, DetectedKeyDisplay, %displayStr%
return

ConfirmKey:
    global DetectedKey, HotkeyList, ConfigFile

    Gui, KeyDetect:Submit, NoHide

    if (DetectedKey = "") {
        MsgBox, 48, Error, Please detect a key first!
        return
    }

    finalHotkey := ""
    if (DetectCtrl)
        finalHotkey .= "^"
    if (DetectShift)
        finalHotkey .= "+"
    if (DetectAlt)
        finalHotkey .= "!"
    if (DetectWin)
        finalHotkey .= "#"
    finalHotkey .= "{" . DetectedKey . "}"

    normalizedHotkey := finalHotkey

    found := false
    for index, hk in HotkeyList {
        if (hk = normalizedHotkey) {
            found := true
            break
        }
    }

    if (!found) {
        HotkeyList.Push(normalizedHotkey)
        RefreshHotkeyList()

        FileAppend, `n, %ConfigFile%
        section := "Hotkey_" . normalizedHotkey
        IniWrite, R, %ConfigFile%, %section%, mode
        IniWrite, %A_Space%, %ConfigFile%, %section%, up
        IniWrite, %A_Space%, %ConfigFile%, %section%, down
        IniWrite, %A_Space%, %ConfigFile%, %section%, left
        IniWrite, %A_Space%, %ConfigFile%, %section%, right
        IniWrite, %normalizedHotkey%, %ConfigFile%, %section%, default
    } else {
        MsgBox, 48, Info, Button already exists!
        return
    }

    gosub, CancelKey
return

CancelKey:
    gosub, StopKeyListener
    Gui, KeyDetect:Destroy
return

StopKeyListener:
    Hotkey, RButton, Off
    Hotkey, MButton, Off
    Hotkey, XButton1, Off
    Hotkey, XButton2, Off

    Loop, 26 {
        key := Chr(64 + A_Index)
        Hotkey, %key%, Off
    }

    Loop, 10 {
        key := A_Index - 1
        Hotkey, %key%, Off
    }

    Loop, 12 {
        key := "F" . A_Index
        Hotkey, %key%, Off
    }

    specialKeys := ["Space", "Enter", "Escape", "Tab", "BackSpace", "Delete", "Insert", "Home", "End", "PgUp", "PgDn", "Up", "Down", "Left", "Right", "PrintScreen", "Pause", "CapsLock", "NumLock", "ScrollLock"]
    for index, key in specialKeys {
        Hotkey, %key%, Off
    }
return

KeyDetectGuiClose:
KeyDetectGuiEscape:
    gosub, StopKeyListener
    Gui, KeyDetect:Destroy
return

ConfigGuiClose:
ConfigGuiEscape:
ExitApp
return

SaveCurrentChanges() {
    global CurrentHotkey, PendingChanges, ButtonMode, AimDelay
    global ActionUp, ActionDown, ActionLeft, ActionRight, ActionDefault

    if (CurrentHotkey = "")
        return

    if (!PendingChanges.HasKey(CurrentHotkey))
        PendingChanges[CurrentHotkey] := {}

    PendingChanges[CurrentHotkey].mode := ConvertModeToStored(ButtonMode)
    PendingChanges[CurrentHotkey].aim_delay := AimDelay
    PendingChanges[CurrentHotkey].up := ActionUp
    PendingChanges[CurrentHotkey].down := ActionDown
    PendingChanges[CurrentHotkey].left := ActionLeft
    PendingChanges[CurrentHotkey].right := ActionRight
    PendingChanges[CurrentHotkey].default := ActionDefault
}

LoadConfig() {
    global ConfigFile, HotkeyList, MoveThreshold

    IniRead, threshold, %ConfigFile%, Settings, MoveThreshold, 30
    GuiControl, Config:, MoveThreshold, %threshold%

    HotkeyList := []

    IniRead, sections, %ConfigFile%
    Loop, Parse, sections, `n
    {
        if (InStr(A_LoopField, "Hotkey_") = 1) {
            hotkey := SubStr(A_LoopField, 8)
            HotkeyList.Push(hotkey)
        }
    }

    RefreshHotkeyList()
}

RefreshHotkeyList() {
    global HotkeyList, ConfigFile

    listStr := ""
    for index, hk in HotkeyList {
        listStr .= hk "|"
    }

    GuiControl, Config:, HotkeyListBox, |%listStr%
}

LoadHotkeyData(hotkey) {
    global ConfigFile, PendingChanges

    spacePos := InStr(hotkey, " ")
    if (spacePos > 0)
        hotkey := SubStr(hotkey, 1, spacePos - 1)

    hotkey := Trim(hotkey)
    section := "Hotkey_" . hotkey

    if (PendingChanges.HasKey(hotkey)) {
        mode := PendingChanges[hotkey].mode
        aimDelay := PendingChanges[hotkey].aim_delay
        up := PendingChanges[hotkey].up
        down := PendingChanges[hotkey].down
        left := PendingChanges[hotkey].left
        right := PendingChanges[hotkey].right
        def := PendingChanges[hotkey].default
    } else {
        IniRead, mode, %ConfigFile%, %section%, mode, gesture
        IniRead, aimDelay, %ConfigFile%, %section%, aim_delay, 150
        IniRead, up, %ConfigFile%, %section%, up, %A_Space%
        IniRead, down, %ConfigFile%, %section%, down, %A_Space%
        IniRead, left, %ConfigFile%, %section%, left, %A_Space%
        IniRead, right, %ConfigFile%, %section%, right, %A_Space%
        IniRead, def, %ConfigFile%, %section%, default, %A_Space%

        up := Trim(up)
        down := Trim(down)
        left := Trim(left)
        right := Trim(right)
        def := Trim(def)
    }

    displayMode := ConvertModeToDisplay(mode)

    GuiControl, Config:ChooseString, ButtonMode, %displayMode%
    GuiControl, Config:, AimDelay, %aimDelay%

    if (displayMode = "Pull and Hold") {
        GuiControl, Config:Show, AimDelayLabel
        GuiControl, Config:Show, AimDelay
        GuiControl, Config:Show, AimDelayUpDown
    } else {
        GuiControl, Config:Hide, AimDelayLabel
        GuiControl, Config:Hide, AimDelay
        GuiControl, Config:Hide, AimDelayUpDown
    }

    GuiControl, Config:, ActionUp, %up%
    GuiControl, Config:, ActionDown, %down%
    GuiControl, Config:, ActionLeft, %left%
    GuiControl, Config:, ActionRight, %right%
    GuiControl, Config:, ActionDefault, %def%
}

ConvertModeToDisplay(storedMode) {
    if (storedMode = "R")
        return "Pull and Release"
    else if (storedMode = "T")
        return "On Tap"
    else if (storedMode = "H")
        return "Pull and Hold"
    else
        return "Pull and Release"
}

ConvertModeToStored(displayMode) {
    if (displayMode = "Pull and Release")
        return "R"
    else if (displayMode = "On Tap")
        return "T"
    else if (displayMode = "Pull and Hold")
        return "H"
    else
        return "R"
}
