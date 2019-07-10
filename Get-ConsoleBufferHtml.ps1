# .synopsis 
# Capture console screen buffer. 
# 
# .returns 
# HTML File 
# 
# .example 
# PSH> Get-ConsoleBufferAsHtml 
# 
# C:\Users\timdunn\AppData\Local\Temp\Console-2013-09-20_150204.html 
# 
# .Notes 
# See http://blogs.msdn.com/b/powershell/archive/2009/01/11/colorized-capture-of-console-screen-in-html-and-rtf.aspx 
# 
# .param Path 
# Path to save screen buffer as HTML.  Defaults to "$env:TEMP\Console-<datestamp>", with suffix as appropriate to file format. 
# 
# .param Full 
# Save entire console buffer.  Default is to only capture the current window. 
# 
# .param Preview 
# Open the file in the default handler upon successful capture. 
# 
# .param HTML 
# Save console buffer in HTML format.  Default is to save in ASCII. 
# 
# .param RTF 
# Save console buffer in RTF format.  Default is to save in ASCII. 
# 
# .param Test 
# Generate test pattern, save to file, then display files.
param ( 
    [string]$Path = "$env:temp\Console-$(Get-Date -Format yyyy-MM-dd_HHmmss).", 
    [switch]$Full, 
    [switch]$Preview, 
    [switch]$HTML, 
    [switch]$RTF, 
    [switch]$Test 
)

