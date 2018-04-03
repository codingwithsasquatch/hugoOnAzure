#set up constants
$dirDepth = 4
$containerName = "public"
$baseStorageUri = 'https://%storageAccountName%.blob.core.windows.net/'+$containerName
$ttl = 3600

#create the temp dir if it doesn't already exist
$tempPublicDir = "d:\local\temp\public"
if((Test-Path $tempPublicDir) -eq 0)
{
  New-Item -ItemType Directory -Force -Path $tempPublicDir
}

#run hugo to generate the site and output the files the the temp dir
.\tools\hugo.exe -d $tempPublicDir -s D:\home\site\repository\hugoRoot

# automatically generate the proxies.json file
$rootFileList = Get-ChildItem -File $tempPublicDir
$extList = Get-ChildItem -File -Recurse $tempPublicDir | Select-Object Extension | Sort-Object Extension | Get-Unique -asString

$objProxiesJson = @{}
$proxiesList = @{}

# default root document
$proxiesList."rootDefault" = @{
  matchCondition = @{
      route = "/"
      }
  backendUri = "$baseStorageUri/index.html"
}

# iterate thru the root filenames
foreach ($file in $rootFileList.Name.Where{$_ -ne '.keep'}) {
  $proxiesList."root$file" = @{
      matchCondition = @{
          route = "/$file"
          }
      backendUri = "$baseStorageUri/$file"
  }

}

# iterate thru directory depth and add file types
For ($i=1; $i -le $dirDepth; $i++)
{
  $path = ""
  For ($d=1; $d -le $i; $d++){
    $path += "/{level$d}"
  }
  $path += "/"

  # default document
  $proxiesList."level$iDefault" = @{
    matchCondition = @{
        route = "$path/"
        }
    backendUri = "$baseStorageUri$path/index.html"
  }

  # and the rest of the document types
  foreach ($ext in $extList.Extension.Where{$_ -ne '.keep'}) {
    $proxiesList."level$i$ext" = @{
        matchCondition = @{
            route = "$path{name}$ext"
            }
        backendUri = "$baseStorageUri$path{name}$ext"
    }
  }
}

$objProxiesJson = @{
    '$schema' = "http://json.schemastore.org/proxies"
    proxies = $proxiesList
}

convertto-json -InputObject $objProxiesJson -Depth 5| Out-File d:\home\site\wwwroot\proxies.json

#copy the host.json, proxies.json and keepalive function into the right locations
Copy-Item functionSrc\* -Force -Destination d:\home\site\wwwroot -Recurse

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
    $blob.ICloudBlob.Properties.CacheControl = "max-age=$ttl"
    $blob.ICloudBlob.SetProperties()
  }
}
else
{
  Write-Host "Unable to find Storage Account Key"
}