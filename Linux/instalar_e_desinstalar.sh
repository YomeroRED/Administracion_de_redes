Desinstalar_DHCP() {
    echo "Eliminando dhcp-server..."
    dnf remove -y dhcp-server
    echo "Desinstalación completada."
    echo "--------------------------------"
    echo ""
}

instalar_DHCP() {
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
clear
}