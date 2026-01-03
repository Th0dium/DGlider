; ============================================================================
; DGlider Configuration Editor
; ============================================================================
; A GUI tool for managing gesture button configurations.
; Allows users to add, edit, and delete button mappings with directional actions.
; ============================================================================

#NoEnv
#SingleInstance Force
SendMode, Input
SetWorkingDir, %A_ScriptDir%

; ----------------------------------------------------------------------------
; Global Variables
; ----------------------------------------------------------------------------
global ConfigFile := A_ScriptDir "\gesture_config.ini"
global CurrentHotkey := "" ; Currently selected button in the list
global HotkeyList := [] ; Array of all configured buttons
global PendingChanges := {} ; Unsaved changes (stored as mode codes: R/T/H)
global HotkeyListBoxHwnd := "" ; Handle for ListBox control

Gosub, BuildGUI
return

; ============================================================================
; GUI CONSTRUCTION
; ============================================================================

BuildGUI:
    Gui, Config:New, +Resize, DGlider Config Editor
    Gui, Config:Color, F0F0F0

    ; --- Left Panel: Button List ---
    Gui, Config:Add, Text, x10 y10 w200, Buttons:
    Gui, Config:Add, ListBox, x10 y30 w200 h350 vHotkeyListBox gOnHotkeySelect +HwndHotkeyListBoxHwnd, 

    ; --- Left Panel: Global Settings ---
    Gui, Config:Add, GroupBox, x10 y390 w200 h80, Settings
    Gui, Config:Add, Text, x20 y410, Move Threshold:
    Gui, Config:Add, Edit, x20 y430 w80 vMoveThreshold Number
    Gui, Config:Add, UpDown, Range10-100, 30
    Gui, Config:Add, Button, x115 y428 w85 h25 gRearrangeButtons, Rearrange

    ; --- Right Panel: Button Properties ---
    Gui, Config:Add, GroupBox, x220 y10 w380 h340, Button Properties

    ; Mode Selection (R=Pull and Release, T=On Tap, H=Pull and Hold)
    Gui, Config:Add, Text, x230 y35, Button Mode:
    Gui, Config:Add, DropDownList, x330 y32 w150 vButtonMode gOnModeChange, Pull and Release|On Tap|Pull and Hold

    ; (Normalization moved to ConfirmKey - keep GUI construction focused on controls)
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

    ; --- Action Buttons ---
    Gui, Config:Add, Button, x220 y380 w90 h35 gSaveConfig Default, Save Config
    Gui, Config:Add, Button, x320 y380 w90 h35 gReloadConfig, Reload
    Gui, Config:Add, Button, x420 y380 w90 h35 gAddHotkey, Add Button
    Gui, Config:Add, Button, x520 y380 w80 h35 gDeleteHotkey cRed, Delete

    ; --- Help Text ---
    Gui, Config:Add, Text, x220 y425 w380 cGray, Tip: Use {key} syntax for keys, ^=Ctrl !=Alt +=Shift #=Win

    LoadConfig()

    Gui, Config:Show, w610 h490
return

; ============================================================================
; EVENT HANDLERS
; ============================================================================

; Called when user selects a button from the list
OnHotkeySelect:
    Gui, Config:Submit, NoHide

    ; Save any pending changes for the previously selected button
    if (CurrentHotkey != "") {
        SaveCurrentChanges()
    }

    ; Get selected index using SendMessage (more reliable than GuiControlGet for ListBox)
    ; LB_GETCURSEL = 0x188, returns 0-based index or -1 if none selected
    SendMessage, 0x188, 0, 0,, ahk_id %HotkeyListBoxHwnd%
    selectedIndex := ErrorLevel

    if (selectedIndex != 0xFFFFFFFF && selectedIndex < HotkeyList.Count()) {
        ; Use HotkeyList array directly instead of parsing ListBox text
        ; This avoids issues with special characters like +, !, #, ^
        CurrentHotkey := HotkeyList[selectedIndex + 1] ; Array is 1-based

        ; Load the hotkey data
        LoadHotkeyData(CurrentHotkey)
    }
