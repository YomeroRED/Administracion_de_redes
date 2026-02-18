Desinstalar_DHCP() {
    echo "Eliminando dhcp-server..."
    dnf remove -y dhcp-server
    echo "Desinstalación completada."
    echo "--------------------------------"
    echo ""
}

verificar_instalacion_DHCP() {
    echo "=== Verificando Estado de DHCP Server ==="

    # 1. Verificar instalación con dnf
    # Buscamos específicamente el paquete en la base de datos de instalados
    if dnf list installed dhcp-server &> /dev/null; then
        echo "Instalación: SOFTWARE INSTALADO"
    else
        echo "Instalación: SOFTWARE NO ENCONTRADO"
        echo "--------------------------------"
        return 1
    fi

    # 2. Verificar si el servicio está corriendo
    # 'is-active' devuelve el estado simplificado (active, inactive, failed)
    ESTADO=$(systemctl is-active dhcpd 2>/dev/null)
    
    if [ "$ESTADO" = "active" ]; then
        echo "Estado:      EN EJECUCION"
    else
        echo "Estado:      DETENIDO ($ESTADO)"
    fi

    # 3. Verificar si está habilitado para iniciar con el sistema
    HABILITADO=$(systemctl is-enabled dhcpd 2>/dev/null)
    echo "Inicio automatico: $HABILITADO"
    echo "--------------------------------"
    echo ""
    read -n 1 -s -p "Presione cualquier tecla para seguir..."
    echo ""
}

Instalar_DHCP() {
    echo "=== Inicio de proceso de instalación ==="

    # 1. Verificar si ya existe una instalación
    if dnf list installed dhcp-server > /dev/null 2>&1; then
        echo "AVISO: Se detectó que dhcp-server ya está instalado en el sistema."
        read -p "¿Desea desinstalar la versión actual y reinstalar? (s/n): " respuesta

        if [ "$respuesta" = "s" ] || [ "$respuesta" = "S" ]; then
            Desinstalar_DHCP
            echo "Procediendo con la nueva instalación..."
        else
            echo "Instalación cancelada por el usuario."
            read -p "Presione Enter para volver al menú..."
            return 0
        fi
    fi

    # 2. Proceder a instalar si no hay nada o si se aceptó reinstalar
    echo "Instalando dhcp-server..."
    if dnf install -y dhcp-server; then
        echo "¡Instalación exitosa!"
    else
        echo "Error: Hubo un problema durante la instalación."
    fi
    echo "--------------------------------"
    echo ""
    read -n 1 -s -p "Presione cualquier tecla para seguir..."
    echo ""
}

validar_ip() {
    local ip=$1
    # Formato básico de IP (4 grupos de números)
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        # Evitar IPs prohibidas
        if [[ $ip == "127.0.0.1" || $ip == "0.0.0.0" || $ip == "255.255.255.255" ]]; then
            return 1
        fi
        return 0
    else
        return 1
    fi
}

