Import-Module -Name WindowsImageTools -Force

# WIM2VHD conversion of Windows 10 and Windows Server 2016 ISO images 
$commonParams = @{
    'Dynamic'     = $true
    'Verbose'     = $true
    'Force'       = $true
    'Unattend'    = (New-UnattendXml -AdminPassword 'LocalP@ssword' -LogonCount  1 -EnableAdministrator)
    'filesToInject' = '.\Resources\FilesToInject\'
}
$vhds = @(
    @{
        'SourcePath' = '.\..\ISO\en_windows_10_multiple_editions_x64_dvd_6846432.iso'
        'DiskLayout' = 'UEFI'
        'index'    = 1
        'size'     = 100Gb
        'Path'     = '.\..\Sysprep Images\Win10_Pro.vhdx'
    }, 
    @{
        'SourcePath' = '.\..\iso\en_windows_server_2016_x64_dvd_9718492.iso'
        'DiskLayout' = 'UEFI'
        'index'    = 1
        'size'     = 100Gb
        'Path'     = '.\..\Sysprep Images\WinSvr2016_CoreStd.vhdx'
    }, 
    @{
        'SourcePath' = '.\..\iso\en_windows_server_2016_x64_dvd_9718492.iso'
        'DiskLayout' = 'UEFI'
        'index'    = 2
        'size'     = 100Gb
        'Path'     = '.\..\Sysprep Images\WinSvr2016_GuiStd.vhdx'
    }
)
foreach ($VhdParms in $vhds)
{
    Convert-Wim2VHD @VhdParms @commonParams #-WhatIf
}
