#NoEnv
#NoTrayIcon
#SingleInstance Ignore

; Declare variables
installFlag := 3
downloadPackages := 1
downloadApp := 1
currentVersion := "0.0"
packageVersion := "v0.0"

; Decide what will happen next by parsing command line flags
If (A_Args[1])
{
    If ((A_Args[1] = "-u") || (A_Args[1] = "--uninstall") || (A_Args[1] = "/U"))
        installFlag := 1
    If ((A_Args[1] = "-c") || (A_Args[1] = "--check-for-updates") || (A_Args[1] = "/C"))
        installFlag := 2
    If ((A_Args[1] = "-r") || (A_Args[1] = "--run-bee2") || (A_Args[1] = "/R"))
        installFlag := 3
} else {
    installFlag := 0
}

; Check for internet access
SetWorkingDir %A_Temp%
FileDelete, internet_check.tmp
UrlDownloadToFile, https://www.example.com/, internet_check.tmp

If ((ErrorLevel = 1) && (installFlag != 1))
{
    MsgBox, 0x10, Better Extended Editor for Portal 2, No internet connection!
    
    if (installFlag = 3)
    {
        ComObjCreate( "Shell.Application" ).Windows.FindWindowSW( 0 , 0 , 8 , 0 , 1 ).Document.Application.ShellExecute( """C:\Program Files\BEEMOD2\BEE2.exe""" )
    }
    
    ExitApp
}

FileDelete, internet_check.tmp

if (installFlag = 1)
{
    GoSub, UninstallBEE2
    ExitApp
}

if (installFlag = 2)
{
    GoSub, CheckForUpdates
    ExitApp
}

if (installFlag = 3)
{
    GoSub, RunBEE2
    ExitApp
}
    
; If the script is not elevated, relaunch as administrator and kill current instance
full_command_line := DllCall("GetCommandLine", "str")

if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
{
    try
    {
        if A_IsCompiled
            Run *RunAs "%A_ScriptFullPath%" /restart
        else
            Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
    }
    ExitApp
}

if (installFlag = 0)
{
    GoSub, InstallBEE2
    ExitApp
}

ExitApp