configurar_DHCP() {
    echo "=== Configuración del ámbito (SCOPE) ==="
    
    # 1. Datos básicos
    read -p "Nombre del ámbito: " SCOPE_NAME

    # 2. IP inicial y cálculo de máscara/red
    while true; do
        read -p "Ingrese la IP inicial del rango: " START_IP
        if validar_ip "$START_IP"; then break; else echo "IP no válida."; fi
    done

    # Lógica de Máscara Automática
    PRIMER_OCTETO=$(echo $START_IP | cut -d. -f1)
    if [ "$PRIMER_OCTETO" -le 126 ]; then
        MASK="255.0.0.0"; CIDR="8"; NETWORK_BASE="$(echo $START_IP | cut -d. -f1).0.0.0"
    elif [ "$PRIMER_OCTETO" -le 191 ]; then
        MASK="255.255.0.0"; CIDR="16"; NETWORK_BASE="$(echo $START_IP | cut -d. -f1-2).0.0"
    else
        MASK="255.255.255.0"; CIDR="24"; NETWORK_BASE="$(echo $START_IP | cut -d. -f1-3).0"
    fi

    # 3. Asignación automática (Servidor = primera IP)
    SERVER_IP=$START_IP
    OCTETOS_BASE=$(echo $START_IP | cut -d. -f1-3)
    ULTIMO_OCTETO=$(echo $START_IP | cut -d. -f4)
    NUEVO_INICIO=$((ULTIMO_OCTETO + 1))
    DHCP_START="${OCTETOS_BASE}.${NUEVO_INICIO}"

    while true; do
        read -p "Ingrese la IP final del rango: " END_IP
        if validar_ip "$END_IP"; then
            if [ "$END_IP" -gt "$DHCP_START" ]; then break; else echo "Rango final debe ser mayor a $DHCP_START"; fi
        fi
    done

    # 4. Configurar red estática en el sistema
    echo "Configurando interfaz red-interna con IP $SERVER_IP/$CIDR..."
    nmcli connection modify red-interna ipv4.method manual ipv4.addresses "${SERVER_IP}/${CIDR}"
    nmcli connection up red-interna > /dev/null 2>&1

    # 5. Parámetros opcionales y Tiempo de concesión (Validado)
    read -p "Gateway (Enter para omitir): " GATEWAY
    read -p "DNS Server (Enter para omitir): " DNS_SERV

    while true; do
        read -p "Tiempo de concesión en segundos [86400]: " LEASE
        LEASE=${LEASE:-86400}
        if [[ "$LEASE" =~ ^[0-9]+$ ]] && [ "$LEASE" -gt 0 ]; then
            break
        else
            echo "Error: Use solo números enteros positivos (sin decimales)."
        fi
    done

    # 6. Generación del archivo dhcpd.conf
    # Usamos > para sobrescribir el archivo y empezar limpio
    cat <<EOF > /etc/dhcp/dhcpd.conf
# Ámbito: $SCOPE_NAME
default-lease-time $LEASE;
max-lease-time $((LEASE * 2));

subnet $NETWORK_BASE netmask $MASK {
    range $DHCP_START $END_IP;
EOF

    # Añadimos los opcionales si existen (usando >> para no borrar lo anterior)
    [[ -n "$GATEWAY" ]] && echo "    option routers $GATEWAY;" >> /etc/dhcp/dhcpd.conf
    [[ -n "$DNS_SERV" ]] && echo "    option domain-name-servers $DNS_SERV;" >> /etc/dhcp/dhcpd.conf
    
    # Cerramos la llave del bloque subnet
    echo "}" >> /etc/dhcp/dhcpd.conf

    # 7. Verificación final de sintaxis
    echo "-------------------------------------------"
    if dhcpd -t -cf /etc/dhcp/dhcpd.conf > /dev/null 2>&1; then
        echo "Sintaxis verificada correctamente."
        systemctl restart dhcpd
        echo "Servicio DHCP iniciado y configurado."
    else
        echo "Error: La sintaxis del archivo generado es incorrecta."
    fi
    read -p "Presione Enter para continuar..."
}

monitorear_DHCP() {
    echo "=== MONITOREO DE DHCP ==="
    
    # 1. Estado del servicio
    echo "[1] Estado del Proceso:"
    systemctl is-active dhcpd --quiet && echo "    Servicio: CORRIENDO" || echo "    Servicio: CAÍDO"
    
    echo -e "\n[2] Equipos Conectados (Concesiones Activas):"
    echo "-----------------------------------------------------------------"
    printf "%-15s %-18s %-15s\n" "IP Address" "MAC Address" "Hostname"
    echo "-----------------------------------------------------------------"

    # El archivo dhcpd.leases es donde se guardan las asignaciones.
    # Usamos awk para extraer la IP, la MAC y el nombre del equipo.
    LEASES_FILE="/var/lib/dhcpd/dhcpd.leases"

    if [ -f "$LEASES_FILE" ]; then
        awk '
        /^lease/ { ip=$2 }
        /hardware ethernet/ { mac=$3; gsub(/;/, "", mac) }
        /client-hostname/ { name=$2; gsub(/;/, "", name); gsub(/"/, "", name) }
        /^}/ { printf "%-15s %-18s %-15s\n", ip, mac, (name ? name : "N/A"); name="" }
        ' "$LEASES_FILE" | sort -u
    else
        echo "No se encontró el archivo de concesiones o no hay equipos conectados."
    fi

    echo "-----------------------------------------------------------------"
    
    # 2. Ver logs en tiempo real
    echo -e "\n[3] ¿Desea ver los logs en tiempo real (journalctl)? (s/n)"
    read -n 1 -s OPCION
    echo ""
    if [[ "$OPCION" == "s" || "$OPCION" == "S" ]]; then
        echo "Presione Ctrl+C para dejar de monitorear los logs."
        journalctl -u dhcpd -f
    fi

    read -p "Presione Enter para volver al menú..."
}