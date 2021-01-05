 param (
    [Parameter(Mandatory=$true)][string]$server,
    [string]$user = $( Read-Host "Input username for ${server}" ),
    [string]$pass = $( Read-Host "Input password for ${server}" )
 )

 if ($server -NotLike "https://*") {
     $server = "https://" + $server
 }

$loginPath = "/v3-public/localProviders/local?action=login"
$loginParams = @{
    "username" = $user
    "password" = $pass
}

$login = ( `
    Invoke-WebRequest -Header  @{'User-Agent' = ''; 'Accept' = 'application/json'; 'Content-Type' = 'application/json';} `
    -Uri $server$loginPath `
    -UseBasicParsing `
    -Method POST `
    -Body ($loginParams | ConvertTo-Json) `
) | ConvertFrom-Json

Set-Content -Path ./token.auto.tfvars -Value "rancher_api_token = `"$($login.token)`""

