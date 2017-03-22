function New-Dummy
{
    [CmdletBinding()]
    param
    (
        [Parameter( Mandatory = $True,
                    Position = 0)]
        $VIServer,

        [Parameter( Mandatory = $True,
                    Position = 1)]
        [PSCredential] $Credential,

        [Parameter( Mandatory = $True,
                    Position = 2)]
        [int] $NumVM,

        [Parameter( Mandatory = $True,
                    Position = 3)]
        [string] $OVAFile
    )

    begin
    {
        Import-Module VMware.VimAutomation.Core -Verbose:$False -ErrorAction Stop
    }

    process
    {
        if (!(Test-Path -Path $OVA))
        {
            throw "$OVA -- is not a valid path!"
        }

        Connect-ViServer -Server $VIServer -Credential $Credential -WarningAction SilentlyContinue

        foreach ($Num in (1..$NumVM))
        {
            Write-Verbose "$OVA -- deploying OVA"
            $ImportVAppParams = @{
                Source              = $OVA
                Name                = "Dummy-$Num"
                DiskStorageFormat   = "Thin"
                Datastore           = Get-Datastore -Name "GHOST"
                RunAsync            = $False 
                VMHost              = $VIServer
            }
            Import-VApp @ImportVAppParams -ErrorAction Stop
        }
    }
}

$Credential = Get-Credential -UserName "root" -Message "pw"
$OVA = "D:\ESXi-perf-test\Lab - Render.ova"
$NumVM = 1
New-Dummy -VIServer 192.168.0.20 -Credential $Credential -NumVM $NumVM -OVAFile $OVA

<#
foreach ($Num in (1..$NumVM))
{
    Get-VM -Name "Dummy-$Num" | Remove-VM -DeletePermanently -RunAsync -Confirm:$False
}
#>