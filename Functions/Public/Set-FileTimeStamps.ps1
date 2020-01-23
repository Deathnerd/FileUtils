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