function Find-String {
    [CmdletBinding()]
    [OutputType([Microsoft.PowerShell.Commands.MatchInfo])]
    Param (
        [ValidateScript( {Resolve-Path $_})]
        [string[]]$Path = ".",
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { $null -ne [Regex]::new($_) })]
        [string]$Pattern,
        [string]$Filter,
        [string[]]$Include,
        [string[]]$Exclude,
        [switch]$Recurse,
        [switch]$AllMatches
    )
    Process {
        if ($Recurse) {
            $params = @{
                "File"    = $true
                "Recurse" = $true
                "Path"    = $Path
                "Filter"  = $Filter
            }
            $Path = Get-ChildItem @params | Select-Object -ExpandProperty FullName
        }
        $params = @{
            "Path"       = $Path
            "Pattern"    = $Pattern
            "AllMatches" = $AllMatches
        }
        if ($Include) {
            $params["Include"] = $Include
        }
        if ($Exclude) {
            $params["Exclude"] = $Exclude
        }
        return Select-String @params
    }
}