return

; Called when user changes the button mode dropdown
; Shows/hides AimDelay control based on mode
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

; ============================================================================
; SAVE / RELOAD OPERATIONS
; ============================================================================

; Save all pending changes to the INI file
SaveConfig:
    Gui, Config:Submit, NoHide

    if (CurrentHotkey = "") {
        MsgBox, 48, Warning, Please select a button first!
        return
    }

    SaveCurrentChanges()

    ; Save global settings
    IniWrite, %MoveThreshold%, %ConfigFile%, Settings, MoveThreshold

    ; Save each button's configuration
    for hotkey, data in PendingChanges {
        section := "Hotkey_" . hotkey
        storedMode := ConvertModeToStored(data.mode)
        IniWrite, %storedMode%, %ConfigFile%, %section%, mode

        ; Only save aim_delay for "Pull and Hold" mode
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

; Discard all pending changes and reload from INI file
ReloadConfig:
    PendingChanges := {}

    LoadConfig()
    if (CurrentHotkey != "") {
        LoadHotkeyData(CurrentHotkey)
    }
return

; ============================================================================
; ADD / DELETE BUTTON OPERATIONS
; ============================================================================

AddHotkey:
    Gosub, OpenKeyDetectionDialog
return

; Delete the currently selected button
DeleteHotkey:
    global CurrentHotkey, HotkeyList, ConfigFile

    if (CurrentHotkey = "") {
        MsgBox, 48, Warning, Please select a button first!
        return
    }

    MsgBox, 4, Confirm Delete, Delete button "%CurrentHotkey%"?
    ; Use IfMsgBox to correctly detect the 'No' response (otherwise numeric ErrorLevel
    ; comparisons can be unreliable depending on AHK version/options).
    IfMsgBox, No
return

; Remove from HotkeyList array
for index, hk in HotkeyList {
    if (hk = CurrentHotkey) {
        HotkeyList.RemoveAt(index)
        break
    }
}

; Delete from INI file
section := "Hotkey_" . CurrentHotkey
IniDelete, %ConfigFile%, %section%

; Clear the form
CurrentHotkey := ""
GuiControl, Config:, HotkeyListBox, 
GuiControl, Config:, ActionUp, 
GuiControl, Config:, ActionDown, 
GuiControl, Config:, ActionLeft, 
GuiControl, Config:, ActionRight, 
GuiControl, Config:, ActionDefault, 

RefreshHotkeyList()
return

; ============================================================================
; REARRANGE BUTTONS
; ============================================================================

; Opens a dialog to rearrange button order
RearrangeButtons:
    global HotkeyList, ConfigFile

    if (HotkeyList.Count() <= 1) {
        MsgBox, 48, Info, You need at least 2 buttons to rearrange!
        return
    }

    Gui, Rearrange:New, +AlwaysOnTop, Rearrange Buttons
    Gui, Rearrange:Color, F0F0F0

    Gui, Rearrange:Add, Text, x10 y10 w280, Drag items to rearrange order:
    Gui, Rearrange:Add, ListBox, x10 y35 w280 h200 vRearrangeListBox, 

    Gui, Rearrange:Add, Button, x10 y245 w60 h30 gRearrangeMoveUp, Move Up
    Gui, Rearrange:Add, Button, x75 y245 w70 h30 gRearrangeMoveDown, Move Down
    Gui, Rearrange:Add, Button, x150 y245 w60 h30 gRearrangeApply Default, Apply
    Gui, Rearrange:Add, Button, x215 y245 w75 h30 gRearrangeCancel, Cancel

    ; Populate list
    listStr := ""
    for index, hk in HotkeyList {
        listStr .= hk "|"
    }
    GuiControl, Rearrange:, RearrangeListBox, |%listStr%

    Gui, Rearrange:Show, w300 h290
return

; Move selected item up
RearrangeMoveUp:
    GuiControlGet, selectedIndex, Rearrange:, RearrangeListBox
    if (selectedIndex <= 1) {
        MsgBox, 48, Info, Cannot move first item up!
        return
    }

    ; Get the item
    GuiControl, Rearrange:, RearrangeListBox, -Redraw
    GuiControlGet, item, Rearrange:, RearrangeListBox

    ; Update array
    temp := HotkeyList[selectedIndex]
    HotkeyList[selectedIndex] := HotkeyList[selectedIndex - 1]
    HotkeyList[selectedIndex - 1] := temp

    ; Refresh list
    listStr := ""
    for index, hk in HotkeyList {
        listStr .= hk "|"
    }
    GuiControl, Rearrange:, RearrangeListBox, |%listStr%
    GuiControl, Rearrange:, RearrangeListBox, +Redraw
    GuiControl, Rearrange:Choose, RearrangeListBox, % selectedIndex - 1
return

; Move selected item down
RearrangeMoveDown:
    GuiControlGet, selectedIndex, Rearrange:, RearrangeListBox
    if (selectedIndex >= HotkeyList.Count()) {
        MsgBox, 48, Info, Cannot move last item down!
        return
    }

    ; Update array
    temp := HotkeyList[selectedIndex]
    HotkeyList[selectedIndex] := HotkeyList[selectedIndex + 1]
    HotkeyList[selectedIndex + 1] := temp

    ; Refresh list
    listStr := ""
    for index, hk in HotkeyList {
        listStr .= hk "|"
    }
    GuiControl, Rearrange:, RearrangeListBox, |%listStr%
    GuiControl, Rearrange:Choose, RearrangeListBox, % selectedIndex + 1
return

; Apply new order to INI file
RearrangeApply:
    global HotkeyList, ConfigFile, PendingChanges

    ; Get all data from INI first
    buttonData := {}
    for index, hotkey in HotkeyList {
        section := "Hotkey_" . hotkey

        IniRead, mode, %ConfigFile%, %section%, mode, R
        IniRead, aimDelay, %ConfigFile%, %section%, aim_delay, 150
        IniRead, up, %ConfigFile%, %section%, up, %A_Space%
        IniRead, down, %ConfigFile%, %section%, down, %A_Space%
        IniRead, left, %ConfigFile%, %section%, left, %A_Space%
        IniRead, right, %ConfigFile%, %section%, right, %A_Space%
        IniRead, def, %ConfigFile%, %section%, default, %A_Space%

        buttonData[hotkey] := {mode: mode, aim_delay: aimDelay, up: up, down: down, left: left, right: right, default: def}
    }

    ; Rebuild INI file by deleting and rewriting sections in new order
    fileContent := ""
    IniRead, fileContent, %ConfigFile%

    ; Get settings section
    IniRead, settings, %ConfigFile%, Settings

    ; Rewrite entire file with new button order
    tempFile := ConfigFile . ".tmp"
    FileDelete, %tempFile%
    FileAppend, [Settings]`n, %tempFile%
    IniRead, moveThreshold, %ConfigFile%, Settings, MoveThreshold, 30
    FileAppend, MoveThreshold=%moveThreshold%`n`n, %tempFile%

    ; Append buttons in new order
    for index, hotkey in HotkeyList {
        data := buttonData[hotkey]
        section := "Hotkey_" . hotkey
        mode := data.mode
        aimDelay := data.aim_delay
        up := data.up
        down := data.down
        left := data.left
        right := data.right
        def := data.default

        FileAppend, [%section%]`n, %tempFile%
        FileAppend, mode=%mode%`n, %tempFile%
        FileAppend, aim_delay=%aimDelay%`n, %tempFile%
        FileAppend, up=%up%`n, %tempFile%
        FileAppend, down=%down%`n, %tempFile%
        FileAppend, left=%left%`n, %tempFile%
        FileAppend, right=%right%`n, %tempFile%
        FileAppend, default=%def%`n`n, %tempFile%
    }

    ; Replace original file
    FileDelete, %ConfigFile%
    FileMove, %tempFile%, %ConfigFile%

    PendingChanges := {}
    gosub, RearrangeCancel
    RefreshHotkeyList()
    MsgBox, 64, Success, Button order updated!
