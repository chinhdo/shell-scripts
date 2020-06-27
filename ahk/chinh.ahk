SendMode Input
SetWorkingDir %A_ScriptDir% 

log(msg) {
	file := FileOpen("chinh.log", "a")
	if !IsObject(file)
	{
		MsgBox Can't open "%FileName%" for writing.
		return
	}

	msg2 = %msg%`n
	file.Write(msg2)
	file.Close()
}

OnExit, sub_exit
if (midi_in_Open(1))
	ExitApp

listenNoteRange(1, 127, "handleNote", 0x00)
listenCC(52, "setVolume", 0)


return
;----------------------End of auto execute section--------------------

sub_exit:
	midi_in_Close()
ExitApp

;-------------------------Miscellaneous hotkeys-----------------------
Esc::ExitApp

;-------------------------Midi "hotkey" functions---------------------
handleNote(note, vel)
{
	if (vel) ; vel == 0 means note off
	{
		log(note . "-" . vel)

		switch (note) {
			case 48:
				Send #1
			case 49:
				Send ^1
			case 50:
				Send #2
			case 51:
				Send ^2
			case 52:
				Send #3
			Case 53:
				Send #4
			Case 54:
				Send ^3
			Case 55:
				Send #5
			Case 56:
				Send ^4
			Case 57:
				Send #6
			Case 58:
				Send ^5
		}

		SoundBeep, 750, 50
		;SoundPlay drum%note%.wav
		; SoundPlay drum48.wav
		;log(note)
	}
}

setVolume(num, vel) {
	; log(num . "-" . vel)
	SoundSet, vel / 1.27
}

;-------------------------  Midi input library  ----------------------
#include midi_in_lib.ahk

; See https://watzek.dev/posts/2020/03/22/midi-for-the-home-office/
