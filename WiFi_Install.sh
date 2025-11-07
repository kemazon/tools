#!/bin/bash
# Agregar regla de usb_modeswitch para Realtek 8211CU

RULE_FILE="/lib/udev/rules.d/40-usb_modeswitch.rules"
RULE_LINE='# Realtek 8211CU Wifi AC USB\nATTR{idVendor}=="0bda", ATTR{idProduct}=="1a2b", RUN+="/usr/sbin/usb_modeswitch -K -v 0bda -p 1a2b"'

REQUIRED_PACKAGES=("dkms")

sudo chmod u+s $(which ping)

# Verifica conexión a internet
check_internet() {
    if ping -c 1 8.8.8.8 &>/dev/null || ping -c 1 1.1.1.1 &>/dev/null; then
        echo "✔ Conexión a internet disponible."
        return 0
    else
        echo "✖ No hay conexión a internet. No se puede continuar."
		sleep 5
        exit 1
    fi
}

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
            echo "[√] '$package'"
        fi
    done
}

check_internet
install_packages

# Verificar si ya existe
if ! grep -q '0bda.*1a2b' "$RULE_FILE"; then
    echo -e "\n$RULE_LINE" | sudo tee -a "$RULE_FILE" > /dev/null
    echo "[√] Regla agregada correctamente a $RULE_FILE"
	sleep 3
else
    echo "[X] La regla ya existe, no se ha agregado."
    sleep 5
fi

# Recargar reglas de udev
sudo udevadm control --reload
sudo udevadm trigger