return

RearrangeCancel:
    Gui, Rearrange:Destroy
return

; ============================================================================
; KEY DETECTION DIALOG
; ============================================================================

; Opens a dialog to detect which key/button the user presses
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

    ; Modifier checkboxes
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

; Enable hotkey detection for supported keys
StartKeyListener:
    global DetectedKey, DetectedKeyDisplay

    ; Mouse buttons (excluding LButton)
    Hotkey, RButton, OnKeyDetected, On
    Hotkey, MButton, OnKeyDetected, On
    Hotkey, XButton1, OnKeyDetected, On
    Hotkey, XButton2, OnKeyDetected, On

    ; Letter keys A-Z
    Loop, 26 {
        key := Chr(64 + A_Index)
        Hotkey, %key%, OnKeyDetected, On
    }

    ; Number keys 0-9
    Loop, 10 {
        key := A_Index - 1
        Hotkey, %key%, OnKeyDetected, On
    }

    ; Function keys F1-F12
    Loop, 12 {
        key := "F" . A_Index
        Hotkey, %key%, OnKeyDetected, On
    }

    ; Special keys
    specialKeys := ["Space", "Enter", "Escape", "Tab", "BackSpace", "Delete", "Insert", "Home", "End", "PgUp", "PgDn", "Up", "Down", "Left", "Right", "PrintScreen", "Pause", "CapsLock", "NumLock", "ScrollLock"]
    for index, key in specialKeys {
        Hotkey, %key%, OnKeyDetected, On
    }

    ; Modifier keys - allow detecting modifier alone (Shift/Alt/Ctrl)
    ; Note: the Windows key (Win/LWin/RWin) cannot be used as a standalone hotkey
    ; (AutoHotkey will raise ""win" is not a valid key name"), so omit it here.
    modifierKeys := ["Shift", "LShift", "RShift", "Alt", "LAlt", "RAlt", "Ctrl", "LControl", "RControl"]
    for index, key in modifierKeys {
        Hotkey, %key%, OnKeyDetected, On
    }
