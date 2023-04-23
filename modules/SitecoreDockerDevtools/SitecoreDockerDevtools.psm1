function Build-SitecoreSupportPackage {
    Write-Host "Starting collecting Sitecore support package files..."
    $date = Get-Date
    $packageName = 'supportPackage_{0:yyyyMMdd}' -f $date
    $destinationPath = ".\temp\$packageName"
    Write-Host "Creating temporary directory in $destinationPath" 
    New-Item $destinationPath -ItemType Directory -Verbose
    Write-Host "Copying web.config..."
    Copy-Item ".\web.config" -Destination $destinationPath -Verbose
    Write-Host "Copying App_Config..."
    Copy-Item ".\App_Config" -Destination $destinationPath -Recurse -Verbose
    Write-Host "Copying logs..."
    Copy-Item ".\App_Data\logs" -Destination $destinationPath -Recurse -Verbose
    Write-Host "Copying DLLs..."
    Copy-Item ".\bin" -Destination $destinationPath -Recurse -Verbose
    Write-Host "Creating the archive..."
    Compress-Archive -Path $destinationPath -DestinationPath ".\temp\$packageName.zip" -Verbose
    Write-Host "Done."
}

function Read-SitecoreCacheStats
{
    $healthLogsPath = "C:\inetpub\wwwroot\App_Data\diagnostics\health_monitor"
    #$healthLogsPath = ".\sample\"
    $cacheStatsFile = Get-ChildItem -Path $healthLogsPath | Where-Object { $_.Name.StartsWith("CacheStatus")} | Sort-Object -Property "LastWriteTime" -Descending | Select-Object -First 1
    $fileContent = Get-Content "$healthLogsPath\$($cacheStatsFile.Name)"
    $fileHeader = $fileContent | Select-Object -First 2
    Write-Host $fileHeader
    $tableContents = $fileContent | Select-Object -Skip 2

    try
    {
        [xml]$xml = $tableContents                
        $rows = $xml.SelectNodes('//table/tr')
        $cacheStatsTable = New-Object Collections.Generic.List[PSCustomObject]

        $rows | Select-Object -Skip 1 | ForEach-Object {             
            $nameXml = $_.ChildNodes[0].InnerText
            $countXml = $_.ChildNodes[1].InnerText
            $sizeXml = $_.ChildNodes[2].InnerText.Replace(' bytes','').Replace(' ','')
            $maxSizeXml = $_.ChildNodes[3].InnerText.Replace(' bytes','').Replace(' ','')            
            $percentage = $maxSizeXml -ne 0 ? $sizeXml / $maxSizeXml : 0;
            
            $newEntry = @{
                Name = $nameXml;
                Count = $countXml;
                Size = $sizeXml;
                MaxSize = $maxSizeXml;
                PercentageValue = $percentage;
                Percentage = "$(($percentage*100).ToString('0.##'))%"
            };

            $cacheStatsTable.Add($newEntry);            
        }

        $cacheStatsTable | Sort-Object -Property "PercentageValue" -Descending  | ForEach-Object {[PSCustomObject]$_} | Format-Table -AutoSize -Property @("Name", "Count", "Size", "MaxSize", "Percentage")                    
    }
    catch
    {
        $err = $_.Exception.Message
        Write-Warning "Failed to read cache XML stats`nDetails: $err"        
    }
}

function Read-SitecoreRenderingStats
{
    $healthLogsPath = "C:\inetpub\wwwroot\App_Data\diagnostics\health_monitor"
    #$healthLogsPath = ".\sample\"
    $statsFile = Get-ChildItem -Path $healthLogsPath | Where-Object { $_.Name.StartsWith("RenderingsStatistics")} | Sort-Object -Property "LastWriteTime" -Descending | Select-Object -First 1
    $tableContents = Get-Content "$healthLogsPath\$($statsFile.Name)"        

    try
    {
        [xml]$xml = $tableContents                
        $rows = $xml.SelectNodes('//table/tr')
        $statsTable = New-Object Collections.Generic.List[PSCustomObject]

        $rows | Select-Object -Skip 1 | ForEach-Object {             
            $nameXml = $_.ChildNodes[0].InnerText
            $nameXml = $nameXml.Substring(0, [Math]::Min($nameXml.Length, 50))

            $siteXml = $_.ChildNodes[1].InnerText
            $countXml = $_.ChildNodes[2].InnerText
            $fromCacheXml = $_.ChildNodes[3].InnerText
            $avgTimeXml = [int]$_.ChildNodes[4].InnerText
            $maxTimeXml = [int]$_.ChildNodes[6].InnerText
            $totalTimeXml = $_.ChildNodes[8].InnerText
            $lastRunXml = $_.ChildNodes[10].InnerText
            
            
            $newEntry = @{
                Name = $nameXml;
                Site = $siteXml;
                Count = $countXml;
                FromCache = $fromCacheXml;
                AvgTime = $avgTimeXml;
                MaxTime = $maxTimeXml;
                TotalTime = $totalTimeXml;
                LastRun = $lastRunXml
            };

            $statsTable.Add($newEntry);            
        }

        $statsTable | Sort-Object -Property "AvgTime" -Descending  | ForEach-Object {[PSCustomObject]$_} | Format-Table -AutoSize -Property @("Name", "Site", "Count", "FromCache", "AvgTime", "TotalTime", "LastRun")                    
    }
    catch
    {
        $err = $_.Exception.Message
        Write-Warning "Failed to read cache XML stats`nDetails: $err"        
    }
}

#. .\src\Sitecore-ReadSitecoreCacheStats.ps1

Export-ModuleMember -Function Build-SitecoreSupportPackage
Export-ModuleMember -Function Read-SitecoreCacheStats
Export-ModuleMember -Function Read-SitecoreRenderingStats