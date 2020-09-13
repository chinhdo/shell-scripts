   SendMode Input
   SetWorkingDir %A_ScriptDir% 

   #Persistent
   SetTimer, Chronos, 500
   Return

   ^!x::
   goto PauseFS
   return

   Chronos:
   FormatTime, TimeToPause,,HHmm

   If TimeToPause = 1515 ; If you wanted the script to start at 7 am put change 1006 to 700
   {
      goto PauseFS   
   }
   Return

   PauseFS:
      Sleep 250
      if WinExist("Microsoft Flight Simulator")
         WinActivate ; use the window found above 
         WinWaitActive, Microsoft Flight Simulator
         SoundBeep, [ 1000, 25]
         Sleep 500

         Send {Esc down}
         Sleep 250
         Send {Esc up}
         Sleep 250

         Sleep 500
         ExitApp
   return