function Get-ConsoleBuffer { 
    #region header 
     
    Param ( 
        [string]$Path = "$env:temp\Console-$(Get-Date -Format yyyy-MM-dd_HHmmss).", 
        [switch]$Full, 
        [switch]$Preview, 
        [switch]$HTML, 
        [switch]$RTF, 
        [bool]$_boolFull = $false, 
        [bool]$_boolPreview = $false, 
        [bool]$_boolHTML = $false, 
        [bool]$_boolRTF = $false 
    )

    #endregion 
    #region html functions

    # The Windows PowerShell console host redefines DarkYellow and DarkMagenta colors and uses them as defaults. 
    # The redefined colors do not correspond to the color names used in HTML, so they need to be mapped to digital color codes. 
    function Normalize-HtmlColor ($color) {
        $color = switch ($color) {
            DarkYellow { "#eeedf0" }
            DarkMagenta { "#012456" }
            default { $color }
        }
        return $color
    }

    function Add-HtmlSpan ($Text, $ForegroundColor = "DarkYellow", $BackgroundColor = "DarkMagenta") { 
        $ForegroundColor = Normalize-HtmlColor $ForegroundColor
        $BackgroundColor = Normalize-HtmlColor $BackgroundColor

        $node = $script:xml.CreateElement("span")
        $node.SetAttribute('style', "font-family:Courier New;color:$ForegroundColor;background:$backgroundColor")
        $node.InnerText = $text
        $script:xml.LastChild.AppendChild($node) | Out-Null
    }

    function Add-HtmlBreak { $script:xml.LastChild.AppendChild($script:xml.CreateElement("br")) | Out-Null }

    #endregion 
    #region rtf functions 
   
    function Get-RtfColorIndex ([string]$color) {  
        switch ($color) {  
            'DarkBlue' {  2 }  
            'DarkGreen' {  3 }  
            'DarkCyan' {  4 }  
            'DarkRed' {  5 }  
            'DarkMagenta' {  6 }  
            'DarkYellow' {  7 }  
            'Gray' {  8 }  
            'DarkGray' {  9 }  
            'Blue' { 10 }  
            'Green' { 11 }  
            'Cyan' { 12 }  
            'Red' { 13 }  
            'Magenta' { 14 }  
            'Yellow' { 15 }  
            'White' { 16 }  
            'Black' { 17 }  
            default {  0 }  
        }  
    }  
    function New-RtfBuilder { 
        # Initialize the RTF string builder. 
        $script:rtfBuilder = [System.Text.StringBuilder]::new()

        # Set the desired font 
        $fontName = 'Lucida Console' 
        & {  
            # Append RTF header 
            $script:rtfBuilder.Append("{\rtf1\fbidis\ansi\ansicpg1252\deff0\deflang1033{\fonttbl{\f0\fnil\fcharset0 $fontName;}}") 
            $script:rtfBuilder.Append("`r`n")

            # Append RTF color table which will contain all Powershell console colors. 
            # script version 
            $script:rtfBuilder.Append('{\colortbl;red0\green0\blue128;\red0\green128\blue0;\red0\green128\blue128;\red128\green0\blue0;\red1\green36\blue86;\red238\green237\blue240;\red192\green192\blue192;\red128\green128\blue128;\red0\green0\blue255;\red0\green255\blue0;\red0\green255\blue255;\red255\green0\blue0;\red255\green0\blue255;\red255\green255\blue0;\red255\green255\blue255;\red0\green0\blue0;}')  
             
            # Append RTF document settings. 
            $script:rtfBuilder.Append('\viewkind4\uc1\pard\ltrpar\f0\fs23 ') 
        } | Out-Null
    }

    # Append line break to RTF builder 
    function Add-RtfBreak {  
        $script:rtfBuilder.Append("\shading0\cbpat$(Get-RtfColorIndex $currentBackgroundColor)\par`r`n") | Out-Null
    } 
     
    # append text to RTF builder 
    function Add-RtfBlock ($Text, $ForegroundColor = "DarkYellow", $BackgroundColor = "DarkMagenta") { 
        $ForegroundColor = Get-RtfColorIndex $ForegroundColor
        $BackgroundColor = Get-RtfColorIndex $BackgroundColor
         
        $script:rtfBuilder.Append("{\cf$ForegroundColor") | Out-Null
        $script:rtfBuilder.Append("\chshdng0\chcbpat$BackgroundColor") | Out-Null
        $script:rtfBuilder.Append("$Text}") | Out-Null
    }

    #endregion 
    #region core code

    # Check the host name and exit if the host is not the Windows PowerShell console host. 
    if ($host.Name -ne 'ConsoleHost') { 
        Write-Warning "$((Get-Variable -ValueOnly -Name MyInvocation).MyCommand)runs only in the console host. You cannot run this script in $($Host.Name)."
        return
    } 
     
    # handle [switch] parameters in nested functions 
    if (!$Full) { $Full = $_boolFull } 
    if (!$Preview) { $Preview = $_boolPreview } 
    if (!$HTML) { $HTML = $_boolHTML } 
    if (!$RTF) { $RTF = $_boolRTF }

    # initialize document name and object 
    if ($HTML) {  
        $script:xml = "<pre style='MARGIN: 0in 10pt 0in;line-height:normal' />"
        $Path += 'html'
        $RTF = $false
    } 
    elseif ($RTF) {  
        New-RtfBuilder
        $Path += 'rtf'
    } 
    else { 
        $fileBuilder = [System.Text.StringBuilder]::new()
        $Path += 'txt'
    }

    # Grab the console screen buffer contents using the Host console API. 
    $bufferWidth = $Host.UI.RawUI.BufferSize.Width 
    $bufferHeight = $Host.UI.RawUI.CursorPosition.Y

    # Line at which capture starts is either top of buffer or top of window. 
    if ($Full) { $startY = 0 } 
    elseif (($startY = $bufferHeight - $Host.UI.RawUI.WindowSize.Height) -lt 0) { $startY = 0 }

    $rec = [System.Management.Automation.Host.Rectangle]::new(0, $startY, ($bufferWidth - 1), $bufferHeight)
    $buffer = $Host.UI.RawUI.GetBufferContents($rec)

    # Iterate through the lines in the console buffer. 
    for ($i = 0; $i -lt $bufferHeight; $i++) { 
        $stringBuilder = [System.Text.StringBuilder]::new()

        if ($HTML -or $RTF) { 
            # Track the colors to identify spans of text with the same formatting. 
            $currentForegroundColor = $buffer[$i, 0].ForegroundColor
            $currentBackgroundColor = $buffer[$i, 0].BackgroundColor
        }

        for ($j = 0; $j -lt $bufferWidth; $j++) { 
            $cell = $buffer[$i, $j]

            # If the colors change, generate an HTML span and append it to the HTML string builder. 
            if (($HTML -or $RTF) -and (($cell.ForegroundColor -ne $currentForegroundColor) -or ($cell.BackgroundColor -ne $currentBackgroundColor))) {

                if ($HTML) { Add-HtmlSpan -Text $stringBuilder.ToString() -ForegroundColor $currentForegroundColor -BackgroundColor $currentBackgroundColor } 
                elseif ($RTF) { Add-RtfBlock -Text $stringBuilder.ToString() -ForegroundColor $currentForegroundColor -BackgroundColor $currentBackgroundColor }

                # Reset the span builder and colors. 
                $stringBuilder = [System.Text.StringBuilder]::new()
                $currentForegroundColor = $cell.ForegroundColor
                $currentBackgroundColor = $cell.BackgroundColor
            }

            if ($RTF) { 
                switch ($cell.Character) {  
                    "`t" { $rtfChar = '\tab' }  
                    '\' { $rtfChar = '\\' }  
                    '{' { $rtfChar = '\{' }  
                    '}' { $rtfChar = '\}' }  
                    default { $rtfChar = $cell.Character } 
                } 

                $stringBuilder.Append($rtfChar) | Out-Null
            } 
            else {  $stringBuilder.Append($cell.Character) | Out-Null } 
        }

        if ($HTML) { 
            Add-HtmlSpan -Text $stringBuilder.ToString() -ForegroundColor $currentForegroundColor -BackgroundColor $currentBackgroundColor
            Add-HtmlBreak
        } 
        elseif ($RTF) { 
            Add-RtfBlock -Text $stringBuilder.ToString() -ForegroundColor $currentForegroundColor -BackgroundColor $currentBackgroundColor
            Add-RtfBreak
        } 
        else { 
            $fileBuilder.Append(($stringBuilder.ToString() -replace ".$", "`r`n")) | Out-Null
        } 
    }

    & { 
        if ($HTML) { $script:xml.OuterXml } 
        elseif ($RTF) { $script:rtfBuilder.ToString() + '}' } 
        else { $fileBuilder.ToString() } 
    } | Out-File -FilePath $Path -Encoding ascii
     
    if (Test-Path -Path $Path) { 
        if ($Preview) { Invoke-Item $Path } 
        $Path
    } 
    else { Write-Warning "Unable to save to -Path $Path" }

    #endregion 
}

#  if we execute this file instead of dot-source it 
if ($MyInvocation.invocationName -ne '.') {  
   
    if ($Test) { 
        [System.Enum]::GetValues('System.ConsoleColor') | % { Write-Host ((" " + $_.ToString() + (" " * 8)).SubString(0, 11) + " ") -NoNewline } 
        Write-Host ''
        foreach ($f in [System.Enum]::GetValues('System.ConsoleColor') ) {  
            foreach ($b in [System.Enum]::GetValues('System.ConsoleColor')) {  
                Write-Host -ForegroundColor $f -BackgroundColor $b " $($f.tostring().substring(0,3)) on $($b.tostring().substring(0,3)) " -NoNewline
            }  
            Write-Host ''
        }

        & {  
            Get-ConsoleBuffer -HTML
            Get-ConsoleBuffer -RTF
            Get-ConsoleBuffer
        } | % { 
            Invoke-Item $_
            Out-Host -InputObject $_
        } 
    } 
    else { 
        Get-ConsoleBuffer -_boolFull $Full -_boolHtml $HTML -_boolRTF $RTF -_boolPreview $Preview -Path $Path
    } 
}