return

; Called when a key is detected - updates the display with key and modifiers
OnKeyDetected:
    global DetectedKey, DetectCtrl, DetectShift, DetectAlt, DetectWin, DetectedKeyDisplay

    DetectedKey := A_ThisHotkey
    ; Normalize some modifier key names (e.g. LShift -> Shift) for display & storage
    if (RegExMatch(DetectedKey, "i)shift")) {
        DetectedKey := "Shift"
    } else if (RegExMatch(DetectedKey, "i)control|ctrl")) {
        DetectedKey := "Ctrl"
    } else if (RegExMatch(DetectedKey, "i)alt")) {
        DetectedKey := "Alt"
    } else if (RegExMatch(DetectedKey, "i)win")) {
        DetectedKey := "Win"
    }

    ; Ensure all modifiers are detected and displayed correctly (physical state)
    modifiers := ""
    DetectCtrl := GetKeyState("Ctrl", "P") ? (modifiers .= "Ctrl + ", 1) : 0
    DetectShift := GetKeyState("Shift", "P") ? (modifiers .= "Shift + ", 1) : 0
    DetectAlt := GetKeyState("Alt", "P") ? (modifiers .= "Alt + ", 1) : 0
    DetectWin := (GetKeyState("LWin", "P") || GetKeyState("RWin", "P")) ? (modifiers .= "Win + ", 1) : 0

    displayStr := modifiers . DetectedKey
    GuiControl, KeyDetect:, DetectedKeyDisplay, %displayStr%
