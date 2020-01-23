function Test-Directory {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "The path to check"
        )]
        [IO.DirectoryInfo]$Path,
        [Parameter(
            ParameterSetName = 'readable',
            HelpMessage = "Check for readability of the directory."
        )]
        [switch]$Readable,
        [Parameter(
            ParameterSetName = 'writable',
            HelpMessage = "Check for writability of the directory."
        )]
        [switch]$Writable
    )
    Process {
        try {
            if ($Writable) {
                $testFile = "$($Path.FullName)\.testpswritable"
                "" | Out-File -Filepath $testFile -Force
                Remove-Item -Path $testFile -Force
            }
            else {
                $testFile = Get-Content (Get-ChildItem -Path $Path.FullName)[0].FullName
            }
            return $true
        }
        catch {
            return $false
        }
    }
}