Function Get-DisabledUserReport{

[CmdletBinding()]
    param(
    #[Parameter(Mandatory=$True,ValueFromPipeline=$False)]
    [Parameter(Mandatory=$False,ValueFromPipeline=$False)]
    [Parameter(ParameterSetName=’String’,Mandatory=$True,ValueFromPipeline=$False)]
    [String]$SiteID,
    [Parameter(ParameterSetName=’String’,Mandatory=$True,ValueFromPipeline=$False)]
	[String]$BrandID,
	[Parameter(ParameterSetName=’String’,Mandatory=$True,ValueFromPipeline=$False)]
    [String]$Region
    )

Begin {
$oldDate = [DateTime]::Today.AddDays(-30) 
$warnDate = [DateTime]::Today.AddDays(-23) 
$delUsers = @() 
$warnUsers = @() 
$30daysUsers = @() 
$OrgUnits = Get-ADOrganizationalUnit -Filter * | Select DistinguishedName

        if($PSCmdlet.ParameterSetName -eq "String"){
            $SearchBases += ($OrgUnits | ?{($_.DistinguishedName.split(",")[0] -match $BrandID) -and ($_.DistinguishedName.split(",")[1] -match $SiteID)}).DistinguishedName
        } 
#Retrieves disabled user accounts and stores in an array 
$disabledUsers = Get-ADUser -filter {(Enabled -eq $False) -and (extensionAttribute7 -eq "U")} -Searchbase $SearchBases -Properties Name,SID,Enabled,LastLogonDate,Modified,info,description 

    }
    PROCESS{  

    Foreach($name in $disabledUsers){
        $Message = ""
        switch ($name.Info){
            {$_ -match "WHITELIST"}{$Message = "$($name.Name) is whitelisted!" ; $wlistUsers += $name}
            {$_ -notmatch "WHITELIST" -and $name.Modified -le $warnDate}{$Message = "$($name.Name) will be deleted on the next run!" ; $warnUsers += $name}
            {$_ -notmatch "WHITELIST" -and $name.Modified -le $oldDate}{$Message = "$($name.Name) is older then 30 days!" ; $delUsers += $Users}
            {$_ -notmatch "WHITELIST" -and $name.Modified -gt $oldDate}{$Message = "$($name.Name) was modified less than 30 days ago!" ; $30daysUsers += $name}         
        }
        
    }
           
}
END{
    $Users
    $Users.Count
    Write-Host $AccountName;
    
$report = "c:\powershell\report.htm" 
##Clears the report in case there is data in it
Clear-Content $report
##Builds the headers and formatting for the report
Add-Content $report "<html>" 
Add-Content $report "<head>" 
Add-Content $report "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>" 
Add-Content $report '<title>COMPANY Terminated User Cleanup Script</title>' 
add-content $report '<STYLE TYPE="text/css">' 
add-content $report  "<!--" 
add-content $report  "td {" 
add-content $report  "font-family: Tahoma;" 
add-content $report  "font-size: 11px;" 
add-content $report  "border-top: 1px solid #999999;" 
add-content $report  "border-right: 1px solid #999999;" 
add-content $report  "border-bottom: 1px solid #999999;" 
add-content $report  "border-left: 1px solid #999999;" 
add-content $report  "padding-top: 0px;" 
add-content $report  "padding-right: 0px;" 
add-content $report  "padding-bottom: 0px;" 
add-content $report  "padding-left: 0px;" 
add-content $report  "}" 
add-content $report  "body {" 
add-content $report  "margin-left: 5px;" 
add-content $report  "margin-top: 5px;" 
add-content $report  "margin-right: 0px;" 
add-content $report  "margin-bottom: 10px;" 
add-content $report  "" 
add-content $report  "table {" 
add-content $report  "border: thin solid #000000;" 
add-content $report  "}" 
add-content $report  "-->" 
add-content $report  "</style>" 
Add-Content $report "</head>" 
add-Content $report "<body>" 

##This section adds tables to the report with individual content
##Table 1 for deleted users
add-content $report  "<table width='100%'>" 
add-content $report  "<tr bgcolor='#CCCCCC'>" 
add-content $report  "<td colspan='7' height='25' align='center'>" 
add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>The following users need deletion (Report Only)</strong></font>" 
add-content $report  "</td>" 
add-content $report  "</tr>" 
add-content $report  "</table>" 
add-content $report  "<table width='100%'>" 
Add-Content $report "<tr bgcolor=#CCCCCC>" 
Add-Content $report  "<td width='20%' align='center'>Account Name</td>" 
Add-Content $report "<td width='10%' align='center'>Modified Date</td>"  
Add-Content $report "<td width='50%' align='center'>Description</td>"  
Add-Content $report "</tr>" 
if ($delUsers -ne $null){
	foreach ($name in $delUsers) {
		$AccountName = $name.name
		$LastChgd = $name.modified
		$UserDesc = $name.Description
		Add-Content $report "<tr>" 
		Add-Content $report "<td>$AccountName</td>" 
		Add-Content $report "<td>$LastChgd</td>" 
		add-Content $report "<td>$UserDesc</td>"
	}
}
else {
	Add-Content $report "<tr>" 
	Add-Content $report "<td>No Accounts match</td>" 
}
Add-content $report  "</table>" 

##Table 2 for warning users
add-content $report  "<table width='100%'>" 
add-content $report  "<tr bgcolor='#CCCCCC'>" 
add-content $report  "<td colspan='7' height='25' align='center'>" 
add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>The following users will be deleted next week</strong></font>" 
add-content $report  "</td>" 
add-content $report  "</tr>" 
add-content $report  "</table>" 
add-content $report  "<table width='100%'>" 
Add-Content $report "<tr bgcolor=#CCCCCC>" 
Add-Content $report  "<td width='20%' align='left'>Account Name</td>" 
Add-Content $report "<td width='10%' align='center'>Modified Date</td>"  
Add-Content $report "<td width='50%' align='center'>Description</td>"  
Add-Content $report "</tr>"
if ($warnUsers -ne $null){
	foreach ($name in $warnUsers) {
		$AccountName = $name.name
		$LastChgd = $name.modified
		$UserDesc = $name.Description
		Add-Content $report "<tr>" 
		Add-Content $report "<td>$AccountName</td>" 
		Add-Content $report "<td>$LastChgd</td>" 
		add-Content $report "<td>$UserDesc</td>"
	}
}
else {
	Add-Content $report "<tr>" 
	Add-Content $report "<td>No Accounts match</td>" 
}
Add-content $report  "</table>" 

##Table 3 for whitelisted users
add-content $report  "<table width='100%'>" 
add-content $report  "<tr bgcolor='#CCCCCC'>" 
add-content $report  "<td colspan='7' height='25' align='center'>" 
add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>The following users are whitelisted</strong></font>" 
add-content $report  "</td>" 
add-content $report  "</tr>" 
add-content $report  "</table>" 
add-content $report  "<table width='100%'>" 
Add-Content $report "<tr bgcolor=#CCCCCC>" 
Add-Content $report  "<td width='20%' align='left'>Account Name</td>" 
Add-Content $report "<td width='10%' align='center'>Modified Date</td>"  
Add-Content $report "<td width='50%' align='center'>Description</td>"  
Add-Content $report "</tr>"
if ($wlistUsers -ne $null){
	foreach ($name in $wlistUsers) {
		$AccountName = $name.name
		$LastChgd = $name.modified
		$UserDesc = $name.Description
		Add-Content $report "<tr>" 
		Add-Content $report "<td>$AccountName</td>" 
		Add-Content $report "<td>$LastChgd</td>" 
		add-Content $report "<td>$UserDesc</td>"
	}
}
else {
	Add-Content $report "<tr>" 
	Add-Content $report "<td>No Accounts match</td>" 
}
Add-content $report  "</table>" 

##Table 4 for recently modified users
add-content $report  "<table width='100%'>" 
add-content $report  "<tr bgcolor='#CCCCCC'>" 
add-content $report  "<td colspan='7' height='25' align='center'>" 
add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>The following users were modified in the last 30 days</strong></font>" 
add-content $report  "</td>" 
add-content $report  "</tr>" 
add-content $report  "</table>" 
add-content $report  "<table width='100%'>" 
Add-Content $report "<tr bgcolor=#CCCCCC>" 
Add-Content $report  "<td width='20%' align='left'>Account Name</td>" 
Add-Content $report "<td width='10%' align='center'>Modified Date</td>"  
Add-Content $report "<td width='50%' align='center'>Description</td>"  
Add-Content $report "</tr>" 
if ($30daysUsers -ne $null){
	foreach ($name in $30daysUsers) {
		$AccountName = $name.name
		$LastChgd = $name.modified
		$UserDesc = $name.Description
		Add-Content $report "<tr>" 
		Add-Content $report "<td>$AccountName</td>" 
		Add-Content $report "<td>$LastChgd</td>" 
		add-Content $report "<td>$UserDesc</td>"
	}
}
else {
	Add-Content $report "<tr>" 
	Add-Content $report "<td>No Accounts match</td>" 
}
Add-content $report  "</table>" 

##This section closes the report formatting
Add-Content $report "</body>" 
Add-Content $report "</html>" 
    
##Assembles and sends completion email with DL information##
$emailFrom = "ADCleanUp@CMGRP.com"
$emailTo = "Shanlon@cmgrp.com"
$subject = "COMPANY $Region Terminated User Cleanup Script Complete"
$smtpServer = "relay-mail.interpublic.com"
$body = Get-Content $report | Out-String

Send-MailMessage -To $emailTo -From $emailFrom -Subject $subject -BodyAsHtml -Body $body -SmtpServer $smtpServer
}

}

