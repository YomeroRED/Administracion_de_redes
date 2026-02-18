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

ip_a_entero() {
    local a b c d
    IFS=. read -r a b c d <<< "$1"
    echo "$(( (a << 24) + (b << 16) + (c << 8) + d ))"
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
        # Convertimos ambas IPs a números enteros para comparar
        START_VAL=$(ip_a_entero "$DHCP_START")
        END_VAL=$(ip_a_entero "$END_IP")

        if [ "$END_VAL" -ge "$START_VAL" ]; then
            break
        else
            echo "Error: La IP final ($END_IP) debe ser mayor o igual a la inicial ($DHCP_START)"
        fi
    else
        echo "IP no válida."
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