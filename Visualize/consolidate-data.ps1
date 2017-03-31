$jsonFiles = Get-ChildItem -Path ".\data"
$jsonConsolidated = ".\consolidate-data.ps1"

if (!(Test-Path -Path $jsonConsolidated))
{
    New-Item -ItemType file -Path $jsonConsolidated
}

$dataPoints = @()
foreach ($file in $jsonFiles.FullName)
{
    $data = Get-Content -Path $file -Raw | ConvertFrom-Json

    ## Convert Unix timestamp to date object
    $epoch = [datetime]"1/1/1970"
    $unixToTime = ($epoch.AddMilliseconds(($data.TimeStamp / 1000000))).AddHours(2)
    
    $dataPoints += @{x=$unixToTime; y=$data.Read}
}

$str = ""
foreach ($point in $dataPoints)
{
    $t = $point.x
    $date = "new Date($($t.Year), $($t.Month), $($t.Day), $($t.Hour), $($t.Minute), $($t.Second))"

    $dataStr = "{ x: $date, y: $($point.y) },`r`n"
    $str += $dataStr
}

$str | Out-File -FilePath ".\consolidate-data-read.txt" -Force
