function New-Shortcut {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$TargetFile,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ShortcutFile
    )
    Begin {
        $ShortcutFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ShortcutFile)
    }
    Process {
        $WScriptShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
        $Shortcut.TargetPath = $TargetFile
        $Shortcut.Save()
    }
}