InstallBEE2:
    If (installFlag = 0)
    {
        ; Install prompt
        MsgBox, 0x21, BEE2 Installer, Would you like to install Better Extended Editor for Portal 2?
        
        ; Interpret user answer
        IfMsgBox, Cancel
        {
            MsgBox, 0x30, BEE2 Installer, Installation canceled
            downloadApp := 0
            downloadPackages := 0
            ExitApp
        }
        
        Sleep, 1000
        
        ; Package prompt
        MsgBox, 0x23, BEE2 Installer, Would you like to install additional BEE2 Packages?
        
        ; Interpret user answer
        IfMsgBox, Cancel
        {
            MsgBox, 0x30, BEE2 Installer, Installation canceled
            downloadApp := 0
            downloadPackages := 0
            ExitApp
        }
        IfMsgBox, No
        {
            downloadPackages := 0
        }
    }
    
    ; Start install GUI
    Gui, New, +AlwaysOnTop +Disabled +MinSize320x240, BEE2 Installer
    Gui, Add, Text, w320 vInstallText, Preparing to install...
    Gui, Add, Progress, w320 h20 cGreen vInstallProgress, 0
    Gui, Show, AutoSize xCenter yCenter
    
    ; Delete old install
    If (installFlag = 0)
    {
        SetWorkingDir, C:\Program Files
        FileDelete, BEEMOD2
        FileRemoveDir, BEEMOD2, 1
        FileCreateDir, BEEMOD2
    }
    
    ; Update progress
    Loop, 5
    {
        GuiControl,, InstallProgress, +1
        Sleep, 5
    }
    
    ; Create temp folder
    SetWorkingDir %A_Temp%
    FileRemoveDir, BEEMOD2, 1
    FileCreateDir, BEEMOD2
    
    ; Update progress
    Loop, 3
    {
        GuiControl,, InstallProgress, +1
        Sleep, 5
    }
    
    ; Navigate to temp folder
    SetWorkingDir %A_Temp%\BEEMOD2
    
    ; Update progress
    GuiControl,, InstallProgress, +1
    
    ; Download unzip.exe
    UrlDownloadToFile, https://github.com/programmer2514/BEE2.4-Installer-Automatic/blob/master/unzip/unzip.exe?raw=true, unzip.exe
    
    ; Update progress
    Loop, 3
    {
        GuiControl,, InstallProgress, +1
        Sleep, 5
    }
    
    ; Download latest BEE2 application
    if (downloadApp = 1)
    {
        GuiControl,, InstallText, Downloading BEE2...
        
        ; Download GitHub API JSON data
        UrlDownloadToFile, https://api.github.com/repos/BEEmod/BEE2.4/releases, beemod.json
        
        ; Parse JSON data
        FileRead beemodJSON, beemod.json
        beemodData := JSON.Load(beemodJSON)
        beemodURL := beemodData[1].assets[1].browser_download_url
        currentVersion := beemodData[1].tag_name
        
        ; Download file
        UrlDownloadToFile, %beemodURL%, beemod.zip
        
        GuiControl,, InstallText, Installing BEE2...
        Sleep, 250
        
        ; Unzip and copy to program files
        RunWait, unzip.exe beemod.zip -d beemod,, Hide
        CopyFilesAndFolders(A_Temp . "\BEEMOD2\beemod\*", "C:\Program Files\BEEMOD2", true)
    }
    
    ; Update progress
    Loop, 38
    {
        GuiControl,, InstallProgress, +1
        Sleep, 5
    }
    
    ; Download latest BEE2 packages
    if (downloadPackages = 1)
    {
        GuiControl,, InstallText, Downloading packages...
        
        ; Download GitHub API JSON data
        UrlDownloadToFile, https://api.github.com/repos/BEEmod/BEE2-items/releases, packages.json
        
        ; Parse JSON data
        FileRead packagesJSON, packages.json
        packagesData := JSON.Load(packagesJSON)
        packagesURL := packagesData[1].assets[1].browser_download_url
        packageVersion := packagesData[1].tag_name
        
        ; Download file
        UrlDownloadToFile, %packagesURL%, packages.zip
        
        GuiControl,, InstallText, Installing packages...
        Sleep, 250
        
        ; Unzip and copy to program files
        RunWait, unzip.exe packages.zip -d packages,, Hide
        CopyFilesAndFolders(A_Temp . "\BEEMOD2\packages\*", "C:\Program Files\BEEMOD2", true)
    }
    
    ; Update progress
    Loop, 40
    {
        GuiControl,, InstallProgress, +1
        Sleep, 5
    }
    GuiControl,, InstallText, Cleaning up...
    
    ; Clean up temp files
    SetWorkingDir %A_Temp%
    FileRemoveDir, BEEMOD2, 1
    
    ; Update progress
    Loop, 2
    {
        GuiControl,, InstallProgress, +1
        Sleep, 5
    }
    GuiControl,, InstallText, Downloading icons...
    
    ; Copy self into BEE2 directory
    FileCopy, %A_ScriptFullPath%, C:\Program Files\BEEMOD2
    
    SetWorkingDir, C:\Program Files\BEEMOD2
    FileDelete, BEE2.ico
    UrlDownloadToFile, https://raw.githubusercontent.com/programmer2514/BEE2.4-Installer-Automatic/master/icons/bee2.ico, bee2.ico
    UrlDownloadToFile, https://raw.githubusercontent.com/programmer2514/BEE2.4-Installer-Automatic/master/icons/bee2-uninstaller.ico, bee2-uninstaller.ico
    UrlDownloadToFile, https://raw.githubusercontent.com/programmer2514/BEE2.4-Installer-Automatic/master/icons/bee2-updater.ico, bee2-updater.ico
    
    
    ; Update progress
    Loop, 3
    {
        GuiControl,, InstallProgress, +1
        Sleep, 5
    }
    GuiControl,, InstallText, Adding shortcuts...
    
    ; Create Start Menu folder
    SetWorkingDir, C:\ProgramData\Microsoft\Windows\Start Menu\Programs
    FileRemoveDir, BEE2, 1
    FileCreateDir, BEE2
    
    ; Update progress
    Loop, 2
    {
        GuiControl,, InstallProgress, +1
        Sleep, 5
    }
    
    ; Navigate to Start Menu folder
    SetWorkingDir, C:\ProgramData\Microsoft\Windows\Start Menu\Programs\BEE2
    
    ; Update progress
    GuiControl,, InstallProgress, +1
    
    ; Create BEE2, Check for updates, & Uninstall links
    FileCreateShortcut, C:\Program Files\BEEMOD2\%A_ScriptName%, BEE2.lnk, C:\Program Files\BEEMOD2\, -r, Launch BEE2, C:\Program Files\BEEMOD2\bee2.ico
    FileCreateShortcut, C:\Program Files\BEEMOD2\%A_ScriptName%, Uninstall.lnk, C:\Program Files\BEEMOD2\, -u, Uninstall BEE2, C:\Program Files\BEEMOD2\bee2-uninstaller.ico
    FileCreateShortcut, C:\Program Files\BEEMOD2\%A_ScriptName%, Check for Updates.lnk, C:\Program Files\BEEMOD2\, -c, Check for updates to BEE2, C:\Program Files\BEEMOD2\bee2-updater.ico
    
    ; Update progress
    Loop, 2
    {
        GuiControl,, InstallProgress, +1
        Sleep, 5
    }
    GuiControl,, InstallText, Finishing up...
    
    ; Create text file with BEE2 version
    SetWorkingDir, %A_AppData%\BEEMOD2
    if (downloadApp = 1)
    {
        FileDelete, version.txt
        FileAppend, %currentVersion%, version.txt
    }
    
    if (downloadPackages = 1)
    {
        FileDelete, pck_version.txt
        FileAppend, %packageVersion%, pck_version.txt
    }
    
    Date_HRS := (A_YYYY * 8760) + (A_MM * 730) + (A_DD * 24) + A_Hour
    
    FileDelete, last_update.txt
    FileAppend, %Date_HRS%, last_update.txt
    
    ; Finish installation
    RunWait, icacls "C:\Program Files\BEEMOD2" /grant "Everyone":F /t,, Hide
    
    Gui, Destroy
    If (downloadApp = 1)
        MsgBox, 0x30, BEE2 Installer, BEEMOD v%currentVersion% has been installed successfully!
    If (downloadPackages = 1)
        MsgBox, 0x30, BEE2 Installer, BEEMOD packages %packageVersion% has been installed successfully!
        
    ; Run Prompt
    MsgBox, 0x124, BEE2 Installer, Would you like to run BEE2 now?
    IfMsgBox Yes
    {
        ComObjCreate( "Shell.Application" ).Windows.FindWindowSW( 0 , 0 , 8 , 0 , 1 ).Document.Application.ShellExecute( """C:\Program Files\BEEMOD2\BEE2.exe""" )
    }
