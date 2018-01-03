# Run Hugo on Azure from a GitHub repo using serverless resources for deployment

1. Just fork this repo.
2. Edit the config.toml for your site, set up theme etc. and add content like you would for any hugo site.
3. When you are ready to deploy. Hit this [![Deploy to Azure](http://azuredeploy.net/deploybutton.svg)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcodingwithsasquatch%2FhugoOnAzure%2Fmaster%2Fazuredeploy.json) button and provide the repo URL for your fork.
4. Anytime you do a push to your github repo hugo will regenerate the site in azure and update the changed files it.

All for pennies a month.


This is based on the work by Maxime Rouiller  in his blog post [here](https://blog.maximerouiller.com/post/go-go-hugo-blog-to-azure-storage/). I parameterized it up and packaged it up into an ARM template.