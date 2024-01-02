FROM ubuntu:22.04

RUN apt update
RUN apt upgrade -y
RUN apt install -y curl git jq libicu70 

# Install powershell
RUN curl -sSL -o powershell.deb https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/powershell_7.4.0-1.deb_amd64.deb && \
    dpkg -i powershell.deb && \
    apt install -f && \
    rm powershell.deb

# Also can be "linux-arm", "linux-arm64".
ENV TARGETARCH="linux-x64"

WORKDIR /azp/

COPY ./start.sh ./
RUN chmod +x ./start.sh

RUN useradd agent

RUN chown -R agent /azp
RUN chown -R agent /home
RUN chmod -R +x /azp

USER agent
# Another option is to run the agent as root.
#ENV AGENT_ALLOW_RUNASROOT="true"

ENTRYPOINT ./start.sh