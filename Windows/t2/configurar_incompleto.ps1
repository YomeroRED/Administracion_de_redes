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

function configurar_DHCP {
    Write-Host "=== Configuracion del ambito (SCOPE) ==="
    
    $ScopeName = Read-Host "Nombre del ambito"
    
    # Validar IP Inicial
    do {
        $StartIP = Read-Host "Ingrese la IP inicial del rango"
        $esValida = Validar-IP $StartIP
        if (-not $esValida) { Write-Host "IP no valida." }
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
            else { Write-Host "La IP final debe ser mayor a la inicial." }
        }
    } while ($true)

    # Configurar IP estática en el servidor (Asumiendo interfaz 'Ethernet')
    Write-Host "Configurando IP estatica en el servidor ($StartIP)..."
    $interface = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1
    New-NetIPAddress -InterfaceAlias $interface.Name -IPAddress $StartIP -PrefixLength ([IPAddress]$Mask).GetAddressBytes() -ErrorAction SilentlyContinue

    # Crear el Scope en el servidor DHCP
    try {
        Add-DhcpServerv4Scope -Name $ScopeName -StartRange $StartIP -EndRange $EndIP -SubnetMask $Mask -State Active
        Write-Host "Ambito creado correctamente."
    } catch {
        Write-Host "Error al crear el ámbito: $_"
    }

    Read-Host "Presione Enter para continuar..."
}