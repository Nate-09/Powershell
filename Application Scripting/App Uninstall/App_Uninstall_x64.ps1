<#
.SYNOPSIS

Uninstalls any application from the localhost when found to be installed
on a local system.

.DESCRIPTION

This script will uninstall the specified application using the variable
specified. This should provide an easy to manage and maintain solution
for uninstalling one off applications where necessary.

This was originally designed to aide the ITOps Team with application 
management.

.EXAMPLE

PS C:\> .\App_Uninstall.ps1
PS C:\> Get-Help .\App_Uninstall.ps1

.INPUTS

This script requires the inputs to be added directly into the script as 
variables. Other than those this script requires no further inputs.

.OUTPUTS

This script will write an output within the shell advising on its state.

.NOTES
 Script version: 1.0
 PowerShell Version: 5.1.19041.1023
 Tags: Application, Uninstall, POWERSHELL, x86, x64, KACE SMA
 PS Versioning:
    1.0 - RTM


    
        ***************** UPDATE the below information ONLY *****************                               
#>

$Application = "Zoom"

<#
        ***************** DO NOT ALTER the below information *****************                                  
#>

$app = Get-Package -Provider Programs -IncludeWindowsInstaller -Name $Application
    
If ($app){
    Uninstall-Package -Name $Application
	write-host "$Application was found and uninstalled"
}else{
	write-host "$Application was not found, please look at manually uninstalling $Application if you believe it to be installed"
}