Return

UninstallBEE2:
    ; If the script is not elevated, relaunch as administrator and kill current instance
    full_command_line := DllCall("GetCommandLine", "str")
    
    if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
    {
        try
        {
            if A_IsCompiled
            {
                FileCopy, %A_ScriptFullPath%, %A_Temp%, true
                Run *RunAs "%A_Temp%\%A_ScriptName%" /U /restart
            } else {
                Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%" /U
            }
        }
        ExitApp
    }
    
    ; Uninstall prompt
    MsgBox, 0x21, BEE2 Uninstaller, Are you sure you would like to remove Better Extended Editor for Portal 2 and all of its components?
    
    ; Interpret user answer
    IfMsgBox, Cancel
    {
        ExitApp
    }
    
    ; Remove version text files
    SetWorkingDir, %A_AppData%\BEEMOD2
    FileDelete, version.txt
    FileDelete, pck_version.txt
    FileDelete, last_update.txt
    
    Sleep, 1000
    
    ; Remove data prompt
    MsgBox, 0x123, BEE2 Uninstaller, Would you like to remove user data (configuration, palettes, etc.)?
    
    ; Interpret user answer
    IfMsgBox, Cancel
    {
        ExitApp
    }
    IfMsgBox Yes
    {
        SetWorkingDir, %A_AppData%
        FileRemoveDir, BEEMOD2, 1
    }
    
    ; Remove application/packages
    SetWorkingDir, C:\Program Files
    FileRemoveDir, BEEMOD2, 1
    
    ; Remove start menu shortcuts
    SetWorkingDir, C:\ProgramData\Microsoft\Windows\Start Menu\Programs
    FileRemoveDir, BEE2, 1
    
    MsgBox, 0x40, BEE2 Uninstaller, Better Extended Editor for Portal 2 removed successfully!
    
Return

