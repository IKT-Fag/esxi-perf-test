function Get-IopsOverTime
{
    [Cmdletbinding()]
    param
    (
        [string]$VIServer,
        [PSCredential]$Credential,
        [int]$Samples = 5,
        [string]$Datastore,
        [hashtable]$Duration = @{Hours=0; Minutes=10},
        [int]$Interval = 2, #Seconds
        [string]$DataFolder
    )

    Import-Module VMware.VimAutomation.Core
    . .\Get-IOPS.ps1

    ## Calculate duration
    $StartTime = Get-Date
    $EndTime = $StartTime.AddHours($Duration.Hours).AddMinutes($Duration.Minutes)

    $Session = Connect-VIServer -Server $VIServer -Credential $Credential

    while ((Get-Date) -le $EndTime)
    {
        $Data = [ordered]@{}
        $Data.VIServer = $VIServer
        $Data.Read = Get-IOPS -Session $Session -Samples $Samples `
            -DatastoreName $Datastore -Metric "disk.numberRead.Summation"
        $Data.Write = Get-IOPS -Session $Session -Samples $Samples `
            -DatastoreName $Datastore -Metric "disk.numberWrite.Summation"
        $Data.Timestamp =  (([datetime]::UtcNow) - (Get-Date -Date "1/1/1970")).TotalMilliseconds * 1000000

        $DataFile = Join-Path -Path $DataFolder -ChildPath "$(Get-Date -Format yyy-MM-dd___hh.mm.ss)___$VIServer.json"
        $Data | ConvertTo-Json | Out-File -FilePath $DataFile
        Start-Sleep -Seconds $Interval

        Write-Output $Data
    }

    Disconnect-VIServer * -Confirm:$False
}

## Example:
if (!($Credential))
{
    $Credential = Get-Credential -UserName "root" -Message "root pw"
}

Get-IopsOverTime -VIServer "192.168.0.20" -Credential $Credential `
    -Samples 5 -Datastore "Smith" -Duration @{Hours=1; Minutes=0} `
    -Interval 2 -DataFolder "C:\Users\admin\Documents\GitHub\esxi-perf-test\Data" -Verbose
