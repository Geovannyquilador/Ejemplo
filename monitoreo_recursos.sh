#!/bin/bash
#Archivo donde almacenaremos los resultados
OUTPUT="reporte_recursos.txt"
#Tiempo de monitoreo
read -p "Ingrese el tiempo de captura de datos (segundos):" m
#Intervalo de captura
read -p "Ingrese el  lapso de tiempo en segundos:" n
#encabezado del archivo de salida
echo "Tempo, % Total de CPU libre, % Memoria Libre, % Disco Libre" > $OUTPUT
#Tiempo transcurrido
capturar_datos(){
	ELAPSED=0
	while [ $ELAPSED -lt $m ]; do
		#Captura % de CPU libre
		CPU_FREE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
		#Captura % de memoria libre
		MEM_FREE=$(free | grep Mem | awk '{print $4/$2 * 100.0}')
		#Captura % de disco libre en el sistema raiz
		DISK_FREE=$(df -h / | grep / | awk '{print 100 - $5}' | sed 's/%//')
		#Guardar en el archivo de salida
		echo "${ELAPSED}s, ${CPU_FREE}, ${MEM_FREE}, ${DISK_FREE}" >> $OUTPUT
		#Esperar el intervalo antes de la siguiente captura de datos
		sleep $n
		ELAPSED=$((ELAPSED + n))
	done
	echo "Captura de datos finalizada"
}

capturar_datos &

echo "La captura de datos se esta ejecutando en segundo plano"