CheckForUpdates:
    ; Reset variables
    downloadPackages := 0
    downloadApp := 0
    newerVersionAvailable := 0
    
    ; Create temp folder
    SetWorkingDir %A_Temp%
    FileRemoveDir, BEEMOD2, 1
    FileCreateDir, BEEMOD2
    
    ; Download GitHub API JSON data
    UrlDownloadToFile, https://api.github.com/repos/BEEmod/BEE2.4/releases, beemod.json
    UrlDownloadToFile, https://api.github.com/repos/BEEmod/BEE2-items/releases, packages.json
        
    ; Parse JSON data
    FileRead beemodJSON, beemod.json
    FileRead packagesJSON, packages.json
    beemodData := JSON.Load(beemodJSON)
    packagesData := JSON.Load(packagesJSON)
    newVersion := beemodData[1].tag_name
    newPckVersion := packagesData[1].tag_name
    
    ; Read current version text files
    SetWorkingDir, %A_AppData%\BEEMOD2
    
    FileRead currentVersion, version.txt
    If FileExist("pck_version.txt")
        FileRead currentPckVersion, pck_version.txt
    else
        currentPckVersion := "null"
        
    If not (currentVersion = newVersion)
        newerVersionAvailable := 1
        
    If not (currentPckVersion = newPckVersion)
    {
        If not (currentPckVersion = "null")
        {
            If (newerVersionAvailable = 1)
                newerVersionAvailable := 3
            else
                newerVersionAvailable := 2
        }
    }
    
    ; Ask user if they want to download newer version if available, otherwise, do nothing
    If (newerVersionAvailable > 0)
    {
        If (installFlag = 3)
        {
            ; If the script is not elevated, relaunch as administrator and kill current instance
            full_command_line := DllCall("GetCommandLine", "str")
            
            if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
            {
                try
                {
                    if A_IsCompiled
                    {
                        FileCopy, %A_ScriptFullPath%, %A_Temp%, true
                        Run *RunAs "%A_Temp%\%A_ScriptName%" -r /restart
                    } else {
                        Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%" -r
                    }
                }
                ExitApp
            }
        } else
        {
            ; If the script is not elevated, relaunch as administrator and kill current instance
            full_command_line := DllCall("GetCommandLine", "str")
            
            if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
            {
                try
                {
                    if A_IsCompiled
                    {
                        FileCopy, %A_ScriptFullPath%, %A_Temp%, true
                        Run *RunAs "%A_Temp%\%A_ScriptName%" /C /restart
                    } else {
                        Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%" /C
                    }
                }
                ExitApp
            }
        }
        
        If ((newerVersionAvailable = 1) || (newerVersionAvailable = 3))
        {
            MsgBox, 0x44, BEE2 Updater, A newer version of BEE2 (%newVersion% > %currentVersion%) is available.`nWould you like to update now?
            IfMsgBox Yes
                downloadApp := 1
        }
        
        If ((newerVersionAvailable = 2) || (newerVersionAvailable = 3))
        {
            MsgBox, 0x44, BEE2 Updater, A newer version of BEE2 packages (%newPckVersion% > %currentPckVersion%) is available.`nWould you like to update now?
            IfMsgBox Yes
                downloadPackages := 1
        }
        
        If ((downloadApp = 1) || (downloadPackages = 1))
            GoSub, InstallBEE2
        else
            Return
    } else
    {
        If (installFlag = 2)
            MsgBox, 0x40, BEE2 Updater, No updates are currently available
    }
Return

RunBEE2:
    ; Get last update time
    SetWorkingDir, %A_AppData%\BEEMOD2
    FileRead lastUpdate, last_update.txt
    
    ; Get date in hours
    Date_HRS := (A_YYYY * 8760) + (A_MM * 730) + (A_DD * 24) + A_Hour

    ; Check for updates
    If not (Date_HRS = lastUpdate)
    {
        GoSub, CheckForUpdates
    }
    
    ; Run BEE2
    ComObjCreate( "Shell.Application" ).Windows.FindWindowSW( 0 , 0 , 8 , 0 , 1 ).Document.Application.ShellExecute( """C:\Program Files\BEEMOD2\BEE2.exe""" )
Return





