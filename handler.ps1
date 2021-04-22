Function Process-Handler {
   param(
      [Parameter(Position=0,Mandatory=$true)][CloudNative.CloudEvents.CloudEvent]$CloudEvent
   )

   # Decode CloudEvent
   $cloudEventData = $cloudEvent | Read-CloudEventJsonData -ErrorAction SilentlyContinue -Depth 10
   if($cloudEventData -eq $null) {
      $cloudEventData = $cloudEvent | Read-CloudEventData
   }

   if(${env:FUNCTION_DEBUG} -eq "true") {
      Write-Host "DEBUG: K8s Secrets:`n${env:TAG_SECRET}`n"

      Write-Host "DEBUG: CloudEventData`n $(${cloudEventData} | Out-String)`n"
   }

   if(${env:TAG_SECRET}) {
      $jsonSecrets = ${env:TAG_SECRET} | ConvertFrom-Json
   } else {
      Write-Host "K8s secrets `$env:TAG does not look to be defined"
      break
   }

   # Retrieve VM Name
   $vmName = $cloudEventData.Vm.Name
   $vcenterServer = ${jsonSecrets}.VCENTER_SERVER
   $vcenterUsername = ${jsonSecrets}.VCENTER_USERNAME
   $vcenterPassword = ${jsonSecrets}.VCENTER_PASSWORD
   $vcenterTagName = ${jsonSecrets}.VCENTER_TAG_NAME

   Write-Host "Configuring PowerCLI Configuration Settings"
   Set-PowerCLIConfiguration -Scope:AllUsers -InvalidCertificateAction:Ignore -ParticipateInCeip:$true -Confirm:$false

   Write-Host "Connecting to vCenter Server $vcenterServer"
   $viConnection = Connect-VIServer -Server $vcenterServer -User $vcenterUsername -Password $vcenterPassword

   Write-Host "Applying vSphere Tag `"$vcenterTagName`" to $vmName ..."
   Get-VM $vmName | New-TagAssignment -Tag (Get-Tag -Name $vcenterTagName) -Confirm:$false

   Disconnect-VIServer -Server $viConnection -Confirm:$false
}
