Function write-log { 
    #Define and validate parameters
    [CmdletBinding()]
    Param(
          #Path to the log file
          [parameter(Mandatory=$True)]
          [String]$LogFile,
 
          #The information to log
          [parameter(Mandatory=$True)]
          [String]$Value,
 
          #The source of the error
          [parameter(Mandatory=$True)]
          [String]$Component,
 
          #The severity (1 - Information, 2- Warning, 3 - Error)
          [parameter(Mandatory=$True)]
          [ValidateRange(1,3)]
          [Single]$Severity
          )
 
 
    #Obtain UTC offset
    $DateTime = New-Object -ComObject WbemScripting.SWbemDateTime 
    $DateTime.SetVarDate($(Get-Date))
    $UtcValue = $DateTime.Value
    $UtcOffset = $UtcValue.Substring(21, $UtcValue.Length - 21)
 
 
    #Create the line to be logged
    $LogLine =  "<![LOG[$Value]LOG]!>" +`
                "<time=`"$(Get-Date -Format HH:mm:ss.fff)$($UtcOffset)`" " +`
                "date=`"$(Get-Date -Format M-d-yyyy)`" " +`
                "component=`"$Component`" " +`
                "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
                "type=`"$Severity`" " +`
                "thread=`"$($pid)`" " +`
                "file=`"`">"
 
    #Write the line to the passed log file
    Out-File -InputObject $LogLine -Append -NoClobber -Encoding Default -FilePath $LogFile -WhatIf:$False 
}

$Logfile = "$env:SystemRoot\logs\Remove-Apps.log"

if(Test-Path $Logfile){
    Remove-Item $Logfile -Force -ErrorAction SilentlyContinue
}

## Configure the apps to be removed
$AppsList = "Microsoft.3DBuilder",
"Microsoft.BingWeather",
"Microsoft.DesktopAppInstaller",
"Microsoft.Getstarted",
"Microsoft.Messaging",
"Microsoft.Microsoft3DViewer",
"Microsoft.MicrosoftOfficeHub",
"Microsoft.MicrosoftSolitaireCollection",
"Microsoft.Office.OneNote",
"Microsoft.OneConnect",
"Microsoft.People",
"Microsoft.SkypeApp",
"Microsoft.StorePurchaseApp",
"Microsoft.Wallet",
"Microsoft.WindowsAlarms",
"Microsoft.WindowsCamera",
"microsoft.windowscommunicationsapps",
"Microsoft.WindowsFeedbackHub",
"Microsoft.WindowsMaps",
"Microsoft.WindowsSoundRecorder",
"Microsoft.XboxApp",
"Microsoft.XboxGameOverlay",
"Microsoft.XboxIdentityProvider",
"Microsoft.XboxSpeechToTextOverlay",
"Microsoft.ZuneMusic",
"Microsoft.BingFinance",
"Microsoft.BingNews",
"Microsoft.Print3D",
"Microsoft.Xbox.TCUI",
"Microsoft.ZuneVideo"

$capabilities = "App.Support.ContactSupport~~~~0.0.1.0",
"App.Support.QuickAssist~~~~0.0.1.0"

 
##Remove the Apps listed above or report if app not present
ForEach ($App in $AppsList)
{
    write-log -LogFile $Logfile -Severity 1 -Value "$App selected for removal" -Component "Selecting App"

    $ProPackageFullName = (Get-AppxProvisionedPackage -Online | Where {$_.Displayname -eq $App}).PackageName
    $PackageFullName = (Get-AppxPackage -allusers $App).PackageFullName
 
    If ($PackageFullName) {
        write-log -LogFile $Logfile -Severity 1 -Value "Found $app" -Component "Remove-AppxPackage"
        try{
            write-log -LogFile $Logfile -Severity 1 -Value "Trying to remove $app" -Component "Remove-AppxPackage"
            Remove-AppxPackage -Package $PackageFullName
            write-log -LogFile $Logfile -Severity 1 -Value "Successfully removed $app" -Component "Remove-AppxPackage"
        }
        catch{
            write-log -LogFile $LogFile "Could not remove $app" -Component "Remove-AppxPackage" -Severity 3
            write-log -LogFile $LogFile "Error: $($_.Exception.Message)" -Component "Remove-AppxPackage" -Severity 3
            write-log -LogFile $LogFile "$($_.InvocationInfo.PositionMessage)" -Component "Remove-AppxPackage" -Severity 3
        }
    }
 
    Else {
        write-log -LogFile $Logfile -Severity 3 -Value "$app not found, continuing to next app" -Component "Remove-AppxPackage"
    }

    If ($ProPackageFullName) {
        write-log -LogFile $Logfile -Severity 1 -Value "Found $app" -Component "Remove-AppxProvisionedPackage"
        try{
            write-log -LogFile $Logfile -Severity 1 -Value "Trying to remove $app" -Component "Remove-AppxProvisionedPackage"
            Remove-AppxProvisionedPackage -Online -PackageName $ProPackageFullName
            write-log -LogFile $Logfile -Severity 1 -Value "Successfully removed $app" -Component "Remove-AppxProvisionedPackage"
        }
        catch{
            write-log -LogFile $LogFile "Could not remove $app" -Component "Remove-AppxProvisionedPackage" -Severity 3
            write-log -LogFile $LogFile "Error: $($_.Exception.Message)" -Component "Remove-AppxProvisionedPackage" -Severity 3
            write-log -LogFile $LogFile "$($_.InvocationInfo.PositionMessage)" -Component "Remove-AppxProvisionedPackage" -Severity 3
        }
    }
 
    Else {
        write-log -LogFile $Logfile -Severity 3 -Value "$app not found, continuing to next app" -Component "Remove-AppxProvisionedPackage"
    }
}

ForEach ($Capability in $Capabilities) {
    write-log -LogFile $Logfile -Severity 1 -Value "$Capability selected for removal" -Component "Remove-WindowsCapability"
    try{
        write-log -LogFile $Logfile -Severity 1 -Value "Removing $Capability" -Component "Remove-WindowsCapability"
        Remove-WindowsCapability -online -name $Capability
        write-log -LogFile $Logfile -Severity 1 -Value "Successfully remove $Capability" -Component "Remove-WindowsCapability"
    }
    catch{
        write-log -LogFile $LogFile "Could not remove $Capability" -Component "Remove-WindowsCapability" -Severity 3
        write-log -LogFile $LogFile "Error: $($_.Exception.Message)" -Component "Remove-WindowsCapability" -Severity 3
        write-log -LogFile $LogFile "$($_.InvocationInfo.PositionMessage)" -Component "Remove-WindowsCapability" -Severity 3
    }
}
