FROM photon:3.0
ENV TERM linux
ENV PORT 8080

# Set terminal. If we don't do this, weird readline things happen.
RUN echo "/usr/bin/pwsh" >> /etc/shells && \
    echo "/bin/pwsh" >> /etc/shells && \
    tdnf install -y wget tar powershell icu && \
    wget https://github.com/PowerShell/PowerShell/releases/download/v7.1.1/powershell-7.1.1-linux-x64.tar.gz && \
    tar -xvf powershell-7.1.1-linux-x64.tar.gz -C /usr/lib/powershell && \
    rm /usr/lib/powershell/libssl.so.1.0.0 && \
    rm /usr/lib/powershell/libcrypto.so.1.0.0 && \
    ln -s /usr/lib/libssl.so.1.1 /usr/lib/powershell/libssl.so.1.0.0 && \
    ln -s /usr/lib/libcrypto.so.1.1 /usr/lib/powershell/libcrypto.so.1.0.0 && \
    pwsh -c "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted" && \
    pwsh -c "\$ProgressPreference = \"SilentlyContinue\"; Install-Module VMware.PowerCLI" && \
    pwsh -Command 'Install-Module ThreadJob -Force -Confirm:$false' && \
    pwsh -Command 'Install-Module -Name CloudEvents.Sdk' && \
    find / -name "net45" | xargs rm -rf && \
    mkdir -p /root/.config/powershell && \
    echo '$ProgressPreference = "SilentlyContinue"' > /root/.config/powershell/Microsoft.PowerShell_profile.ps1 && \
    tdnf clean all

COPY server.ps1 ./
COPY handler.ps1 handler.ps1

CMD ["pwsh","./server.ps1"]