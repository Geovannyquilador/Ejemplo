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

# Definición de variables
DIR_REMOTO="/home/usuario/respaldo"    # Ruta del directorio remoto
DIR_LOCAL="/home/usuario/directorio_respaldo"   # Ruta local para el respaldo
FECHA=$(date +"%Y%m%d")                # Fecha en formato YYYYMMDD
MAX_RESPALDOS=5                       # Número máximo de respaldos permitidos

# Crear un archivo con la dirección IP local en el directorio local
IP_LOCAL=$(hostname -I | awk '{print $1}')
echo $IP_LOCAL > $DIR_LOCAL/servidor.txt

# Comprimir el directorio local a respaldar
tar -czvf $DIR_LOCAL/$FECHA.gz $DIR_LOCAL

# Contar los respaldos existentes en el directorio local
NUM_RESPALDOS=$(ls -d $DIR_LOCAL/*/ 2>/dev/null | wc -l)

# Si existen más de 5 respaldos, eliminar los más antiguos
if [ $NUM_RESPALDOS -ge $MAX_RESPALDOS ]; then
    echo "Existen $NUM_RESPALDOS respaldos, eliminando los más antiguos..."
    ls -dt $DIR_LOCAL/*/ | tail -n +$(($MAX_RESPALDOS + 1)) | xargs rm -rf
fi

# Realizar el backup incremental con rsync al servidor remoto
USUARIO="usuario"
SERVIDOR="servidor_remoto"
rsync -avz --delete --link-dest=$DIR_REMOTO/backup_$(date --date="yesterday" +"%Y%m%d") $DIR_LOCAL $USUARIO@$SERVIDOR:$DIR_REMOTO/backup_$FECHA

# Limpiar la carpeta de backups remotos si supera el límite
BACKUPS_EN_REMOTO=$(ssh $USUARIO@$SERVIDOR "ls $DIR_REMOTO | grep -c 'backup_'")
if [ $BACKUPS_EN_REMOTO -gt $MAX_RESPALDOS ]; then
    ssh $USUARIO@$SERVIDOR "ls -t $DIR_REMOTO/backup_* | tail -n +$(($MAX_RESPALDOS + 1)) | xargs rm -rf"
fi

echo "Backup completado correctamente."

# Ejecuta la captura de datos en segundo plano
capturar_datos &

echo "La captura de datos se está ejecutando en segundo plano"
