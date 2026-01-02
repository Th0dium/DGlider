#NoEnv
#SingleInstance Force

testFile := A_ScriptDir "\gesture_config.ini"

; Test reading empty value
IniRead, emptyLeft, %testFile%, Hotkey_{xbutton1}, left
MsgBox, xbutton1/left (no default): [%emptyLeft%]

; Test with empty default
IniRead, emptyLeft2, %testFile%, Hotkey_{xbutton1}, left, 
MsgBox, xbutton1/left (empty default): [%emptyLeft2%]

; Test reading non-empty value
IniRead, rightVal, %testFile%, Hotkey_{rbutton}, right
MsgBox, rbutton/right (no default): [%rightVal%]

ExitApp