CopyFilesAndFolders(SourcePattern, DestinationFolder, DoOverwrite = false)
{
    ; First copy all the files (but not the folders):
    FileCopy, %SourcePattern%, %DestinationFolder%, %DoOverwrite%
    ErrorCount := ErrorLevel
    
    ; Now copy all the folders:
    Loop, %SourcePattern%, 2 ; 2 means "retrieve folders only".
    {
        FileCopyDir, %A_LoopFileFullPath%, %DestinationFolder%\%A_LoopFileName%, %DoOverwrite%
        ErrorCount += ErrorLevel
        if ErrorLevel  ; Report each problem folder by name.
            MsgBox Could not copy %A_LoopFileFullPath% into %DestinationFolder%.
    }
    
    return ErrorCount
}





/**
 * Lib: JSON.ahk
 *     JSON lib for AutoHotkey.
 * Version:
 *     v2.1.3 [updated 04/18/2016 (MM/DD/YYYY)]
 * License:
 *     WTFPL [http://wtfpl.net/]
 * Requirements:
 *     Latest version of AutoHotkey (v1.1+ or v2.0-a+)
 * Installation:
 *     Use #Include JSON.ahk or copy into a function library folder and then
 *     use #Include <JSON>
 * Links:
 *     GitHub:     - https://github.com/cocobelgica/AutoHotkey-JSON
 *     Forum Topic - http://goo.gl/r0zI8t
 *     Email:      - cocobelgica <at> gmail <dot> com
 */


/**
 * Class: JSON
 *     The JSON object contains methods for parsing JSON and converting values
 *     to JSON. Callable - NO; Instantiable - YES; Subclassable - YES;
 *     Nestable(via #Include) - NO.
 * Methods:
 *     Load() - see relevant documentation before method definition header
 *     Dump() - see relevant documentation before method definition header
 */
