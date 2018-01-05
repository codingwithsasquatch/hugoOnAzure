#copy the host.json, proxies.json and keepalive function into the right locations
Copy-Item functionSrc\* -Force -Destination d:\home\site\wwwroot -Recurse

#create the temp dir if it doesn't already exist
$tempPublicDir = "d:\local\temp\public"
if((Test-Path $tempPublicDir) -eq 0)
{
  New-Item -ItemType Directory -Force -Path $tempPublicDir
}

#run hugo to generate the site and output the files the the temp dir
.\tools\hugo.exe -d $tempPublicDir -s D:\home\site\repository\hugoRoot

# Connection string associated with the blob storage.
$blobStorage = $env:AzureWebJobsStorage

# Then we extract the name and key below
$accountKey = ""
$accountName = ""
$array = $blobStorage.Split(';')
foreach($element in $array)
{
  if($element.Contains('AccountName')) {
    $accountName = $element.Replace("AccountName=", "")
  }  
  if($element.Contains('AccountKey')) {
      $accountKey = $element.Replace("AccountKey=", "")
  }
}

# Use AzCopy to deploy blob storage as long as we have an Account Key for the storage account
if($accountKey -ne "")
{
  .\tools\AzCopy\AzCopy.exe /Source:$tempPublicDir /Dest:https://$accountName.blob.core.windows.net/public /DestKey:$accountKey /SetContentType /S /Y
  $ProgressPreference="SilentlyContinue"
  $StorageContext = New-AzureStorageContext  -StorageAccountName $accountName -StorageAccountKey $accountKey
  Set-AzureStorageContainerAcl -Context $StorageContext -Container "public" -Permission Blob

  #set TTL
  $blobs = Get-AzureStorageBlob -Container "public" -Context $StorageContext
  foreach ($blob in $blobs)
  {
    $blob.ICloudBlob.Properties.CacheControl = "max-age=3600"
    $blob.ICloudBlob.SetProperties()
  }
}
else
{
  Write-Host "Unable to find Storage Account Key"
}