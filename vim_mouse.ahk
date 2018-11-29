<#<!i::
  mouse1alt := not mouse1alt
  if (mouse1alt) {
    Click down
  } else {
    Click up
  }
Return

; realistically we never need to hold down the right click button
<#<!o:: Click Right

; this doesn't work the way you'd think, so I'm also just going to make it a single click
<#<!p:: Click Middle

; Mouse Wheel
<#<!<+j:: Click WheelDown
<#<!<+k:: Click WheelUp

; Forward and backward mouse buttons
<#<!n:: Click X2
<#<!b:: Click X1

; Move the mouse with vim movement keys
; TODO make this smoother
<#<!h:: MouseMove -16, 0, 0, R
<#<!j:: MouseMove 0, 16, 0, R
<#<!k:: MouseMove 0, -16, 0, R
<#<!l:: MouseMove 16, 0, 0, R

; Jump to edges of screen
; Center
<#<!<^;::
  CoordMode, Mouse, Screen
  MouseMove, (A_ScreenWidth // 2), (A_ScreenHeight // 2)
Return
; Center of 2nd monitor
<#<!<^'::
  CoordMode, Mouse, Screen
  MouseMove, (A_ScreenWidth + A_ScreenWidth // 2), (A_ScreenHeight // 2)
Return
; Left
<#<!<^h::
  y := 0
  CoordMode, Mouse, Screen
  MouseGetPos,, y
  MouseMove, 0, y
Return
; Right
<#<!<^l::
  y := 0
  CoordMode, Mouse, Screen
  MouseGetPos,, y
  MouseMove, (A_ScreenWidth - 1), y
Return
; Down
<#<!<^j::
  x := 0
  CoordMode, Mouse, Screen
  MouseGetPos, x
  MouseMove, x, (A_ScreenHeight - 0)
Return
; Up
<#<!<^k::
  x := 0
  CoordMode, Mouse, Screen
  MouseGetPos, x
  MouseMove, x, 0
Return

<#<!<^6:: MsgBox % A_ScreenWidth


; Yank a window around
<#<!y::
  width := 0
  WinGetPos,,,width,,A
  center := width / 2
  ;MsgBox, Hello %width% %center%
  MouseMove center, 10
  mouse1alt := 1
  Click down
Return

; Move mouse to center of current window
<#<!c::
  width := 0
  height := 0
  WinGetPos,,,width,height,A
  centerX := width / 2
  centerY := height / 2
  ;MsgBox, Hello %width% %center%
  MouseMove centerX, centerY
Return

; Move mouse to right / center of current window (where the scroll bar might be)
<#<!r::
  width := 0
  height := 0
  WinGetPos,,,width,height,A
  x := width - 15
  y := height / 2
  ;MsgBox, Hello %width% %center%
  MouseMove x, y
Return

; Move mouse to slightly less right / center of current window (where you can right click in explorer)
<#<!e::
  width := 0
  height := 0
  WinGetPos,,,width,height,A
  x := width - 40
  y := height / 2
  ;MsgBox, Hello %width% %center%
  MouseMove x, y
Return

; Add vim movement to Explorer
if WinActive("ahk_class CabinetWClass")
  <#h:: Send {Left}
  <#j:: Send {Down}
  <#k:: Send {Up}
  <#l:: Send {Right}


;<#<!hk:: MouseMove -16, -16, 0, R
;<#<!hj:: MouseMove -16, 16, 0, R
;<#<!lk:: MouseMove 16, -16, 0, R
;<#<!lj:: MouseMove 16, 16, 0, R
