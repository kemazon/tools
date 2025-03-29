#!/bin/bash

# Lista de paquetes requeridos
REQUIRED_PACKAGES=("curl" "wget" "unzip" "lynx")

# Definir ruta de descarga
if [ -d "/roms2/tools" ]; then
    SCRIPT_DEST="/roms2/tools/downloader.sh"
elif [ -d "/roms/tools" ]; then
    SCRIPT_DEST="/roms/tools/downloader.sh"
else
    echo "❌ No se encontró ninguna de las rutas /roms2/tools ni /roms/tools."
    exit 1
fi

# URL del script a descargar
SCRIPT_URL="https://raw.githubusercontent.com/kemazon/tools/refs/heads/main/downloader.sh"

GPTK_URL="https://raw.githubusercontent.com/kemazon/tools/refs/heads/main/downloader.gptk"
GPTK_DEST="/opt/inttools/downloader.gptk"

RC_URL="https://raw.githubusercontent.com/kemazon/tools/refs/heads/main/.lynxrc"
RC_DEST="/home/ark/.lynxrc"

CFG_URL="https://raw.githubusercontent.com/kemazon/tools/refs/heads/main/lynx.cfg"
CFG_DEST="/etc/lynx/lynx.cfg"

sudo chmod u+s $(which ping)

# Verifica conexión a internet
check_internet() {
    if ping -c 1 8.8.8.8 &>/dev/null; then
        echo "✔ Conexión a internet disponible."
        return 0
    else
        echo "✖ No hay conexión a internet. No se puede continuar."
		sleep 5
        exit 1
    fi
}

# Verifica e instala paquetes según la distribución
install_packages() {
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! command -v "$package" &>/dev/null; then
            echo "⚠ El paquete '$package' no está instalado. Instalando..."
            if [[ -f /etc/debian_version ]]; then
                sudo apt update && sudo apt install -y "$package"
            elif [[ -f /etc/arch-release ]]; then
                sudo pacman -Sy --noconfirm "$package"
            else
                echo "❌ No se pudo determinar la distribución. Instale '$package' manualmente."
                exit 1
            fi
        else
            echo "✔ El paquete '$package' ya está instalado."
        fi
    done
}

# Descarga el script si todo está bien
download_script() {
    echo "⬇ Descargando script desde $SCRIPT_URL..."
    wget -O "$SCRIPT_DEST" "$SCRIPT_URL" || curl -o "$SCRIPT_DEST" "$SCRIPT_URL"
	wget -O "$GPTK_DEST" "$GPTK_URL" || curl -o "$GPTK_DEST" "$GPTK_URL"
	wget -O "$RC_DEST" "$RC_URL" || curl -o "$RC_DEST" "$RC_URL"
	sudo wget -O "$CFG_DEST" "$CFG_URL" || sudo curl -o "$CFG_DEST" "$CFG_URL"
    chmod +x "$SCRIPT_DEST"
    echo "✔ Script descargado y marcado como ejecutable en $SCRIPT_DEST."
	echo "✔ INSTALACIÓN COMPLETA, REINICIANDO."
	sleep 4
	sudo systemctl restart emulationstation
}

# Ejecutar funciones
check_internet
install_packages
download_script
