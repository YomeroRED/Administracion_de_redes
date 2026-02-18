New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Name "RepairContentServerSource" -Value 2 -PropertyType DWORD -Force
gpupdate /force

Install-WindowsFeature -Name DHCP -IncludeManagementTools


# Reinicia el servicio de Windows Update
#Restart-Service wuauserv

# Intenta la instalación indicando que use Windows Update explícitamente
#Install-WindowsFeature -Name DHCP -IncludeManagementTools -Source WindowsUpdate


para mañana 
Mount-DiskImage -ImagePath "C:\Ruta\Tu_Imagen.iso"
# Luego revisa qué letra de unidad le dio:
Get-Volume