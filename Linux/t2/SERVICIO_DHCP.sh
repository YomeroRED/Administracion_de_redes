#!/bin/bash
#Scrip: menu del servicio DHCP

. ./verificar.sh
. ./instalar_e_desinstalar.sh
. ./configurar.sh
. ./monitorear.sh

opciones() {
        echo ""
        echo "==========================================================================="
        echo "Panel de control del servicio DHCP"
        echo ""
        echo "==========================================================================="

        echo ""

        echo "[1] Verificar instalación"
        echo "[2] Instalar o reinstalar Dhcp"
        echo "[3] Configurar dhcp"
        echo "[4] Monitorear"
        echo "[5] Desinstalar dhcp"
        echo "[6] Salir"

        echo ""

        read -p "Acción a realizar: " accion
}
opciones

until [ "$accion" -eq 6 ] 2>/dev/null; do
        case $accion in
                1)
                        verificar_instalacion_DHCP
                        ;;
                2)

                        instalar_DHCP
                        ;;

                3)
                        configurar_DHCP
                        ;;

                4)
                        monitorear_DHCP
                        ;;

                5)
                        Desinstalar_DHCP
                        ;;
                6)
                        echo "Saliendo..."
                        ;;

                *)
                        echo "Error: prueba con números del 1-6"
                        ;;
        esac

        if [ "$accion" -ne 6 ]; then
                opciones
        fi

done
