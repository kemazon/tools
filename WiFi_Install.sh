#!/bin/bash
# Agregar regla de usb_modeswitch para Realtek 8211CU

sudo chmod 777 /tmp
sudo chmod u+s $(which ping)

REQUIRED_PACKAGES=("dkms")

RULE_FILE="/lib/udev/rules.d/40-usb_modeswitch.rules"
TMP_FILE="/tmp/40-usb_modeswitch.rules.tmp"

RULE_COMMENT="# Realtek 8211CU Wifi AC USB"
RULE_CONTENT='ATTR{idVendor}=="0bda", ATTR{idProduct}=="1a2b", RUN+="/usr/sbin/usb_modeswitch -K -v 0bda -p 1a2b"'

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

# Comprobar si ya existe
if grep -q '0bda.*1a2b' "$RULE_FILE"; then
    echo "⚠️ La regla ya existe en $RULE_FILE"
    exit 0
fi

# Insertar antes de LABEL="modeswitch_rules_end"
sudo awk -v cmt="$RULE_COMMENT" -v rule="$RULE_CONTENT" '
    /LABEL="modeswitch_rules_end"/ {
        print cmt "\n" rule "\n"
    }
    { print }
' "$RULE_FILE" | sudo tee "$TMP_FILE" > /dev/null

# Reemplazar el archivo original
sudo mv "$TMP_FILE" "$RULE_FILE"
sudo chmod 644 "$RULE_FILE"

echo "[√] Regla agregada correctamente"

# Recargar reglas
sudo udevadm control --reload
sudo udevadm trigger
