# ==========================================
# FUNCIONES AUXILIARES
# ==========================================

function Validar-IP {
    param([string]$ip)
    # Regex para validar formato IPv4
    if ($ip -match '^(\d{1,3}\.){3}\d{1,3}$') {
        # Evitar IPs prohibidas
        if ($ip -eq "127.0.0.1" -or $ip -eq "0.0.0.0" -or $ip -eq "255.255.255.255") {
            return $false
        }
        return $true
    }
    return $false
}

function IP-A-Entero {
    param([string]$ip)
    $octetos = $ip.Split('.')
    return ([int64]$octetos[0] -shl 24) + ([int64]$octetos[1] -shl 16) + ([int64]$octetos[2] -shl 8) + [int64]$octetos[3]
}

# ==========================================
# FUNCIONES PRINCIPALES
# ==========================================

function Desinstalar_DHCP {
    Write-Host "Eliminando rol de Servidor DHCP..." -ForegroundColor Yellow
    Uninstall-WindowsFeature -Name DHCP -Remove -IncludeManagementTools
    Write-Host "Desinstalación completada."
    Write-Host "--------------------------------"
}

function verificar_instalacion_DHCP {
    Write-Host "=== Verificando Estado de DHCP Server ===" -ForegroundColor Cyan

    # 1. Verificar si el Rol está instalado
    $feature = Get-WindowsFeature -Name DHCP
    if ($feature.Installed) {
        Write-Host "Instalación: SOFTWARE INSTALADO" -ForegroundColor Green
    } else {
        Write-Host "Instalación: SOFTWARE NO ENCONTRADO" -ForegroundColor Red
        Write-Host "--------------------------------"
        return
    }

    # 2. Verificar estado del servicio (dhcp)
    $service = Get-Service -Name DHCPServer -ErrorAction SilentlyContinue
    if ($service.Status -eq "Running") {
        Write-Host "Estado:      EN EJECUCION" -ForegroundColor Green
    } else {
        Write-Host "Estado:      DETENIDO ($($service.Status))" -ForegroundColor Yellow
    }

    # 3. Verificar tipo de inicio
    Write-Host "Inicio automático: $($service.StartType)"
    Write-Host "--------------------------------"
    Read-Host "Presione Enter para seguir..."
}

function instalar_DHCP {
    Write-Host "=== Inicio de proceso de instalación ===" -ForegroundColor Cyan

    # 1. Verificar si ya existe
    $feature = Get-WindowsFeature -Name DHCP
    if ($feature.Installed) {
        Write-Host "AVISO: El rol DHCP ya está instalado." -ForegroundColor Yellow
        $resp = Read-Host "¿Desea desinstalar y reinstalar? (s/n)"
        if ($resp -eq "s") {
            Desinstalar_DHCP
            Write-Host "Procediendo con la instalación..."
        } else {
            return
        }
    }

    # 2. Instalar Rol y Herramientas de administración
    Write-Host "Instalando Rol DHCP..."
    Install-WindowsFeature -Name DHCP -IncludeManagementTools
    
    # Autorizar en AD (opcional, solo si es Server en Dominio)
    # Add-DhcpServerInDC -DnsName "nombre.dominio"
    
    Write-Host "¡Instalación exitosa!" -ForegroundColor Green
    Read-Host "Presione Enter para seguir..."
}

function configurar_DHCP {
    Write-Host "=== Configuración del ámbito (SCOPE) ===" -ForegroundColor Cyan
    
    $ScopeName = Read-Host "Nombre del ámbito"
    
    # Validar IP Inicial
    do {
        $StartIP = Read-Host "Ingrese la IP inicial del rango"
        $esValida = Validar-IP $StartIP
        if (-not $esValida) { Write-Host "IP no válida." -ForegroundColor Red }
    } until ($esValida)

    # Lógica de Máscara (Clases A, B, C)
    $primerOcteto = [int]($StartIP.Split('.')[0])
    if ($primerOcteto -le 126) { $Mask = "255.0.0.0" }
    elseif ($primerOcteto -le 191) { $Mask = "255.255.0.0" }
    else { $Mask = "255.255.255.0" }

    # IP Final
    do {
        $EndIP = Read-Host "Ingrese la IP final del rango"
        if (Validar-IP $EndIP) {
            if (IP-A-Entero $EndIP -ge IP-A-Entero $StartIP) { break }
            else { Write-Host "La IP final debe ser mayor a la inicial." -ForegroundColor Red }
        }
    } while ($true)

    # Configurar IP estática en el servidor (Asumiendo interfaz 'Ethernet')
    Write-Host "Configurando IP estática en el servidor ($StartIP)..."
    $interface = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1
    New-NetIPAddress -InterfaceAlias $interface.Name -IPAddress $StartIP -PrefixLength ([IPAddress]$Mask).GetAddressBytes() -ErrorAction SilentlyContinue

    # Crear el Scope en el servidor DHCP
    try {
        Add-DhcpServerv4Scope -Name $ScopeName -StartRange $StartIP -EndRange $EndIP -SubnetMask $Mask -State Active
        Write-Host "Ámbito creado correctamente." -ForegroundColor Green
    } catch {
        Write-Host "Error al crear el ámbito: $_" -ForegroundColor Red
    }

    Read-Host "Presione Enter para continuar..."
}

function monitorear_DHCP {
    Write-Host "=== MONITOREO DE DHCP ===" -ForegroundColor Cyan
    
    # 1. Estado del servicio
    $status = Get-Service -Name DHCPServer
    Write-Host "[1] Estado del Proceso: $($status.Status)"

    # 2. Equipos Conectados (Leases)
    Write-Host "`n[2] Equipos Conectados (Concesiones Activas):"
    $scopes = Get-DhcpServerv4Scope
    foreach ($s in $scopes) {
        Write-Host "Ámbito: $($s.ScopeId) ($($s.Name))" -ForegroundColor DarkCyan
        Get-DhcpServerv4Lease -ScopeId $s.ScopeId | Select-Object IPAddress, ClientId, HostName | Format-Table
    }

    # 3. Logs (Visor de eventos de Windows)
    $verLogs = Read-Host "¿Desea ver los últimos 10 eventos de DHCP? (s/n)"
    if ($verLogs -eq "s") {
        Get-EventLog -LogName System -Source "Microsoft-Windows-DHCP-Server" -Newest 10
    }

    Read-Host "Presione Enter para volver al menú..."
}