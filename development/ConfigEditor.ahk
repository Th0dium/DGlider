;------------------------------------- Config Editor GUI -------------------------------------
#NoEnv
#SingleInstance Force
SendMode, Input
SetWorkingDir, %A_ScriptDir%

; Global variables
global ConfigFile := A_ScriptDir "\gesture_config.ini"
global CurrentHotkey := ""
global HotkeyList := []

; Launch GUI
Gosub, BuildGUI
return

;------------------------------------- GUI Construction -------------------------------------

BuildGUI:
    Gui, Config:New, +Resize, DGlider Config Editor
    Gui, Config:Color, F0F0F0

    ; Left Panel - Button List
    Gui, Config:Add, Text, x10 y10 w200, Buttons:
    Gui, Config:Add, ListBox, x10 y30 w200 h400 vHotkeyListBox gOnHotkeySelect, 

    ; Settings Section
    Gui, Config:Add, GroupBox, x10 y440 w200 h80, Settings
    Gui, Config:Add, Text, x20 y460, Move Threshold:
    Gui, Config:Add, Edit, x20 y480 w80 vMoveThreshold Number
    Gui, Config:Add, UpDown, Range10-100, 30

    ; Right Panel - Button Properties
    Gui, Config:Add, GroupBox, x220 y10 w380 h320, Button Properties

    ; Button Mode
    Gui, Config:Add, Text, x230 y35, Button Mode:
    Gui, Config:Add, DropDownList, x330 y32 w150 vButtonMode gOnModeChange, gesture||click|aim

    ; Aim Delay (only for aim mode)
    Gui, Config:Add, Text, x230 y65 vAimDelayLabel Hidden, Aim Delay (ms):
    Gui, Config:Add, Edit, x330 y62 w80 vAimDelay Number Hidden
    Gui, Config:Add, UpDown, vAimDelayUpDown Range50-1000 Hidden, 150

    ; Gesture Directions
    Gui, Config:Add, GroupBox, x230 y95 w360 h220, Direction Actions

    ; Direction inputs
    yPos := 120
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

    ; Preview/Test Section
    Gui, Config:Add, GroupBox, x220 y340 w380 h100, Testing
    Gui, Config:Add, Text, x230 y365, Test your gestures here:
    Gui, Config:Add, Button, x230 y390 w150 h30 gTestGesture, Test Gesture Mode
    Gui, Config:Add, Text, x390 y395 w200 vTestStatus cGray, Ready

    ; Action Buttons
    Gui, Config:Add, Button, x220 y450 w120 h35 gSaveConfig Default, Save Config
    Gui, Config:Add, Button, x350 y450 w120 h35 gReloadConfig, Reload
    Gui, Config:Add, Button, x480 y450 w120 h35 gAddHotkey, Add Button

    ; Help text
    Gui, Config:Add, Text, x220 y495 w380 cGray, Tip: Use {key} syntax for keys, ^=Ctrl !=Alt +=Shift #=Win

    ; Load initial data
    LoadConfig()

    Gui, Config:Show, w610 h530
return

;------------------------------------- Event Handlers -------------------------------------

