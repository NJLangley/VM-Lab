#Requires -Version 4

function Get-WimImage {
<# 
 .SYNOPSIS
  Function/tool to return information on images contained in a Wim file

 .DESCRIPTION
  This Script/Function/tool returns information on images contained in a Wim file.
  For more information on Wim files see http://technet.microsoft.com/en-us/library/cc749478%28v=ws.10%29.aspx
  Wim file information is available via the Deployment Image Servicing and Management (DISM) Command-Line tool
  For more information on Dism.exe see http://msdn.microsoft.com/en-us/library/jj980032%28v=winembedded.81%29.aspx
  The tool returns the information as text. This script/function/tool extracts information from the Dism.exe output 
  text and returns a PS Object containing the same information. This makes it easily available for further 
  processing or reporting.
  Similar information is available from the Get-WindowsImage Cmdlet of the DISM PS module, 
  but this script/tool returns more details.

 .PARAMETER WimFile
  Path to Windows Imaging File Format (WIM) file

 .EXAMPLE
  Get-WimImage -WimPath H:\sources\install.wim 
  This example returns a list of images in the WIM file

 .EXAMPLE
  $Images = Get-WimImage H:\sources\install.wim | Select Index,Name,Size,Version,Languages
  $Images | FT -a                           # Output to console
  $Images | Out-GridView                    # Output to Powershell_ISE Grid View
  $Images | Export-Csv .\Images.csv -NoType # Export to CSV file

 .EXAMPLE
  $DriveLetters = (Get-Volume).DriveLetter
  $ISO = Mount-DiskImage -ImagePath E:\Install\ISO\Win10\en_windows_server_technical_preview_x64_dvd_5554304.iso -PassThru
  $ISODriveLetter = (Compare-Object -ReferenceObject $DriveLetters -DifferenceObject (Get-Volume).DriveLetter).InputObject
  $Images = Get-WimImage "$($ISODriveLetter):\sources\install.wim"
  Dismount-DiskImage $ISO.ImagePath
  $SelectedProps = $Images | Select Index,Name,@{N='Size(GB)';E={[Math]::Round($_.Size/1GB,2)}},Version,Languages 
  $SelectedProps | FT -a # Output to console
  $SelectedProps | Out-GridView # Output to Powershell_ISE Grid View
  $SelectedProps | Export-Csv .\Images.csv -NoType

 .EXAMPLE
    $ISOFolder = 'e:\install\ISO\win10'
    $Images = @()
    (Get-ChildItem -Path $ISOFolder -Filter *.iso).FullName | % {
        $DriveLetters = (Get-Volume).DriveLetter
        $ISO = Mount-DiskImage -ImagePath $_ -PassThru
        $ISODriveLetter = (Compare-Object -ReferenceObject $DriveLetters -DifferenceObject (Get-Volume).DriveLetter).InputObject
        $Result = Get-WimImage "$($ISODriveLetter):\sources\install.wim"
        $Result | Add-Member 'ISOFile' (Split-Path -Path $ISO.ImagePath -Leaf)
        $Images += $Result
        Dismount-DiskImage $ISO.ImagePath
        Start-Sleep -Seconds 1
    }
    $Images | Select ISOFile,Index,Name,@{N='Size(GB)';E={[Math]::Round($_.Size/1GB,2)}},Version,Languages | FT -a 

 .LINK
  https://superwidgets.wordpress.com/category/powershell/
  http://superwidgets.wordpress.com/2015/01/07/powershell-scripttool-to-get-os-image-information-from-wim-file/

 .INPUTS
  Path to Windows Imaging File Format (WIM) file

 .OUTPUTS
  PS Object containing the following properties (example):
    WimFile          : H:\sources\install.wim
    Index            : 4
    Name             : Windows Server vNext SERVERDATACENTER
    Description      : Windows Server vNext SERVERDATACENTER
    Size             : 12264411641
    Bootable         : No
    Architecture     : x64
    Hal              : acpiapic
    Version          : 6.4.9841
    ServicePackBuild : 0
    ServicePackLevel : 0
    Edition          : ServerDatacenter
    Installation     : Server
    ProductType      : ServerNT
    ProductSuite     : Terminal Server
    SystemRoot       : WINDOWS
    Directories      : 18576
    Files            : 79539
    Created          : 9/13/2014 4:34:01 AM
    Modified         : 9/13/2014 4:34:41 AM
    Languages        : en-US (Default)

 .NOTES
  Function by Sam Boutros
  v1.0 - 1/7/2014

#>

    [CmdletBinding(ConfirmImpact='Low')] 
    Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeLine=$true,
                   ValueFromPipeLineByPropertyName=$true,
                   Position=0)]
            [ValidateScript({ Test-Path $_ })]
            [String]$WimPath
    )

    $RawImages = Dism.exe /Get-WimInfo /WimFile:$WimPath
    if ($RawImages[5] -match 'Error') {
        Write-Warning "Are you sure '$WimPath' is a valid .wim file?"
        Write-Warning ($RawImages | Out-String)
        break
    }
    $Images = @()
    for ($i=0; $i -lt ($RawImages.Count-7)/5; $i++) {
        $Image = New-Object -TypeName psobject
        $Image | Add-Member 'WimFile' $WimPath
        $Image | Add-Member 'Index' (0 + $RawImages[($i*5)+6].Split(':')[1].trim())
        $Image | Add-Member 'Name' $RawImages[($i*5)+7].Split(':')[1].trim()
        $Image | Add-Member 'Description' $RawImages[($i*5)+8].Split(':')[1].trim()
        $Image | Add-Member 'Size' (0 + $RawImages[($i*5)+9].Split(':')[1].trim().Split(' ')[0].Replace(',',''))
        $Images += $Image 
    }

    $Images | % {
        $ImageInfo = Dism.exe /Get-WimInfo /WimFile:$WimPath /index:$($_.Index)
        $_ | Add-Member 'Bootable'         $ImageInfo[10].Split(':')[1].trim()
        $_ | Add-Member 'Architecture'     $ImageInfo[11].Split(':')[1].trim()
        $_ | Add-Member 'Hal'              $ImageInfo[12].Split(':')[1].trim()
        $_ | Add-Member 'Version'          $ImageInfo[13].Split(':')[1].trim()
        $_ | Add-Member 'ServicePackBuild' $ImageInfo[14].Split(':')[1].trim()
        $_ | Add-Member 'ServicePackLevel' $ImageInfo[15].Split(':')[1].trim()
        $_ | Add-Member 'Edition'          $ImageInfo[16].Split(':')[1].trim()
        $_ | Add-Member 'Installation'     $ImageInfo[17].Split(':')[1].trim()
        $_ | Add-Member 'ProductType'      $ImageInfo[18].Split(':')[1].trim()
        $_ | Add-Member 'ProductSuite'     $ImageInfo[19].Split(':')[1].trim()
        $_ | Add-Member 'SystemRoot'       $ImageInfo[20].Split(':')[1].trim()
        $_ | Add-Member 'Directories' (0 + $ImageInfo[21].Split(':')[1].trim())
        $_ | Add-Member 'Files'       (0 + $ImageInfo[22].Split(':')[1].trim())
        $_ | Add-Member 'Created'  $([DateTime]$ImageInfo[23].Substring(10,$ImageInfo[23].Length-10).Replace('-',''))
        $_ | Add-Member 'Modified' $([DateTime]$ImageInfo[24].Substring(11,$ImageInfo[24].Length-11).Replace('-',''))
        $_ | Add-Member 'Languages' $(
            $Languages = @()
            for ($i=26; $i -lt $ImageInfo.Length-2; $i++) { $Languages += $ImageInfo[$i].trim() }
            $Languages -join ', '
        )
    }
    
    $Images 
}