
# generate and install certificate
wget https://github.com/FiloSottile/mkcert/releases/download/v1.4.1/mkcert-v1.4.1-windows-amd64.exe -O mkcert.exe
.\mkcert.exe -install
.\mkcert.exe "*.dev.env" "dev.env"
Move-Item -Force -Path .\*.pem -Destination .\conf/

# register domain resolution using a local NRTP rule configuration
# see https://docs.microsoft.com/en-us/powershell/module/dnsclient/add-dnsclientnrptrule?view=win10-ps#examples
Add-DnsClientNrptRule -Namespace "dev.env" -NameServers "127.0.0.1"

# set custom environment variables
Set-Content -Path .\.env -Value "DEVENV_WEB_PATH=$env:UserProfile\\www"

# create shared docker network
docker network create devenv

# run the application
docker-compose up -d
