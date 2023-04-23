# escape=`

FROM mcr.microsoft.com/windows/nanoserver:1809
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

COPY ./modules/ C:/modules/