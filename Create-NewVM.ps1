[CmdletBinding()]
param(

    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [int64]$CPU,

    [Parameter(Mandatory = $true)]
    [int64]$Memory,

    [Parameter(Mandatory = $true)]
    [uint64]$Storage,

    [Parameter(Mandatory = $true)]
    [ValidateSet('External Switch', 'Internal Switch', 'Private Switch')]
    [string]$SwitchName,

    [Parameter(Mandatory = $true)]
    [string]$WindowsISO,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Windows Server 2022 Datacenter Evaluation', 'Windows Server 2022 Datacenter Evaluation (Desktop Experience)')]
    [string]$WindowsEdition,

    [string]$AdminPassword

)

# AutoBuild Properties

# Check we have Convert-WindowsImage.ps1
If (-not (Test-Path -Path .\Convert-WindowsImage.ps1 -PathType Leaf)) {
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/MicrosoftDocs/Virtualization-Documentation/master/hyperv-tools/Convert-WindowsImage/Convert-WindowsImage.ps1' -OutFile .\Convert-WindowsImage.ps1
}

# Random Build ID
$BuildID = (Get-Random)

# Base Keys
# Install with KMS, Activate with AMVA
$WindowsKMS = 'WX4NM-KYWYW-QJJR4-XV3QB-6VM33'
$WindowsAMVA = 'W3GNR-8DDXR-2TFRP-H8P33-DV9BG'

# Quick Check for inflight and duplicate builds
if (Test-Path -Path "C:\Temp\HVA\$Name") {
    $Name = $Name + $BuildID
}
elseif (Get-VM | Where-Object Name -EQ $Name) {
    $Name = $Name + $BuildID
}

# Trim and clean name
$Name = $Name -replace '\s', '' -replace '^(.{0,14}).*', '$1'

# Setup Working Directories for build
$TempDirectory = "C:\Temp\HVA\$Name"
$UnattendDirectory = "C:\Temp\HVA\$Name\Unattend"
New-Item -Path $TempDirectory -ItemType Directory -Force | Out-Null
New-Item -Path $UnattendDirectory -ItemType Directory -Force | Out-Null
## Set VHD Path
$VHDPath = (Get-WmiObject -Namespace root\virtualization\v2 Msvm_VirtualSystemManagementServiceSettingData).DefaultVirtualHardDiskPath + "\$Name.vhdx"

# User Details
# Administrator
$UserName = 'Administrator'
if (-not $AdminPassword) {
    $AdminPassword = -join (33..126 | ForEach-Object { [char]$_ } | Get-Random -C 24)
}
# Secure String and Credential
$Password = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($UserName, $Password)

# START BUILD

Write-Host "[$BuildID] - $(Get-date) - Build Start" -ForegroundColor Green

# Create Answer File
$UnattendTemplate = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ProductKey></ProductKey>
            <ComputerName></ComputerName>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SkipAutoActivation>true</SkipAutoActivation>
        </component>
        <component name="Microsoft-Windows-SQMApi" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <CEIPEnabled>0</CEIPEnabled>
        </component>
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Path>net user administrator /active:yes</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <SkipMachineOOBE>true</SkipMachineOOBE>
                <SkipUserOOBE>true</SkipUserOOBE>
            </OOBE>
            <UserAccounts>
                <AdministratorPassword>
                    <Value></Value>
                    <PlainText>true</PlainText>
                </AdministratorPassword>
            </UserAccounts>
        </component>
    </settings>
</unattend>
'@

# Template Set
$xml = [xml]$UnattendTemplate
# Answer destination
$UnattendPath = "$UnattendDirectory\unattend.xml"
# Define unattended settings
$xml.unattend.settings[0].component[0].ComputerName = $Name
$xml.unattend.settings[0].component[0].ProductKey = $WindowsKMS
$xml.unattend.settings[1].component.UserAccounts.AdministratorPassword.Value = $AdminPassword
# Save and Write answers
$writer = New-Object System.XMl.XmlTextWriter($UnattendPath, [System.Text.Encoding]::UTF8)
$writer.Formatting = [System.Xml.Formatting]::Indented
$xml.Save($writer)
$writer.Dispose()

