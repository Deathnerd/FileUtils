function Invoke-TouchFile {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidateNotNull()]
        [string[]]$file
    )
    Process {
        $file | ForEach-Object {
            if (Test-Path $_) {
                (Get-ChildItem $_).LastWriteTime = Get-Date
            }
            else {
                New-Item -Force -ItemType File -Path $_ | Out-Null
            }
        }
    }
}
Set-Alias -Name touch -Value Invoke-TouchFile -Force