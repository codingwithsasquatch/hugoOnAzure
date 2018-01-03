#r "Microsoft.WindowsAzure.Storage"

using System.Net;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.IO;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;
using MimeTypes;

static string defaultPage = GetEnvironmentVariable("DefaultPage") ?? "index.html";
static string root = GetEnvironmentVariable("Container") ?? "public";
static string storageCn = GetEnvironmentVariable("AzureWebJobsStorage");

public async static Task<HttpResponseMessage> Run(HttpRequestMessage req, TraceWriter log)
{
    var filePath = req.GetQueryNameValuePairs()
                        .FirstOrDefault(q => string.Compare(q.Key, "file", true) == 0)
                        .Value;

    filePath = string.IsNullOrWhiteSpace(filePath) ? defaultPage : filePath;
    filePath = filePath.EndsWith("/") ? $"{filePath}{defaultPage}" : filePath;

    CloudStorageAccount storageAccount = CloudStorageAccount.Parse(storageCn);
    CloudBlobClient blobClient = storageAccount.CreateCloudBlobClient();
    CloudBlobContainer container = blobClient.GetContainerReference(root);

    var blob = container.GetBlockBlobReference(filePath);
    var exists = await blob.ExistsAsync();

    filePath = exists ? filePath : $"{filePath}/{defaultPage}";
    blob = container.GetBlockBlobReference(filePath);
    
    var fileInfo = new FileInfo(filePath);
    var mimeType = MimeTypeMap.GetMimeType(fileInfo.Extension);

    log.Info($"Serving: {filePath} - {blob.Uri.ToString()} with MimeType: {mimeType}");
    try
    {
        var response = new HttpResponseMessage(HttpStatusCode.OK);
        var stream = new MemoryStream();

        await blob.DownloadToStreamAsync(stream);
        stream.Position = 0;
        response.Content = new StreamContent(stream);
        response.Content.Headers.ContentType = new MediaTypeHeaderValue(mimeType);
        return response;
    }
    catch
    {
        return new HttpResponseMessage(HttpStatusCode.NotFound);
    }
}

private static string GetEnvironmentVariable(string name)
    => System.Environment.GetEnvironmentVariable(name, EnvironmentVariableTarget.Process);