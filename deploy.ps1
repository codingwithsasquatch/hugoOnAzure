# Generates our blog to /public
.\tools\hugo.exe

# Connection string associated with the blob storage. Can be input manually too.
$blobStorage = $env:AzureWebJobsStorage

# We extract the key below
$accountKey = ""
$accountName = ""
$array = $blobStorage.Split(';')
foreach($element in $array)
{
  if($element.Contains('AccountName')) {
    $accountKey = $element.Replace("AccountName=", "")
  }  
  if($element.Contains('AccountKey')) {
      $accountKey = $element.Replace("AccountKey=", "")
  }
}

if($accountKey -ne "")
{
  # Deploy to blob storage
  .\tools\AzCopy\AzCopy.exe /Source:.\public /Dest:https://$accountName.blob.core.windows.net/public /DestKey:$accountKey /SetContentType /S /Y
}
else
{
  Write-Host "Unable to find Storage Account Key"
}