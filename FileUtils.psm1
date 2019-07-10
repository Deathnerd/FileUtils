using namespace System.Management.Automation
using namespace System.IO
using namespace System.Collections.Generic
using namespace Security.Principal

function Set-FileTimeStamps {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String[]]$Path,
        [DateTime]$Date = (Get-Date)
    )
    Process {
        Get-ChildItem -Path $Path | ForEach-Object {
            $_.CreationTime = $Date
            $_.LastAccessTime = $Date
            $_.LastWriteTime = $Date
        }
    }
}

function New-Shortcut {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$TargetFile,
        [Parameter(Mandatory=$true)]
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
function Test-Directory {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "The path to check"
        )]
        [DirectoryInfo]$Path,
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

function Find-String {
    [CmdletBinding()]
    [OutputType([Microsoft.PowerShell.Commands.MatchInfo])]
    Param (
        [ValidateScript({Resolve-Path $_})]
        [string[]]$Path = ".",
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ $null -ne [Regex]::new($_) })]
        [string]$Pattern,
        [string]$Filter,
        [string[]]$Include,
        [string[]]$Exclude,
        [switch]$Recurse,
        [switch]$AllMatches
        # [switch]$Parallel
    )
    Process {
        if($Recurse) {
            $params = @{
                "File" = $true
                "Recurse" = $true
                "Path" = $Path
                "Filter" = $Filter
            }
            $Path = Get-ChildItem @params | Select-Object -ExpandProperty FullName
        }
        # if($Parallel -and $Recurse) {
        #     return Invoke-Parallel -ImportVariables -ImportFunctions -Throttle 20 -InputObject $Path -ScriptBlock {
        #         Find-String -Path $_ -Pattern $Pattern -Filter $Filter -Include $Include -Exclude $Exclude -Recurse:$Recurse -AllMatches:$AllMatches
        #     }
        # } else {
            $params = @{
                "Path" = $Path
                "Pattern" = $Pattern
                "AllMatches" = $AllMatches
            }
            if($Include) {
                $params["Include"] = $Include
            }
            if($Exclude) {
                $params["Exclude"] = $Exclude
            }
            return Select-String @params
        # }
    }
}

function Invoke-ReplaceString {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [ValidateScript({Resolve-Path $_})]
        [string[]]$Path,
        [switch]$AsRegex,
        [ValidateSet("ASCII", "BigEndianUnicode", "Default", "Unicode", "UTF32", "UTF7", "UTF8")]
        [EncodingTransformAttribute()]
        [string]$Encoding = "Default",
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if($AsRegex) {
                return $null -ne [Regex]::new($_)
            }
            return $true
        })]
        [string]$Search,
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [string]$Replacement,
        [string]$Filter,
        [string[]]$Include,
        [string[]]$Exclude,
        [switch]$Recurse,
        [switch]$CaseSensitive
    )
    Process {
        $params = @{
            "File" = $true
            "Recurse" = $Recurse
            "Path" = $Path
            "Filter" = $Filter
        }
        if($Include) {
            $params["Include"] = $Include
        }
        if($Exclude) {
            $params["Exclude"] = $Exclude
        }
        Get-ChildItem @params | ForEach-Object {
            if($PSCmdlet.ShouldProcess($_.FullName, ("Replace {0} with {1}" -f $Search,$Replacement))) {
                $Content = Get-Content $_.FullName -ReadCount 0
                if($AsRegex) {
                    $Content = $Content -replace $Search, $Replacement
                } else {
                    $Content = $Content.Replace($Search, $Replacement)
                }
                $Content | Out-File -LiteralPath $_.FullName
            }
        }
    }
}

function Invoke-TouchFile {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidateNotNull()]
        [string]$file
    )
    Process {
        if (Test-Path $file) {
            (Get-ChildItem $file).LastWriteTime = Get-Date
        }
        else {
            New-Item -Force -ItemType File -Path $file | Out-Null
        }
    }
}

Set-Alias -Name touch -Value Invoke-TouchFile
Set-Alias -Name replace -Value Invoke-ReplaceString

Export-ModuleMember -Function *-* -Alias * -Variable *