. .\verificar.ps1
. .\instalar_e_desinstalar.ps1
. .\configurar.ps1
. .\monitorear.ps1

function Mostrar-Opciones {
    Write-Host ""
    Write-Host "===========================================================================" 
    Write-Host "Panel de control del servicio DHCP"
    Write-Host "==========================================================================="
    Write-Host ""
    Write-Host "[1] Verificar instalacion"
    Write-Host "[2] Instalar o reinstalar Dhcp"
    Write-Host "[3] Configurar dhcp"
    Write-Host "[4] Monitorear"
    Write-Host "[5] Desinstalar dhcp"
    Write-Host "[6] Salir"
    Write-Host ""
    
    $global:accion = Read-Host "Accion a realizar"
}

# Inicializamos la variable
$global:accion = 0

# Bucle principal
do {
    Mostrar-Opciones

    switch ($global:accion) {
        1 { verificar_instalacion_DHCP }
        2 { instalar_DHCP }
        3 { configurar_DHCP }
        4 { monitorear_DHCP }
        5 { Desinstalar_DHCP }
        6 { Write-Host "Saliendo..." }
        Default { 
            Write-Host "Error: prueba con numeros del 1-6" 
        }
    }

} until ($global:accion -eq 6)