# Create VHDX from ISO
Write-Host "[$BuildID] - $(Get-date) - Brewing $Name with $WindowsEdition" -ForegroundColor Yellow

# Import Convert-WindowsImage.ps1 function for use
. .\Convert-WindowsImage.ps1

# Compile Image
Convert-WindowsImage -SourcePath $WindowsISO -Edition $WindowsEdition -TempDirectory $TempDirectory -UnattendPath $UnattendPath -SizeBytes $Storage -DiskLayout UEFI -VHDPath $VHDPath -VHDFormat VHDX -RemoteDesktopEnable

# Setup new VM
$SetupVM = New-VM -Name $Name -Generation 2 -MemoryStartupBytes $Memory -VHDPath $VHDPath -SwitchName $SwitchName
$SetupVM | Set-VMProcessor -Count $CPU
$SetupVM | Get-VMIntegrationService -Name "Guest Service Interface" | Enable-VMIntegrationService -Passthru
$SetupVM | Set-VMMemory -DynamicMemoryEnabled $true
$SetupVM | Set-VM -AutomaticCheckpointsEnabled $false
$SetupVM | Start-VM

# Wait for installation complete
Wait-VM -Name $Name -For Heartbeat

## START CONFIG ##

do {
    $StartSession = New-PSSession -VMName $Name -Credential $Credential -ErrorAction SilentlyContinue
} until ($StartSession.State -eq "Opened")

# Connect to New VM and enable Remote Management
Write-Host "[$BuildID] - $(Get-date) - Setting up $Name" -ForegroundColor Yellow

# Performance Tuning and Initial Setup
Invoke-Command -Session $StartSession -ScriptBlock {
    # Disable Realtime Antivirus monitoring
    Set-MpPreference -DisableRealtimeMonitoring $true
    # Set High performance Power Plan
    powercfg /SETACTIVE 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
}

# Setup Ansible for Host Management
Write-Host "[$BuildID] - $(Get-date) - Enabling Ansible Management on $Name" -ForegroundColor Yellow
Invoke-Command -Session $StartSession -ScriptBlock {
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1'))
} | Out-Null

# Upgrade OS from Eval to Full using KMS Key
if ($WindowsEdition -match "Desktop") {
    Write-Host "[$BuildID] - $(Get-date) - Converting Windows Server Evaluation to Full" -ForegroundColor Yellow
    Invoke-Command -Session $StartSession -ScriptBlock {
        dism /online /Set-Edition:ServerDatacenter /ProductKey:WX4NM-KYWYW-QJJR4-XV3QB-6VM33 /AcceptEula /Quiet
    }
    
}
else {
    Write-Host "[$BuildID] - $(Get-date) - Converting Windows Server Evaluation to Full" -ForegroundColor Yellow
    Invoke-Command -Session $StartSession -ScriptBlock {
        dism /online /Set-Edition:ServerDatacenterCor /ProductKey:WX4NM-KYWYW-QJJR4-XV3QB-6VM33 /AcceptEula /Quiet
    }
    
}

# Create new session after reboot and continue
Wait-VM -Name $Name -For Heartbeat
do {
    Start-Sleep -Seconds 15
    $FinalSession = New-PSSession -VMName $Name -Credential $Credential -ErrorAction SilentlyContinue
} until ($FinalSession.State -eq "Opened")

# Set AVMA Key
Write-Host "[$BuildID] - $(Get-date) - Setting AVMA Key on $Name" -ForegroundColor Yellow
Invoke-Command -Session $FinalSession -ScriptBlock {
    cscript.exe $env:SystemRoot\System32\slmgr.vbs /ipk W3GNR-8DDXR-2TFRP-H8P33-DV9BG
    # Activate Windows
    cscript.exe $env:SystemRoot\System32\slmgr.vbs /ato
    # Return activation state
    cscript.exe $env:SystemRoot\System32\slmgr.vbs /dli
} | Out-Null

# Waiting for Heartbeat prior to finish
Wait-VM -Name $Name -For Heartbeat

# END BUILD

## Wrap it up
Write-Host "[$BuildID] - $(Get-date) - Credentials: $UserName\$AdminPassword" -ForegroundColor Yellow
Write-Host "[$BuildID] - $(Get-date) - $Name is now ready" -ForegroundColor Green