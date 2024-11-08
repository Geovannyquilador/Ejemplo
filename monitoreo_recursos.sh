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

# Ejecuta la captura de datos en segundo plano
capturar_datos &

echo "La captura de datos se está ejecutando en segundo plano"
