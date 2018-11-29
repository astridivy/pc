#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance force
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Include, %A_ScriptDir%\VA.ahk

vol_Master := VA_GetMasterVolume()

; -------------------
; START CONFIGURATION
; -------------------
; The percentage by which to raise or lower the volume each time
vol_Step = 3
; How long to display the volume level bar graphs (in milliseconds)
vol_DisplayTime = 1000
; Transparency of window (0-255)
vol_TransValue = 255
; Bar's background colour
vol_CW = EEEEEE    
vol_Width = 200  ; width of bar
vol_Thick = 20   ; thickness of bar
; Bar's screen position
vol_PosX := A_ScreenWidth - vol_Width - 50
vol_PosY := A_ScreenHeight - vol_Thick - 100
; --------------------
; END OF CONFIGURATION
; --------------------
vol_BarOptionsMaster = 1:B1 ZH%vol_Thick% ZX8 ZY4 W%vol_Width% X%vol_PosX% Y%vol_PosY% CW%vol_CW%
return


$Volume_down::
Alt & NumpadSub:: 
{
   if vol_Master > .01
   {
   VA_SetMasterVolume(vol_Master-=vol_Step)
   if vol_Master <= 0
      {
         VA_SetMute(True)
      }
   }
Gosub, vol_ShowBars
}
return



$Volume_up::
Alt & NumpadAdd::
{
   if vol_Master <= 99
   {
   VA_SetMasterVolume(vol_Master+=vol_Step)
   if vol_Master > 1
      {
         VA_SetMute(False)
      }
   }
Gosub, vol_ShowBars
}
return



vol_ShowBars:
; Get volumes in case the user or an external program changed them:
vol_Master := VA_GetMasterVolume()
vol_Mute := VA_GetMasterMute()
if vol_Mute <> 1
{
  vol_Colour = Green    
  vol_Text = Volume
}
else
{
  vol_Colour = Red      
  vol_Text = Volume (muted)
}
; To prevent the "flashing" effect, only create the bar window if it doesn't already exist:
IfWinNotExist, VolumeOSDxyz
{
    Progress, %vol_BarOptionsMaster% CB%vol_Colour% CT%vol_Colour%, , %vol_Text%, VolumeOSDxyz
    WinSet, Transparent, %vol_TransValue%, VolumeOSDxyz
}
Progress, 1:%vol_Master%, , %vol_Text%
SetTimer, vol_BarOff, %vol_DisplayTime%
return


vol_BarOff:
SetTimer, vol_BarOff, off
Progress, 1:Off
return
