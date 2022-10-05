#   O365 Compliance Search and Destroy)
# Finds specified email content through compliance search and executes a soft delete of results
    	Write-Host "   _____                     _                      _____            _                   "
    	Write-Host "  / ____|                   | |          ___       |  __ \          | |                    "
	Write-Host " | (___   ___  __ _ _ __ ___| |__       ( _ )      | |  | | ___  ___| |_ _ __ ___  _   _   "
	Write-Host "  \___ \ / _ \/ _' | '__/ __| '_ \      / _ \/\    | |  | |/ _ \/ __| __| '__/ _ \| | | |  "
	Write-Host "  ____) |  __/ (_| | | | (__| | | |    | (_>  <    | |__| |  __/\__ \ |_| | | (_) | |_| |  "
	Write-Host " |_____/ \___|\__,_|_|  \___|_| |_|     \___/\/    |_____/ \___||___/\__|_|  \___/ \__, |  "
	Write-Host "                                                                                     / /  "
	Write-Host "                                                                                    /_/  "
	Write-Host " @xBurningGiraffe                                                                                   
	Write-Host "================================================================================================"


    Write-Host "================================================================================================"
    Write-Host "O365 Compliance Search Info:" -ForegroundColor Yellow
	Write-Host "O365's Compliance Search Purge Action moves items to the user's Recoverable Items folder, and they will remain there based on the Retention Period that is configuYellow for the mailbox." -ForegroundColor Yellow
	Write-Host "O365's Compliance Search results will return Items that were already purged (and are located in the Recoverable Items folder)." -ForegroundColor Yellow
    
Connect-IPPSSession

$GetName = (Get-Date -Format "yyyy-MM-dd")
$SearchName = $GetName
$EmailSender = Read-Host -Prompt 'Please enter the exact Sender (From:) address of the Email you would like to search for'
$Subject = Read-Host -Prompt 'Please enter the exact Subject of the Email you would like to search for'
$DateStart = Read-Host -Prompt 'Please enter the Beginning Date for your Date Range (ex. MM/DD/YYYY)'
$DateEnd = Read-Host -Prompt 'Please enter the Ending Date for your Date Range (ex. MM/DD/YYYY)'
$DateRangeSeparator = ".."
$DateRange = $DateStart + $DateRangeSeparator + $DateEnd
$Search = "(Received:$DateRange) AND (From:$EmailSender) AND (Subject:'$Subject')"

# Search Creation
New-ComplianceSearch -Name $SearchName -ExchangeLocation All -ContentMatchQuery $Search

# Search
Write-Host "================================================================================================"
Write-Host "Starting Search and Destroy...please wait for results..." -ForegroundColor Green
Start-ComplianceSearch -Identity $SearchName
Get-ComplianceSearch -Identity $SearchName
    do{ $ThisSearch = Get-ComplianceSearch -Identity $SearchName
            Start-Sleep 15
    } until ($ThisSearch.status -match "Completed")


$ThisSearchResults = $ThisSearch.SuccessResults;
    if (($ThisSearch.Items -le 0) -or ([string]::IsNullOrWhiteSpace($ThisSearchResults))){
            Write-Host "Whoops...no useful results were found!" -ForegroundColor Yellow
    }
    $mailboxes = @() #create an empty array for mailboxes
    $ThisSearchResultsLines = $ThisSearchResults -split '[\r\n]+'; #Split up the Search Results at carriage return and line feed
    foreach ($ThisSearchResultsLine in $ThisSearchResultsLines){
            # If the Search Results Line matches the regex, and $matches[2] (the value of "Item count: n") is greater than 0)
    if ($ThisSearchResultsLine -match 'Location: (\S+),.+Item count: (\d+)' -and $matches[2] -gt 0){ 
                # Add the Location: (email address) for that Search Results Line to the $mailboxes array
    $mailboxes += $matches[1]; 
    }
    }
    Write-Host "Number of mailboxes that have Search Hits..."
    Write-Host $mailboxes.Count -ForegroundColor Yellow
    Write-Host "List of mailboxes that have Search Hits..."
    Write-Host $mailboxes -ForegroundColor Yellow
    Write-Host "================================================================================================"

    $CheckDelete = Read-Host -Prompt "Please review the results above. Do you want to proceed with the soft delete? [Y]es or [N]o"
    if ($CheckDelete -eq 'Y'){
        Write-Host "==========================================================================="
        Write-Host "Running Search and Destroy...."
        Write-Host "==========================================================================="
        $PurgeSuffix = "_purge"
		$PurgeName = $SearchName + $PurgeSuffix
        New-ComplianceSearchAction -SearchName $SearchName -Purge -PurgeType SoftDelete
								do{
									$ThisPurge = Get-ComplianceSearchAction -Identity $PurgeName
                                        Start-Sleep 15
                                        Write-Host "Destruction in progress...please wait" -ForegroundColor Green
								}until ($ThisPurge.Status -match "Completed")
                                $ThisPurge | Format-List
                                $ThisPurgeResults = $ThisPurge.Results
                                $ThisPurgeResultsMatches = $ThisPurgeResults -match 'Purge Type: SoftDelete; Item count: (\d*); Total size (\d*);.*'
                                if ($ThisPurgeResultsMatches){
                                    $ThisPurgeResultsItemCount = $Matches[1]
                                    $ThisPurgeResultsTotalSize = $matches[2]
                                }
                                Write-Host "Finishing up...with your mom LOL" -ForegroundColor Green
                                Write-Host "==========================================================="
                                Write-Host "Search and Destroy complete! You removed the chosen email from a total of: "  -ForeGround Green                         
                                Write-Host $ThisPurgeResultsItemCount -ForegroundColor Yellow
                                Write-Host "Mailboxes" -ForeGround Green
                                Write-Host "==========================================================================="
                                Write-Host "and the total size of the purge was: " -ForeGround Green
                                Write-Host $ThisPurgeResultsTotalSize -ForegroundColor Yellow
                                Write-Host "==========================================================================="
                                Remove-ComplianceSearch -Identity $SearchName
                                Write-Host "================================================================================================"
                                Write-Host "My work here is finished. If yours isn't, please rerun Search and Destroy. This ain't no picnic b**tch!)" -ForeGround Green
                                Write-Host "================================================================================================"
                                Disconnect-ExchangeOnline                
    }elseif ($CheckDelete -eq 'N'){
        Write-Host "==========================================================================="
        Write-Host "Exiting Search and Destroy...go review the results in the Compliance Center! :)" -ForeGround Green
        Remove-ComplianceSearch -Identity $SearchName
        Write-Host "==========================================================================="
        Disconnect-ExchangeOnline
    }
