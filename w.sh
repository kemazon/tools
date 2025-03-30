#!/bin/bash
printf "\033c" > /dev/tty1
lsusb
# Verificar si el adaptador Wi-Fi está detectado por el sistema
echo "Revisando adaptador Wi-Fi en puerto OTG..."
if lsusb | grep -i "wifi\|wireless"; then
    echo "Adaptador Wi-Fi detectado."
else
    echo "Adaptador Wi-Fi no detectado en lsusb."
    exit 1
fi

# Verificar si el adaptador aparece en la lista de interfaces de red
if ip link show | grep -q "wlan0"; then
    echo "Interfaz Wi-Fi detectada:"
    ip link show | grep "wlan0"
else
    echo "No se detectó interfaz Wi-Fi."
    exit 1
fi

# Verificar si el adaptador tiene conectividad a una red
if nmcli device status | grep -i "wlan0   wifi      connected"; then
    echo "El adaptador Wi-Fi está conectado a una red."
else
    echo "El adaptador Wi-Fi no está conectado a ninguna red."
	echo "apagando el radio WiFi"
	sudo nmcli radio all off
	sleep 5
	echo "encendiendo el radio WiFi"
	sudo nmcli radio all on
	sleep 15
fi

# Probar conectividad a Internet con un ping
echo "Probando conectividad a Internet..."
if ping -c 4 8.8.8.8 > /dev/null 2>&1; then
    echo "Conectividad a Internet verificada."
else
    echo "No hay conexión a Internet."
fi
sleep 10