class JSON
{
	/**
	 * Method: Load
	 *     Parses a JSON string into an AHK value
	 * Syntax:
	 *     value := JSON.Load( text [, reviver ] )
	 * Parameter(s):
	 *     value      [retval] - parsed value
	 *     text    [in, ByRef] - JSON formatted string
	 *     reviver   [in, opt] - function object, similar to JavaScript's
	 *                           JSON.parse() 'reviver' parameter
	 */
	class Load extends JSON.Functor
	{
		Call(self, ByRef text, reviver:="")
		{
			this.rev := IsObject(reviver) ? reviver : false
		; Object keys(and array indices) are temporarily stored in arrays so that
		; we can enumerate them in the order they appear in the document/text instead
		; of alphabetically. Skip if no reviver function is specified.
			this.keys := this.rev ? {} : false

			static quot := Chr(34), bashq := "\" . quot
			     , json_value := quot . "{[01234567890-tfn"
			     , json_value_or_array_closing := quot . "{[]01234567890-tfn"
			     , object_key_or_object_closing := quot . "}"

			key := ""
			is_key := false
			root := {}
			stack := [root]
			next := json_value
			pos := 0

			while ((ch := SubStr(text, ++pos, 1)) != "") {
				if InStr(" `t`r`n", ch)
					continue
				if !InStr(next, ch, 1)
					this.ParseError(next, text, pos)

				holder := stack[1]
				is_array := holder.IsArray

				if InStr(",:", ch) {
					next := (is_key := !is_array && ch == ",") ? quot : json_value

				} else if InStr("}]", ch) {
					ObjRemoveAt(stack, 1)
					next := stack[1]==root ? "" : stack[1].IsArray ? ",]" : ",}"

				} else {
					if InStr("{[", ch) {
					; Check if Array() is overridden and if its return value has
					; the 'IsArray' property. If so, Array() will be called normally,
					; otherwise, use a custom base object for arrays
						static json_array := Func("Array").IsBuiltIn || ![].IsArray ? {IsArray: true} : 0
					
					; sacrifice readability for minor(actually negligible) performance gain
						(ch == "{")
							? ( is_key := true
							  , value := {}
							  , next := object_key_or_object_closing )
						; ch == "["
							: ( value := json_array ? new json_array : []
							  , next := json_value_or_array_closing )
						
						ObjInsertAt(stack, 1, value)

						if (this.keys)
							this.keys[value] := []
					
					} else {
						if (ch == quot) {
							i := pos
							while (i := InStr(text, quot,, i+1)) {
								value := StrReplace(SubStr(text, pos+1, i-pos-1), "\\", "\u005c")

								static tail := A_AhkVersion<"2" ? 0 : -1
								if (SubStr(value, tail) != "\")
									break
							}

							if (!i)
								this.ParseError("'", text, pos)

							  value := StrReplace(value,  "\/",  "/")
							, value := StrReplace(value, bashq, quot)
							, value := StrReplace(value,  "\b", "`b")
							, value := StrReplace(value,  "\f", "`f")
							, value := StrReplace(value,  "\n", "`n")
							, value := StrReplace(value,  "\r", "`r")
							, value := StrReplace(value,  "\t", "`t")

							pos := i ; update pos
							
							i := 0
							while (i := InStr(value, "\",, i+1)) {
								if !(SubStr(value, i+1, 1) == "u")
									this.ParseError("\", text, pos - StrLen(SubStr(value, i+1)))

								uffff := Abs("0x" . SubStr(value, i+2, 4))
								if (A_IsUnicode || uffff < 0x100)
									value := SubStr(value, 1, i-1) . Chr(uffff) . SubStr(value, i+6)
							}

							if (is_key) {
								key := value, next := ":"
								continue
							}
						
						} else {
							value := SubStr(text, pos, i := RegExMatch(text, "[\]\},\s]|$",, pos)-pos)

							static number := "number", integer :="integer"
							if value is %number%
							{
								if value is %integer%
									value += 0
							}
							else if (value == "true" || value == "false")
								value := %value% + 0
							else if (value == "null")
								value := ""
							else
							; we can do more here to pinpoint the actual culprit
							; but that's just too much extra work.
								this.ParseError(next, text, pos, i)

							pos += i-1
						}

						next := holder==root ? "" : is_array ? ",]" : ",}"
					} ; If InStr("{[", ch) { ... } else

					is_array? key := ObjPush(holder, value) : holder[key] := value

					if (this.keys && this.keys.HasKey(holder))
						this.keys[holder].Push(key)
				}
			
			} ; while ( ... )

			return this.rev ? this.Walk(root, "") : root[""]
		}

		ParseError(expect, ByRef text, pos, len:=1)
		{
			static quot := Chr(34), qurly := quot . "}"
			
			line := StrSplit(SubStr(text, 1, pos), "`n", "`r").Length()
			col := pos - InStr(text, "`n",, -(StrLen(text)-pos+1))
			msg := Format("{1}`n`nLine:`t{2}`nCol:`t{3}`nChar:`t{4}"
			,     (expect == "")     ? "Extra data"
			    : (expect == "'")    ? "Unterminated string starting at"
			    : (expect == "\")    ? "Invalid \escape"
			    : (expect == ":")    ? "Expecting ':' delimiter"
			    : (expect == quot)   ? "Expecting object key enclosed in double quotes"
			    : (expect == qurly)  ? "Expecting object key enclosed in double quotes or object closing '}'"
			    : (expect == ",}")   ? "Expecting ',' delimiter or object closing '}'"
			    : (expect == ",]")   ? "Expecting ',' delimiter or array closing ']'"
			    : InStr(expect, "]") ? "Expecting JSON value or array closing ']'"
			    :                      "Expecting JSON value(string, number, true, false, null, object or array)"
			, line, col, pos)

			static offset := A_AhkVersion<"2" ? -3 : -4
			throw Exception(msg, offset, SubStr(text, pos, len))
		}

		Walk(holder, key)
		{
			value := holder[key]
			if IsObject(value) {
				for i, k in this.keys[value] {
					; check if ObjHasKey(value, k) ??
					v := this.Walk(value, k)
					if (v != JSON.Undefined)
						value[k] := v
					else
						ObjDelete(value, k)
				}
			}
			
			return this.rev.Call(holder, key, value)
		}
	}

	/**
	 * Method: Dump
	 *     Converts an AHK value into a JSON string
	 * Syntax:
	 *     str := JSON.Dump( value [, replacer, space ] )
	 * Parameter(s):
	 *     str        [retval] - JSON representation of an AHK value
	 *     value          [in] - any value(object, string, number)
	 *     replacer  [in, opt] - function object, similar to JavaScript's
	 *                           JSON.stringify() 'replacer' parameter
	 *     space     [in, opt] - similar to JavaScript's JSON.stringify()
	 *                           'space' parameter
	 */
	class Dump extends JSON.Functor
	{
		Call(self, value, replacer:="", space:="")
		{
			this.rep := IsObject(replacer) ? replacer : ""

			this.gap := ""
			if (space) {
				static integer := "integer"
				if space is %integer%
					Loop, % ((n := Abs(space))>10 ? 10 : n)
						this.gap .= " "
				else
					this.gap := SubStr(space, 1, 10)

				this.indent := "`n"
			}

			return this.Str({"": value}, "")
		}

		Str(holder, key)
		{
			value := holder[key]

			if (this.rep)
				value := this.rep.Call(holder, key, ObjHasKey(holder, key) ? value : JSON.Undefined)

			if IsObject(value) {
			; Check object type, skip serialization for other object types such as
			; ComObject, Func, BoundFunc, FileObject, RegExMatchObject, Property, etc.
				static type := A_AhkVersion<"2" ? "" : Func("Type")
				if (type ? type.Call(value) == "Object" : ObjGetCapacity(value) != "") {
					if (this.gap) {
						stepback := this.indent
						this.indent .= this.gap
					}

					is_array := value.IsArray
				; Array() is not overridden, rollback to old method of
				; identifying array-like objects. Due to the use of a for-loop
				; sparse arrays such as '[1,,3]' are detected as objects({}). 
					if (!is_array) {
						for i in value
							is_array := i == A_Index
						until !is_array
					}

					str := ""
					if (is_array) {
						Loop, % value.Length() {
							if (this.gap)
								str .= this.indent
							
							v := this.Str(value, A_Index)
							str .= (v != "") ? v . "," : "null,"
						}
					} else {
						colon := this.gap ? ": " : ":"
						for k in value {
							v := this.Str(value, k)
							if (v != "") {
								if (this.gap)
									str .= this.indent

								str .= this.Quote(k) . colon . v . ","
							}
						}
					}

					if (str != "") {
						str := RTrim(str, ",")
						if (this.gap)
							str .= stepback
					}

					if (this.gap)
						this.indent := stepback

					return is_array ? "[" . str . "]" : "{" . str . "}"
				}
			
			} else ; is_number ? value : "value"
				return ObjGetCapacity([value], 1)=="" ? value : this.Quote(value)
		}

		Quote(string)
		{
			static quot := Chr(34), bashq := "\" . quot

			if (string != "") {
				  string := StrReplace(string,  "\",  "\\")
				; , string := StrReplace(string,  "/",  "\/") ; optional in ECMAScript
				, string := StrReplace(string, quot, bashq)
				, string := StrReplace(string, "`b",  "\b")
				, string := StrReplace(string, "`f",  "\f")
				, string := StrReplace(string, "`n",  "\n")
				, string := StrReplace(string, "`r",  "\r")
				, string := StrReplace(string, "`t",  "\t")

				static rx_escapable := A_AhkVersion<"2" ? "O)[^\x20-\x7e]" : "[^\x20-\x7e]"
				while RegExMatch(string, rx_escapable, m)
					string := StrReplace(string, m.Value, Format("\u{1:04x}", Ord(m.Value)))
			}

			return quot . string . quot
		}
	}

	/**
	 * Property: Undefined
	 *     Proxy for 'undefined' type
	 * Syntax:
	 *     undefined := JSON.Undefined
	 * Remarks:
	 *     For use with reviver and replacer functions since AutoHotkey does not
	 *     have an 'undefined' type. Returning blank("") or 0 won't work since these
	 *     can't be distnguished from actual JSON values. This leaves us with objects.
	 *     Replacer() - the caller may return a non-serializable AHK objects such as
	 *     ComObject, Func, BoundFunc, FileObject, RegExMatchObject, and Property to
	 *     mimic the behavior of returning 'undefined' in JavaScript but for the sake
	 *     of code readability and convenience, it's better to do 'return JSON.Undefined'.
	 *     Internally, the property returns a ComObject with the variant type of VT_EMPTY.
	 */
	Undefined[]
	{
		get {
			static empty := {}, vt_empty := ComObject(0, &empty, 1)
			return vt_empty
		}
	}

	class Functor
	{
		__Call(method, ByRef arg, args*)
		{
		; When casting to Call(), use a new instance of the "function object"
		; so as to avoid directly storing the properties(used across sub-methods)
		; into the "function object" itself.
			if IsObject(method)
				return (new this).Call(method, arg, args*)
			else if (method == "")
				return (new this).Call(arg, args*)
		}
	}
}