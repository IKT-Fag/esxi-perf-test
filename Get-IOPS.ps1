function Get-IOPS
{
    [CmdletBinding()]
    param
    (
        [Parameter( Mandatory = $True)]
        $Session,

        [Parameter( Mandatory = $True)]
        [int] $Samples,

        [Parameter( Mandatory = $True)]
        [string] $DatastoreName,

        [Parameter( Mandatory = $True)]
        [string] $Metric
    )

    begin
    {
        Import-Module VMware.VimAutomation.Core -WarningAction SilentlyContinue | Out-Null
    }

    process
    {
        $VIServer = $Session.Name
        Write-Verbose "$VIServer -- connecting to VIServer"
        Connect-VIServer -Server $VIServer -Session $Session.SessionId | Out-Null

        $Datastore      = Get-Datastore -Name $DatastoreName -Server $VIServer
        $DatastoreId    = ($Datastore | Get-View).info.vmfs.extent[0].diskname
        $VMHost         = Get-VMHost -Name $VIServer -Server $VIServer

        $RawStats = Get-Stat -Entity $VMHost -Stat $Metric -MaxSamples $Samples -Realtime
        #return $RawStats
        ## Collect the read or write values
        $Results = @()
        foreach ($Stat in $RawStats)
        {
            ## Check to see if the $Stat comes from the correct DS,
            ## then add the value to our collection.
            if ($Stat.instance.Equals($DatastoreId))
            {
                $Results += $Stat.Value
            }
        }

        ## Add all the values together
        $TotalIOPS = 0
        foreach ($Result in $Results)
        {
            $TotalIOPS += $Result
        }

        ## Calculate the average IOPS
        [int]$AverageIOPS = ($TotalIOPS / $Samples / 20)
        Write-Output $AverageIOPS
    }
}

$VIServer = "192.168.0.12"
if (!($Credential))
{
    $Credential = Get-Credential -UserName "root" -Message "root pw"
}
$Samples = 5
$Datastore = "TheNewCloud (1)"

$Session = Connect-VIServer -Server $VIServer -Credential $Credential

$Data = [ordered]@{}
$Data.VIServer = $VIServer
$Data.Read = Get-IOPS -Session $Session -Samples $Samples -DatastoreName $Datastore -Metric "disk.numberRead.Summation"
$Data.Write = Get-IOPS -Session $Session -Samples $Samples -DatastoreName $Datastore -Metric "disk.numberWrite.Summation"
#$Data.Timestamp =  (([datetime]::UtcNow) - (Get-Date -Date "1/1/1970")).TotalMilliseconds * 1000000

$Data

Disconnect-VIServer * -Confirm:$False
