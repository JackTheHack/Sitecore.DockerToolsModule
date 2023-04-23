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