return

; Confirm the detected key and create a new button entry
ConfirmKey:
    global DetectedKey, HotkeyList, ConfigFile

    Gui, KeyDetect:Submit, NoHide

    if (DetectedKey = "") {
        MsgBox, 48, Error, Please detect a key first!
        return
    }

    ; Normalize hotkey string with modifiers
    finalHotkey := ""
    if (DetectCtrl)
        finalHotkey .= "^"
    if (DetectShift)
        finalHotkey .= "+"
    if (DetectAlt)
        finalHotkey .= "!"

    if (DetectWin)
        finalHotkey .= "#"

    ; If the detected key is itself a modifier (or no non-mod key was found),
    ; represent the combination as a single brace-wrapped modifier list
    if (DetectedKey = "Shift" || DetectedKey = "Ctrl" || DetectedKey = "Alt" || DetectedKey = "Win") {
        mods := ""
        if (DetectCtrl)
            mods .= (mods = "" ? "Ctrl" : "+Ctrl")
        if (DetectShift)
            mods .= (mods = "" ? "Shift" : "+Shift")
        if (DetectAlt)
            mods .= (mods = "" ? "Alt" : "+Alt")
        if (DetectWin)
            mods .= (mods = "" ? "Win" : "+Win")

        ; Fallback to the detected key if no modifiers were captured for some reason
        if (mods = "")
            mods := DetectedKey

        finalHotkey := "{" . mods . "}"
    } else {
        ; For letters/digits/functions, don't wrap in braces; for special keys keep braces
        if (RegExMatch(DetectedKey, "^[A-Za-z0-9]$") || RegExMatch(DetectedKey, "^F\d+$")) {
            finalHotkey .= SubStr(DetectedKey, 1) ; letter/number/function (case preserved)
        } else {
            finalHotkey .= "{" . DetectedKey . "}"
        }
    }

    normalizedHotkey := finalHotkey

    ; Check if button already exists
    found := false
    for index, hk in HotkeyList {
        if (hk = normalizedHotkey) {
            found := true
            break
        }
    }

    ; Add new button to list and INI file
    if (!found) {
        HotkeyList.Push(normalizedHotkey)
        RefreshHotkeyList()

        ; Add blank line before new section for readability
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

; Disable all hotkey listeners
StopKeyListener:
    ; Check if hotkeys were registered before disabling
    if (DetectedKey != "") {
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

        modifierKeys := ["Shift", "LShift", "RShift", "Alt", "LAlt", "RAlt", "Ctrl", "LControl", "RControl"]
        for index, key in modifierKeys {
            Hotkey, %key%, Off
        }
    }
return

; ============================================================================
; GUI CLOSE HANDLERS
; ============================================================================

KeyDetectGuiClose:
KeyDetectGuiEscape:
    gosub, StopKeyListener
    Gui, KeyDetect:Destroy
return

ConfigGuiClose:
ConfigGuiEscape:
ExitApp
return

; ============================================================================
; HELPER FUNCTIONS
; ============================================================================

; Store current form values to PendingChanges (converts display mode to stored code)
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

; Load all buttons from INI file into HotkeyList
LoadConfig() {
    global ConfigFile, HotkeyList, MoveThreshold

    IniRead, threshold, %ConfigFile%, Settings, MoveThreshold, 30
    GuiControl, Config:, MoveThreshold, %threshold%

    HotkeyList := []

    ; Find all sections starting with "Hotkey_"
    IniRead, sections, %ConfigFile%
    Loop, Parse, sections, `n
    {
        if (InStr(A_LoopField, "Hotkey_") = 1) {
            hotkey := SubStr(A_LoopField, 8)
            hotkey := Trim(hotkey)

            ; Migrate legacy modifier-symbol-only section names (e.g. ^+, +!, ^)
            if (RegExMatch(hotkey, "^[\^+!#]+$")) {
                mods := ""
                if (InStr(hotkey, "^"))
                    mods .= (mods = "" ? "Ctrl" : "+Ctrl")
                if (InStr(hotkey, "+"))
                    mods .= (mods = "" ? "Shift" : "+Shift")
                if (InStr(hotkey, "!"))
                    mods .= (mods = "" ? "Alt" : "+Alt")
                if (InStr(hotkey, "#"))
                    mods .= (mods = "" ? "Win" : "+Win")

                newHotkey := "{" . mods . "}"

                ; Read old values
                oldSection := "Hotkey_" . hotkey
                IniRead, modeVal, %ConfigFile%, %oldSection%, mode
                IniRead, aimVal, %ConfigFile%, %oldSection%, aim_delay
                IniRead, upVal, %ConfigFile%, %oldSection%, up
                IniRead, downVal, %ConfigFile%, %oldSection%, down
                IniRead, leftVal, %ConfigFile%, %oldSection%, left
                IniRead, rightVal, %ConfigFile%, %oldSection%, right
                IniRead, defVal, %ConfigFile%, %oldSection%, default

                ; Write to new section (overwrites if exists)
                newSection := "Hotkey_" . newHotkey
                if (modeVal != "")
                    IniWrite, %modeVal%, %ConfigFile%, %newSection%, mode
                if (aimVal != "")
                    IniWrite, %aimVal%, %ConfigFile%, %newSection%, aim_delay
                IniWrite, % upVal := upVal ? upVal : %A_Space% , %ConfigFile%, %newSection%, up
                IniWrite, % downVal := downVal ? downVal : %A_Space% , %ConfigFile%, %newSection%, down
                IniWrite, % leftVal := leftVal ? leftVal : %A_Space% , %ConfigFile%, %newSection%, left
                IniWrite, % rightVal := rightVal ? rightVal : %A_Space% , %ConfigFile%, %newSection%, right
                IniWrite, % defVal := defVal ? defVal : %A_Space% , %ConfigFile%, %newSection%, default

                ; Delete old section
                IniDelete, %ConfigFile%, %oldSection%

                hotkey := newHotkey
            }
            HotkeyList.Push(hotkey)

            ; Preload data for each button
            LoadHotkeyData(hotkey)
        }
    }

    RefreshHotkeyList()
}

; Update the ListBox with current HotkeyList
RefreshHotkeyList() {
    global HotkeyList, ConfigFile

    listStr := ""
    for index, hk in HotkeyList {
        listStr .= hk "|"
    }

    GuiControl, Config:, HotkeyListBox, |%listStr%
}

; Update LoadHotkeyData to populate the GUI for all buttons
LoadHotkeyData(hotkey) {
    global ConfigFile, PendingChanges

    ; Clean up hotkey string
    spacePos := InStr(hotkey, " ")
    if (spacePos > 0)
        hotkey := SubStr(hotkey, 1, spacePos - 1)

    hotkey := Trim(hotkey)
    section := "Hotkey_" . hotkey

    ; Load from PendingChanges if available, otherwise from INI
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

    ; Convert stored mode code to display name
    displayMode := ConvertModeToDisplay(mode)

    ; Update form controls for preloading
    GuiControl, Config:ChooseString, ButtonMode, %displayMode%
    GuiControl, Config:, AimDelay, %aimDelay%

    ; Show/hide AimDelay based on mode
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

; ============================================================================
; MODE CONVERSION FUNCTIONS
; ============================================================================
; INI stores: R (Pull and Release), T (On Tap), H (Pull and Hold)
; GUI displays: "Pull and Release", "On Tap", "Pull and Hold"

; Convert stored mode code to display name
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

; Convert display name to stored mode code
ConvertModeToStored(displayMode) {
    if (displayMode = "Pull and Release")
        return "R"
    else if (displayMode = "On Tap")
        return "T"
    else if (displayMode = "Pull and Hold")
        return "H"
}
