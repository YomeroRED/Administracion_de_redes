function Validar-IP {
    param([string]$IP)
    $ip_obj = $null
    # Verifica si es un formato de IP válido y no está en la lista negra
    if ([System.Net.IPAddress]::TryParse($IP, [ref]$ip_obj)) {
        $blackList = @("127.0.0.1", "0.0.0.0", "255.255.255.255")
        if ($blackList -contains $IP) { return $false }
        return $true
    }
    return $false
}

function IP-A-Entero {
    param([string]$IP)
    $bytes = ([System.Net.IPAddress]::Parse($IP)).GetAddressBytes()
    if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($bytes) }
    return [BitConverter]::ToUInt32($bytes, 0)
}

function Configurar_DHCP {
    Write-Host "=== Configuracion del ambito (SCOPE) ==="

    # 1. Datos básicos
    $ScopeName = Read-Host "Nombre del ambito"

    # 2. IP inicial y lógica de máscara automática
    while ($true) {
        $START_IP = Read-Host "Ingrese la IP inicial del rango (Esta sera la IP del Servidor)"
        if (Validar-IP $START_IP) { break } else { Write-Host "IP no valida." }
    }

    $primerOcteto = [int]($START_IP.Split('.')[0])
    if ($primerOcteto -le 126) {
        $MASK = "255.0.0.0"; $CIDR = 8; $NETWORK_BASE = "$($START_IP.Split('.')[0]).0.0.0"
    } elseif ($primerOcteto -le 191) {
        $MASK = "255.255.0.0"; $CIDR = 16; $NETWORK_BASE = "$($START_IP.Split('.')[0..1] -join '.').0.0"
    } else {
        $MASK = "255.255.255.0"; $CIDR = 24; $NETWORK_BASE = "$($START_IP.Split('.')[0..2] -join '.').0"
    }

    # 3. Asignación automática (DHCP Start = IP Servidor + 1)
    $SERVER_IP = $START_IP
    $ipBase = $START_IP.Split('.')[0..2] -join '.'
    $ultimoOcteto = [int]($START_IP.Split('.')[3])
    $DHCP_START = "$ipBase.$($ultimoOcteto + 1)"

    while ($true) {
        $END_IP = Read-Host "Ingrese la IP final del rango"
        if (Validar-IP $END_IP) {
            if ((IP-A-Entero $END_IP) -ge (IP-A-Entero $DHCP_START)) { break }
            else { Write-Host "Error: La IP final ($END_IP) debe ser mayor a la inicial ($DHCP_START)" }
        } else { Write-Host "IP no valida." }
    }

    # 4. Configurar red estática en el sistema
    Write-Host "Configurando interfaz con IP $SERVER_IP/$CIDR..."
    $interfaceName = "Red-interna"
    
    	# 1. Eliminamos cualquier IP previa en esa interfaz para evitar conflictos
    Remove-NetIPAddress -InterfaceAlias $interfaceName -Confirm:$false -ErrorAction SilentlyContinue
    	# 2. Asignamos la nueva
    New-NetIPAddress -InterfaceAlias $interfaceName -IPAddress $SERVER_IP -PrefixLength $CIDR -Confirm:$false -ErrorAction SilentlyContinue

    # 5. Parámetros opcionales y Tiempo de concesión
    $GATEWAY = Read-Host "Gateway (Enter para omitir)"
    $DNS_SERV = Read-Host "DNS Server (Enter para omitir)"

    while ($true) {
        $LEASE_INPUT = Read-Host "Tiempo de concesion en segundos [86400]"
        if ([string]::IsNullOrWhiteSpace($LEASE_INPUT)) { $LEASE = 86400; break }
        if ($LEASE_INPUT -match '^\d+$' -and [int]$LEASE_INPUT -gt 0) { $LEASE = [int]$LEASE_INPUT; break }
        Write-Host "Error: Use solo numeros enteros positivos."
    }
    # Convertir segundos a formato TimeSpan para Windows (Días:Horas:Minutos:Segundos)
    $ts = [TimeSpan]::FromSeconds($LEASE)

    # 6. Ejecución de comandos DHCP de Windows (Idempotencia)
    Write-Host "-------------------------------------------"
    try {
	Get-DhcpServerv4Scope | Remove-DhcpServerv4Scope -Force -ErrorAction SilentlyContinue

        # Crear Ámbito
        Add-DhcpServerv4Scope -Name $ScopeName -StartRange $DHCP_START -EndRange $END_IP -SubnetMask $MASK -LeaseDuration $ts -ErrorAction Stop
	Set-DhcpServerv4Scope -ScopeId $NETWORK_BASE -State Active -ErrorAction SilentlyContinue

	Add-DhcpServerv4ExclusionRange -ScopeId $NETWORK_BASE -StartRange $SERVER_IP -EndRange $SERVER_IP
        
        # Configurar Opciones si se proveyeron
        if ($GATEWAY) { Set-DhcpServerv4OptionValue -ScopeId $NETWORK_BASE -OptionId 3 -Value $GATEWAY }
        if ($DNS_SERV) { Set-DhcpServerv4OptionValue -ScopeId $NETWORK_BASE -OptionId 6 -Value $DNS_SERV }

        Write-Host "Servicio DHCP configurado y Ámbito '$ScopeName' activo."
    } catch {
        Write-Host "Error al configurar DHCP: $($_.Exception.Message)"
    }

    Read-Host "Presione Enter para continuar..."
}