param(
  [Parameter(Mandatory = $true)]
  [string]$HostName,
  [string]$User = "root",
  [string]$RemoteDir = "/opt/deepulogger"
)

$ErrorActionPreference = "Stop"

ssh "$User@$HostName" "mkdir -p $RemoteDir"
scp -r .\server\* "$User@$HostName`:$RemoteDir/"
ssh "$User@$HostName" "cd $RemoteDir && test -f .env || cp .env.example .env && npm install --omit=dev && npm run migrate && npm run seed && pm2 start src/index.js --name deepulogger-api || node src/index.js"
