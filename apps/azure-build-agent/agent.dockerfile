FROM ubuntu:22.04

RUN apt update
RUN apt upgrade -y
RUN apt install -y curl git jq libicu70 acl

# Install powershell
RUN curl -sSL -o powershell.deb https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/powershell_7.4.0-1.deb_amd64.deb && \
    dpkg -i powershell.deb && \
    apt install -f && \
    rm powershell.deb

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

ENV TARGETARCH="linux-x64"

WORKDIR /azp

COPY ./start.sh ./

RUN useradd agent

RUN chmod +x ./start.sh
RUN mkdir _work
RUN setfacl -R -m u:agent:rwx _work
RUN setfacl -R -m u:agent:rwx _work
RUN chown -R agent /azp
RUN chown -R agent /home

USER agent

ENTRYPOINT ./start.sh