OnHotkeySelect:
    Gui, Config:Submit, NoHide
    GuiControlGet, selectedIndex, Config:, HotkeyListBox
    if (selectedIndex > 0) {
        ; Get the actual selected text from the ListBox
        GuiControlGet, selectedText, Config:, HotkeyListBox
        ; Extract just the hotkey name (before the first space)
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
    if (ButtonMode = "aim") {
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

    ; Save settings
    IniWrite, %MoveThreshold%, %ConfigFile%, Settings, MoveThreshold

    ; Save hotkey config
    section := "Hotkey_" . CurrentHotkey
    IniWrite, %ButtonMode%, %ConfigFile%, %section%, mode

    if (ButtonMode = "aim") {
        IniWrite, %AimDelay%, %ConfigFile%, %section%, aim_delay
    }

    IniWrite, %ActionUp%, %ConfigFile%, %section%, up
    IniWrite, %ActionDown%, %ConfigFile%, %section%, down
    IniWrite, %ActionLeft%, %ConfigFile%, %section%, left
    IniWrite, %ActionRight%, %ConfigFile%, %section%, right
    IniWrite, %ActionDefault%, %ConfigFile%, %section%, default

    GuiControl, Config:, TestStatus, ✓ Saved successfully!

    ; Refresh list to update action counts
    RefreshHotkeyList()

    SetTimer, ClearStatus, -2000
return

ReloadConfig:
    LoadConfig()
    if (CurrentHotkey != "") {
        LoadHotkeyData(CurrentHotkey)
    }
    GuiControl, Config:, TestStatus, ✓ Config reloaded
    SetTimer, ClearStatus, -2000
return

AddHotkey:
    InputBox, newHotkey, Add Button, Enter button name (e.g. {rbutton}, {xbutton1}):, , 350, 150
    if (ErrorLevel = 0 && newHotkey != "") {
        ; Add to list if not exists
        found := false
        for index, hk in HotkeyList {
            if (hk = newHotkey) {
                found := true
                break
            }
        }

        if (!found) {
            HotkeyList.Push(newHotkey)
            RefreshHotkeyList()

            ; Set defaults
            section := "Hotkey_" . newHotkey
            IniWrite, gesture, %ConfigFile%, %section%, mode
            IniWrite, %A_Space%, %ConfigFile%, %section%, up
            IniWrite, %A_Space%, %ConfigFile%, %section%, down
            IniWrite, %A_Space%, %ConfigFile%, %section%, left
            IniWrite, %A_Space%, %ConfigFile%, %section%, right
            IniWrite, %newHotkey%, %ConfigFile%, %section%, default

            GuiControl, Config:, TestStatus, ✓ Button added
            SetTimer, ClearStatus, -2000
        } else {
            MsgBox, 48, Info, Button already exists!
        }
    }
return

TestGesture:
    GuiControl, Config:, TestStatus, Testing... perform a gesture

    ; Start gesture test
    Hotkey, RButton, TestGestureHandler, On
    Hotkey, XButton1, TestGestureHandler, On
    Hotkey, XButton2, TestGestureHandler, On

    ; Auto-disable after 10 seconds
    SetTimer, DisableGestureTest, -10000
return

TestGestureHandler:
    testHotkey := "{" A_ThisHotkey "}"

    MouseGetPos, tx0, ty0
    KeyWait, %A_ThisHotkey%
    MouseGetPos, tx1, ty1

    tdx := tx1 - tx0
    tdy := ty1 - ty0

    ; Determine direction
    threshold := 30
    if (Abs(tdx) > Abs(tdy)) {
        if (tdx > threshold)
            tdir := "right"
        else if (tdx < -threshold)
            tdir := "left"
        else
            tdir := "default"
    } else {
        if (tdy > threshold)
            tdir := "down"
        else if (tdy < -threshold)
            tdir := "up"
        else
            tdir := "default"
    }

    result := testHotkey " - " tdir " (dx:" tdx " dy:" tdy ")"
    GuiControl, Config:, TestStatus, %result%

    Gosub, DisableGestureTest
return

DisableGestureTest:
    Hotkey, RButton, Off
    Hotkey, XButton1, Off
    Hotkey, XButton2, Off
return

ClearStatus:
    GuiControl, Config:, TestStatus, Ready
return

ConfigGuiClose:
ConfigGuiEscape:
ExitApp
return

;------------------------------------- Helper Functions -------------------------------------

LoadConfig() {
    global ConfigFile, HotkeyList, MoveThreshold

    ; Load settings
    IniRead, threshold, %ConfigFile%, Settings, MoveThreshold, 30
    GuiControl, Config:, MoveThreshold, %threshold%

    ; Scan for hotkeys
    HotkeyList := []

    ; Read all sections
    IniRead, sections, %ConfigFile%
    Loop, Parse, sections, `n
    {
        if (InStr(A_LoopField, "Hotkey_") = 1) {
            hotkey := SubStr(A_LoopField, 8) ; Remove "Hotkey_" prefix
            HotkeyList.Push(hotkey)
        }
    }

    RefreshHotkeyList()
}

RefreshHotkeyList() {
    global HotkeyList, ConfigFile

    ; Build list string with mode indicators
    listStr := ""
    for index, hk in HotkeyList {
        section := "Hotkey_" . hk
        IniRead, mode, %ConfigFile%, %section%, mode, gesture

        ; Count assigned actions
        actionCount := 0
        IniRead, val, %ConfigFile%, %section%, up
        if (val != "" && val != " ")
            actionCount++
        IniRead, val, %ConfigFile%, %section%, down
        if (val != "" && val != " ")
            actionCount++
        IniRead, val, %ConfigFile%, %section%, left
        if (val != "" && val != " ")
            actionCount++
        IniRead, val, %ConfigFile%, %section%, right
        if (val != "" && val != " ")
            actionCount++
        IniRead, val, %ConfigFile%, %section%, default
        if (val != "" && val != " ")
            actionCount++

        ; Format: {button} [mode] (actions)
        modeShort := SubStr(mode, 1, 1) ; g/c/a
        listStr .= hk " [" modeShort "] (" actionCount ")|"
    }

    GuiControl, Config:, HotkeyListBox, |%listStr%
}

LoadHotkeyData(hotkey) {
    global ConfigFile

    ; Strip any formatting like " [g] (5)" - only keep text before first space
    spacePos := InStr(hotkey, " ")
    if (spacePos > 0)
        hotkey := SubStr(hotkey, 1, spacePos - 1)

    ; Trim any whitespace and construct section name
    hotkey := Trim(hotkey)
    section := "Hotkey_" . hotkey

    ; Load mode
    IniRead, mode, %ConfigFile%, %section%, mode, gesture
    GuiControl, Config:ChooseString, ButtonMode, %mode% ; Load aim delay if aim mode
    IniRead, aimDelay, %ConfigFile%, %section%, aim_delay, 150
    GuiControl, Config:, AimDelay, %aimDelay%

    ; Show/hide aim controls
    if (mode = "aim") {
        GuiControl, Config:Show, AimDelayLabel
        GuiControl, Config:Show, AimDelay
        GuiControl, Config:Show, AimDelayUpDown
    } else {
        GuiControl, Config:Hide, AimDelayLabel
        GuiControl, Config:Hide, AimDelay
        GuiControl, Config:Hide, AimDelayUpDown
    }

    ; Load actions - provide explicit empty default for missing keys
    IniRead, up, %ConfigFile%, %section%, up, %A_Space%
    IniRead, down, %ConfigFile%, %section%, down, %A_Space%
    IniRead, left, %ConfigFile%, %section%, left, %A_Space%
    IniRead, right, %ConfigFile%, %section%, right, %A_Space%
    IniRead, def, %ConfigFile%, %section%, default, %A_Space%

    ; Trim to remove the space if it's the default
    up := Trim(up)
    down := Trim(down)
    left := Trim(left)
    right := Trim(right)
    def := Trim(def)

    GuiControl, Config:, ActionUp, %up%
    GuiControl, Config:, ActionDown, %down%
    GuiControl, Config:, ActionLeft, %left%
    GuiControl, Config:, ActionRight, %right%
    GuiControl, Config:, ActionDefault, %def%

    GuiControl, Config:, TestStatus, Loaded: %hotkey%
    SetTimer, ClearStatus, -2000
}
