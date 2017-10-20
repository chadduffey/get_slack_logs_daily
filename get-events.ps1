#Script Parameters
$earliest = 1506816061 #This represents October 1st at 0:01am

$output_file = "c:\iceberg\slack\data\slack.log"
$marker_file = "c:\iceberg\slack\script\marker.cfg"
$last_marker = Get-Content $marker_file

if ($last_marker -eq $null){
    write-host "Last marker is null"
    $last_marker = $earliest
}

#API parameters
$url = "http://slack.com/api/"
$method = "team.accessLogs/"
$token = $env:SLACK
$pretty = 1
$page = 1

Write-Host "Previous Marker: "$last_marker

while($page -lt 100)
{

    $query = '?token='+$token+'&pretty='+$pretty+'&page='+$page
    $response = Invoke-RestMethod $url$method$query

    #update the marker file on first api call only
    if ($page -eq 1){
        write-host "New Marker:"$response.logins[0].date_last
        $response.logins[0].date_last | Out-File $marker_file
    }

    Write-Host "Current Query: " + $query -BackgroundColor Green

    #process a single response.
    for($i = 0; $i -le 99; $i++)
    {
        if ([int]$response.logins[$i].date_last -lt [int]$last_marker){
            write-host "Found marker entry. Exiting" -BackgroundColor Yellow
            exit
        } else {
            $response.logins[$i] | ConvertTo-Json | Add-Content $output_file
        }
    }

    if ([int]$response.logins[99].date_last -lt $earliest){
        Write-Host "Found Pre-October Date. Done."
        $page = 999
    } else {
        $page++
        Write-Host "Incrementing page: "$page
        Write-Host "Last timestamp: "$response.logins[99].date_last
    }

}
