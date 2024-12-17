#!/bin/bash
# Archivo donde almacenaremos los resultados
OUTPUT="reporte_recursos.txt"
# Archivo de salida de la gráfica
GRAPH="grafica_recursos.png"

# Tiempo de monitoreo
read -p "Ingrese el tiempo de captura de datos (segundos):" m
# Intervalo de captura
read -p "Ingrese el lapso de tiempo en segundos:" n

# Encabezado del archivo de salida
echo "Tiempo, % CPU Libre, % Memoria Libre, % Disco Libre" > $OUTPUT

# Función para capturar datos
capturar_datos(){
    ELAPSED=0
    while [ $ELAPSED -lt $m ]; do
        # Captura % de CPU libre
        CPU_FREE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
        # Captura % de memoria libre
        MEM_FREE=$(free | grep Mem | awk '{print $4/$2 * 100.0}')
        # Captura % de disco libre en el sistema raiz
        DISK_FREE=$(df -h / | grep / | awk '{print 100 - $5}' | sed 's/%//')
        # Guardar en el archivo de salida
        echo "${ELAPSED}s, ${CPU_FREE}, ${MEM_FREE}, ${DISK_FREE}" >> $OUTPUT
        # Esperar el intervalo antes de la siguiente captura de datos
        sleep $n
        ELAPSED=$((ELAPSED + n))
    done
    echo "Captura de datos finalizada"
    generar_grafica
}

# Función para generar la gráfica
generar_grafica(){
    gnuplot -persist <<-EOFMarker
        set terminal png size 800,600
        set output "$GRAPH"
        set title "Monitoreo de Recursos del Sistema"
        set xlabel "Tiempo (s)"
        set ylabel "Porcentaje (%)"
        set grid
        set key outside
        plot "$OUTPUT" using 1:2 with lines title "% CPU Libre", \
             "$OUTPUT" using 1:3 with lines title "% Memoria Libre", \
             "$OUTPUT" using 1:4 with lines title "% Disco Libre"
EOFMarker
    echo "Gráfica generada en $GRAPH"
}

?????????????????????????????

#!/bin/bash

# Ruta del directorio de respaldo en el servidor local
DIR_REMOTO="/home/usuario/respaldo"  # Directorio remoto de respaldo

# Contar el número de archivos en el directorio
NUM_ARCHIVOS=$(ls -1 $DIR_REMOTO | wc -l)

# Si hay 5 o más archivos, eliminar todos los archivos
if [ $NUM_ARCHIVOS -ge 5 ]; then
    rm -rf $DIR_REMOTO/*
fi

???????????????????????????????

#!/bin/bash

# Variables
DIR_LOCAL="/home/usuario/directorio_local"    # Directorio local a respaldar
DIR_REMOTO="/home/usuario/respaldo"           # Directorio remoto
FECHA=$(date +%Y%m%d_%H%M)                    # Fecha y hora actual (YYYYMMDD_HHMM)
USUARIO="usuario"                             # Usuario remoto
SERVIDOR="192.168.1.100"                      # IP o dominio del servidor remoto
NOMBRE_BACKUP="backup_$FECHA.tar.gz"          # Nombre del archivo comprimido
PING_FILE="ping_result_$FECHA.txt"            # Archivo con el resultado de ping
IP_FILE="ip_local_$FECHA.txt"                 # Archivo con la IP de la máquina local
NUEVA_CARPETA="$DIR_REMOTO/$FECHA"            # Carpeta donde se almacenará el backup
PASSWORD="contraseña_remota"                  # Contraseña SSH (cámbiala por la real)

# Verificar conexión SSH con el servidor remoto usando sshpass
echo "Comprobando conexión SSH con el servidor remoto..."
if ! sshpass -p "$PASSWORD" ssh -q -o ConnectTimeout=5 "$USUARIO@$SERVIDOR" exit; then
    echo "No se pudo establecer conexión SSH con $SERVIDOR. Verifique la conexión y vuelva a intentarlo."
    exit 1
fi

# Verificar conectividad con el servidor remoto (5 pings)
echo "Verificando conectividad con el servidor..."
ping -c 5 "$SERVIDOR" > "$DIR_LOCAL/$PING_FILE"

# Capturar la dirección IP local y almacenarla
echo "Obteniendo IP de la máquina local..."
ip a | awk '/inet / && !/127.0.0.1/ {print $2}' > "$DIR_LOCAL/$IP_FILE"

# Comprimir el directorio local para respaldo
echo "Creando el archivo comprimido..."
tar -czvf "$DIR_LOCAL/$NOMBRE_BACKUP" -C "$(dirname "$DIR_LOCAL")" "$(basename "$DIR_LOCAL")"

# Verificar la cantidad de carpetas en el directorio remoto
echo "Verificando la cantidad de carpetas en el servidor remoto..."
EXISTENTES=$(sshpass -p "$PASSWORD" ssh "$USUARIO@$SERVIDOR" "cd $DIR_REMOTO && ls -1dt */ | wc -l")

# Si hay 5 o más carpetas, eliminar todas
if [ "$EXISTENTES" -ge 5 ]; then
    echo "Han pasado 5 minutos o más. Eliminando todas las carpetas de respaldo..."
    sshpass -p "$PASSWORD" ssh "$USUARIO@$SERVIDOR" "rm -rf $DIR_REMOTO/*"
fi

# Crear una nueva carpeta con el nombre basado en la fecha y hora
echo "Creando nueva carpeta $NUEVA_CARPETA..."
sshpass -p "$PASSWORD" ssh "$USUARIO@$SERVIDOR" "mkdir -p $NUEVA_CARPETA"

# Transferir el backup usando rsync (copia incremental)
echo "Enviando respaldo al servidor remoto..."
sshpass -p "$PASSWORD" rsync -avz --delete "$DIR_LOCAL/" "$USUARIO@$SERVIDOR:$NUEVA_CARPETA/"

# Verificar si la transferencia fue exitosa
if [ $? -eq 0 ]; then
    echo "Respaldo realizado exitosamente en $SERVIDOR:$NUEVA_CARPETA/"
else
    echo "Hubo un error al realizar el respaldo."
    exit 1
fi

echo "Tarea completada correctamente."
