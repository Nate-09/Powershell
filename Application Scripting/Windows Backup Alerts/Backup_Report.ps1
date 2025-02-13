Add-PSSnapin Windows.ServerBackup -ErrorAction SilentlyContinue

#######################################
#-------- Variables to change --------#

$Servers = New-PSSession -Computername HOST
Invoke-Command -Session $Servers {

# Set your Company name
$Company = "COMPANY TEST"

# Set the recipient/sender email-address
$MailMessageTo = "backups@test.com.au" # List of users to email your report to (separate by comma)
$MailMessageFrom = "backups@test.com.au" # Enter the email you would like the report sent from
$MailMessageSMTPServer = "SMTP SERVER" # Enter your own SMTP server DNS name / IP address here
$MailMessagePriority = "Normal" # Low/Normal/High
$HTMLMessageSubject = $env:computername+": Backup Report - "+(Get-Date) # Email Subject


#---- Don't change anything below ----#
#######################################

Try {
$CurrentTime = (Get-Date).ToString("yyyy-MM-dd HH:mm")
$Computer = Get-Content env:computername
$WBJob = Get-WBJob -Previous 1
$WBSummary = Get-WBSummary
$WBLastSuccess = ($WBSummary.LastSuccessfulBackupTime).ToString("yyyy-MM-dd HH:mm")
$WBResult = $WBSummary.LastBackupResultHR
$WBErrorMsg = $WBJob.ErrorDescription + "`n" + $WBSummary.DetailedMessage
$WBStartTime = $WBJob.StartTime
$WBEndTime = $WBJob.EndTime
$WBDuration = (New-TimeSpan -Start $WBStartTime -End $WBEndTime)



#$Password = ConvertTo-SecureString $MailPassword -AsPlainText -Force
#$Credentials = New-Object System.Management.Automation.PSCredential ($MailUser, $Password)

Function FormatBytes
{
 Param
 (
 [System.Int64]$Bytes
 )
 [string]$BigBytes = ""
 #Convert to TB
 If ($Bytes -ge 1TB) {$BigBytes = [math]::round($Bytes / 1TB, 2); $BigBytes += " TB"}
 #Convert to GB
 ElseIf ($Bytes -ge 1GB) {$BigBytes = [math]::round($Bytes / 1GB, 2); $BigBytes += " GB"}
 #Convert to MB
 ElseIf ($Bytes -ge 1MB) {$BigBytes = [math]::round($Bytes / 1MB, 2); $BigBytes += " MB"}
 #Convert to KB
 ElseIf ($Bytes -ge 1KB) {$BigBytes = [math]::round($Bytes / 1KB, 2); $BigBytes += " KB"}
 #If smaller than 1KB, leave at bytes.
 Else {$BigBytes = $Bytes; $BigBytes += " Bytes"}
 Return $BigBytes
}

Function Log-BackupItems
{
    Param
    (
        [System.String]$Name,
        [System.String]$Status,
        [System.Int64]$Bytes
    )
    $Item = New-Object System.Object;
    $Item | Add-Member -Type NoteProperty -Name "Name" -Value $Name;
    $Item | Add-Member -Type NoteProperty -Name "Status" -Value $Status;
    $Item | Add-Member -Type NoteProperty -Name "Size" -Value (FormatBytes -Bytes $Bytes);
    Return $Item;
}

$results=@()
$WBJob | % {
 $_.JobItems | % {
 $BackupItem = $null
 If ($_.Name -eq 'VolumeList') {
 $_ | % {$_.SubItemList | % {
 $BackupItem = Log-BackupItems -Name $_.Name -Status $_.State -Bytes $_.TotalBytes
 $results += $BackupItem
 }}
 } 
 Else {
 $_ | % {
 $BackupItem = Log-BackupItems -Name $_.Name -Status $_.State -Bytes $_.TotalBytes
 $results += $BackupItem
 }
 }
 }
}

# Change Result of 0 to Success in green text and any other result as Failure in red text
If ($WBResult -eq 0) { $WBResult = "Successful"}
Else {$WBResult = "Failed"}

# Assemble the HTML Report
$HTMLMessage = @"
    <!DOCTYPE html>
    <html>
    <head>
    <title>$Company Backup Report for $Computer</title>
    <style>
    body { font-family: Verdana, Geneva, Arial, Helvetica, sans-serif; font-size: 12px }
    h3{ clear: both; font-size: 150%; margin-left: 20px;margin-top: 30px; }
    table { padding: 15px 0 20px; width: 500px; text-align: left; }
    td, th { padding: 0 20px 0 0; margin 0; text-align: left; }
    th { margin-top: 15px }
    a, a:visited { color: #2ea3f2; text-decoration: none; }
    #Report { width: 600px; }
    #Successful { color: green }
    #Failed { color: red }
    </style>
    </head>
    <body>
    <div id="Report">
    <p><h3><a>$Company Backup Report for $Computer</a></p></h3>
    <table id="summary"><tbody>
    <tr><td>Todays date:</td>
    <td>$CurrentTime</td></tr>
    <tr><td>Last Successful Backup:</td>
    <td>$WBLastSuccess</td></tr>
    <tr><td>Start time last backup:</td>
    <td>$WBStartTime</td></tr>
    <tr><td>End time last backup:</td>
    <td>$WBEndTime</td></tr>
    <tr><td>Duration last backup:</td>
    <td>$WBDuration</td></tr>
    <tr><td>Backup Result:</td>
    <td><b id="$WBResult">$WBResult</b></td></tr>
    <tr><td>Error Message (if applicable):</td>
    <td>$WBErrorMsg</td></tr></tbody></table>

    $(
     $html = $results | ConvertTo-HTML -Fragment
     $xml=[xml]$html
     $attr=$xml.CreateAttribute('id')
     $attr.Value='items'
     $xml.table.Attributes.Append($attr) | out-null
     $html=$xml.OuterXml | out-string
     $html
    )
    </div>
    </body>
    </html>
"@

# Email the report
$MailMessageOptions = @{
    From            = "$MailMessageFrom"
    To              = "$MailMessageTo"
    Subject         = "$WBResult : $HTMLMessageSubject"
    BodyAsHTML      = $True
    Body            = "$HTMLMessage"
    Priority        = "$MailMessagePriority"
    SmtpServer      = "$MailMessageSMTPServer"
}
Send-MailMessage @MailMessageOptions
}

Catch {
$MailMessageOptions = @{
    From            = "$MailMessageFrom"
    To              = "$MailMessageTo"
    Subject = "Failed Backup on $Computer"
    BodyAsHTML      = $True
    Body = "The backup script failed to run!"
    Priority        = "$MailMessagePriority"
    SmtpServer      = "$MailMessageSMTPServer"
    }
    Send-MailMessage @MailMessageOptions
}
}