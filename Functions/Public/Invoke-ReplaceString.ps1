function Invoke-ReplaceString {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [ValidateScript( {Resolve-Path $_})]
        [string[]]$Path,
        [switch]$AsRegex,
        [ValidateSet("ASCII", "BigEndianUnicode", "Default", "Unicode", "UTF32", "UTF7", "UTF8")]
        [EncodingTransformAttribute()]
        [string]$Encoding = "Default",
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ($AsRegex) {
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
            "File"    = $true
            "Recurse" = $Recurse
            "Path"    = $Path
            "Filter"  = $Filter
        }
        if ($Include) {
            $params["Include"] = $Include
        }
        if ($Exclude) {
            $params["Exclude"] = $Exclude
        }
        Get-ChildItem @params | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($_.FullName, ("Replace {0} with {1}" -f $Search, $Replacement))) {
                $Content = Get-Content $_.FullName -ReadCount 0
                if ($AsRegex) {
                    $Content = $Content -replace $Search, $Replacement
                }
                else {
                    $Content = $Content.Replace($Search, $Replacement)
                }
                $Content | Out-File -LiteralPath $_.FullName
            }
        }
    }
}
Set-Alias -Name replace -Value Invoke-ReplaceString