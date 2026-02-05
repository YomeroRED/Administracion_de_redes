#MANUAL DE USUARIO: SCRIPTS DE MONITOREO (WIN/LINUX)
Este manual describe los requisitos y pasos para ejecutar scripts de diagnóstico en entornos virtuales de Windows Server Core 2022 y Rocky Linux 9.

##1. Requisitos Previos

###Hardware (Mínimo recomendado para la VM)
*Procesador: 2 Cores.
*Memoria RAM: 2 GB (Windows Server Core) / 2 GB (Rocky Linux).
*Almacenamiento: 25 GB (Windows Server Core) / 20 GB (Rocky Linux) de espacio libre.
*Red: Adaptador1 conectado a NAT, Adaptador2 conectado a Red interna.

###Hipervisor
VirtualBox.

###Scripts
*check_status.sh
*check_status.ps1

###Credenciales: Usuario con privilegios de Administrador/Root y contraseña establecida.

###Editor de texto: Micro instalado en Windows y nano en Linux.

##2. Flujo de Ejecución
El proceso de uso sigue este orden lógico en caso de no tener las configuraciones iniciales sigue también las que esan marcadas en negrita sino es el caso saltalas:

1.Inicio de la VM: Arrancar los servidores.
2.Logearte: Agregar las credenciales de administrador/root 
2,5.**Configurar el hostname:** usa 'hostnamectl set-hostname ejemplo_nombre' en Linux y en Windows puedes usar 'rename-computer -newname "ejemplo_nombre"'
3.Ejecución: Llamada al script de diagnóstico en linux '.\check_status.sh' y en windows '.\check_status.ps1'.
4.Lectura de Resultados: Visualización de métricas en consola.

##3. Funciones y Comandos Utilizados
*Scripts de Windows (PowerShell)*

### Salida de texto y encabezados
Write-Host: Muestra información en pantalla.

###Identificación del equipo
hostname: Es un comando que devuelve el nombre de red de la computadora.

###Información de red
Get-NetIPAddress: Obtiene la configuración de las interfaces de red (IP, índices, etc.).

-AddressFamily IPv4: Filtra para que solo muestre direcciones IPv4, ignorando las IPv6.

where InterfaceAlias -like "*Red-interna*": Filtra los resultados para buscar una tarjeta de red específica que contenga ese nombre en su etiqueta.

Select IPAddress: De toda la información disponible, solo se queda con el dato de la dirección IP.

Format-Table -HideTableHeaders: Presenta el resultado en formato de tabla, pero oculta el encabezado ("IPAddress") para que la salida sea más limpia.

###consulta de memoria
Get-CimInstance Win32_OperatingSystem: Consulta la clase WMI del sistema operativo para obtener datos de rendimiento y recursos.

[Math]::Round(...): Una función matemática de .NET para redondear los decimales.

/ 1MB: Convierte los valores (que vienen en Kilobytes por defecto en esta clase) a Gigabytes.

$TotalRam / $FreeRam: Son variables creadas para almacenar esos cálculos y mostrarlos después.

###consulta de disco duro
Get-PSDrive C: Obtiene la información de la unidad lógica "C" (espacio usado, libre y total).

Select-Object @{Name=...; Expression=...}: Esto se llama Propiedad Calculada. Se usa para crear una columna personalizada al vuelo, transformando los Bytes originales en Gigabytes mediante la operación ($_.Used/1GB) y redondeando a 2 decimales.

$Disk | Format-Table: Toma la variable con los datos del disco y la imprime en una tabla organizada.

*Scripts de Linux (Bash)*

###Encabezado y fecha
#!/bin/bash: Indica al sistema que este archivo debe ejecutarse usando el intérprete de comandos Bash.

echo: imprime texto en la terminal.

$(date '+%y-%m-%d %H:%M:%S'): Ejecuta el comando date y formatea la salida para mostrar Año-Mes-Día y la hora exacta. El $() se llama sustitución de comando.

###Identificación y red
hostname: Devuelve el nombre del host.

ip addr show enp0s8: Muestra la configuración de la interfaz de red llamada enp0s8.

grep "inet " / grep "inet6 ": Filtra las líneas que contienen las direcciones IPv4 e IPv6 respectivamente.

awk '{print $2}': De la línea filtrada, toma la segunda palabra (donde reside la IP).

cut -d/ -f1: Corta la cadena usando el carácter / como delimitador y se queda con la primera parte (elimina la máscara de red como /24).

${ipv4:-Sin dirección}: Es una expansión de parámetros. Si la variable $ipv4 está vacía, imprime "Sin dirección".

###Almacenamiento (Disco)
df -h: Muestra el uso del espacio de disco en formato Gigas, Megas.

-x tmpfs -x devtmpfs: Excluye del reporte los sistemas de archivos temporales y virtuales que Linux crea en la RAM, dejando solo los discos físicos o particiones reales.

###Memoria RAM
free -h: Muestra la cantidad de memoria libre y usada en el sistema.

grep "Mem:": Filtra para mostrar solo la línea de la memoria física, ignorando la partición de intercambio (Swap).

awk '{print ...}': Organiza la salida para que sea más estética, extrayendo las columnas 2 (Total), 3 (Usado) y 4 (Libre) y añadiéndoles etiquetas de texto.