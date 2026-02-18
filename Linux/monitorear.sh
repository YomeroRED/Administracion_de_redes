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