#!/bin/bash
#Script: check_status.sh --> muestra informacion basica del sistema

echo "======================="
echo "Información del sistema"
echo "$(date '+%y-%m-%d %H:%M:%S')"
echo "======================="

echo ""

echo "[1] Nombre del equipo:"
hostname
echo ""

echo "[2] Direcciones IP de la red interna:"
ipv4=$(ip addr show enp0s8 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
ipv6=$(ip addr show enp0s8 | grep "inet6 " | awk '{print $2}' | cut -d/ -f1)

echo "IPv4: ${ipv4:-Sin dirección}"
echo "IPv6: ${ipv6:-Sin dirección}"

echo ""

echo "[3] Espacio en disco:"
df -h -x tmpfs -x devtmpfs

echo ""

echo "[4] Memoria RAM:"
free -h | grep "Mem:" | awk '{print " Total: " $2 " |  Usado: " $3 " | Libre: " $4}'

echo ""
