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
clear
}