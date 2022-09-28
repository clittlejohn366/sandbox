#*******************************************
#  Email Autogen
#  Generate emails to send
#  Modify these variables:
#    -SMTPServer = Your SMTP Relay IP or Servername
#    -ToEmail = Array with the emails you want to send TO
#    -FromEmail = Single email address you want to send FROM
#    -Subject = Subject of your test email
#    -EmailsToSend = Number of emails you want to send
#*******************************************


#***************VARIABLES***********************
$strSMTPServer 		= "SMTPSERVER IP OR NAME"
$strToEmail 		= "user1@domain.com","user2@domain.com","user3@domain.com","user4@domain.com","user5@domain.com"
$strFromEmail 		= "no-reply@domain.com"
$strSubject 		= "Email Autogen"
$intEmailsToSend	= 5

$strComputerName 	= gc env:computername
$dtTimeNow = get-date
$strScriptInfo 		= "<br><br><br><b>Script Info</b><br>Script Name:  " + $MyInvocation.MyCommand.Definition + "<br>Time:  " + $dtTimeNow + "<br>Run From:  " + $strComputerName
#************************************************



#***************EMAIL HTML***********************
$strHTMLHeader = ""
$strHTMLHeader = $strHTMLHeader + "<html>"
$strHTMLHeader = $strHTMLHeader + "<body>"
$strHTMLHeader = $strHTMLHeader + "<h2>Email Autogen</h2><br>"

$strHTMLFooter = ""
$strHTMLFooter = $strHTMLFooter + $strScriptInfo
$strHTMLFooter = $strHTMLFooter + "</body>"
$strHTMLFooter = $strHTMLFooter + "</html>"
#************************************************



#********************SEND THE EMAILS********************
foreach ($itemEmail in $strToEmail)
{
    For ($intEmailCount =1; $intEmailCount -le $intEmailsToSend; $intEmailCount++)
    {
        $strContent = "Email Number: " + $intEmailCount 
        $strHTMLBody = $strHTMLHeader + $strContent + $strHTMLFooter
        
        #sending email
        $msg = new-object Net.Mail.MailMessage
        $smtp = new-object Net.Mail.SmtpClient($strSMTPServer)

        $msg.From = $strFromEmail
        $msg.To.Add($itemEmail)
        $msg.subject = $strSubject + $intEmailCount
        $msg.IsBodyHtml = $true
        $msg.body = $strHTMLBody
        $smtp.Send($msg)
        
        #****Logging Stuff****
        #Write-host "From: " $strFromEmail
        #write-host "To: " $itemEmail
        #write-host "Subject: " $strSubject $intEmailCount
        #write-host "Body: " $strHTMLBody
        #*********************
    }
}
#*******************************************************

