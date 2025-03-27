#!/bin/bash
#sudo nmui

sudo chmod 666 /dev/tty1
#printf "\033c" > /dev/tty1
reset

# hide cursor
printf "\e[?25l" > /dev/tty1
dialog --clear

height="15"
width="55"

if test ! -z "$(cat /home/ark/.config/.DEVICE | grep RG503 | tr -d '\0')"
then
  height="20"
  width="60"
elif test ! -z "$(cat /home/ark/.config/.DEVICE | grep RGB20PRO | tr -d '\0')"
then
  height="20"
  width="70"
fi

export TERM=linux
export XDG_RUNTIME_DIR=/run/user/$UID/

if [[ ! -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
  if test ! -z "$(cat /home/ark/.config/.DEVICE | grep RG503 | tr -d '\0')"
  then
    sudo setfont /usr/share/consolefonts/Lat7-TerminusBold20x10.psf.gz
  elif test ! -z "$(cat /home/ark/.config/.DEVICE | grep RGB20PRO | tr -d '\0')"
  then
    sudo setfont /usr/share/consolefonts/Lat7-TerminusBold32x16.psf.gz
  else
    sudo setfont /usr/share/consolefonts/Lat7-TerminusBold22x11.psf.gz
  fi
else
  sudo setfont /usr/share/consolefonts/Lat7-Terminus16.psf.gz
fi

pgrep -f gptokeyb | sudo xargs kill -9
pgrep -f osk.py | sudo xargs kill -9
printf "\033c" > /dev/tty1
printf "Iniciando BT Manager.  Espera..." > /dev/tty1

old_ifs="$IFS"

ToggleWifi() {
  dialog --infobox "\nActivando el BT $1, espera..." 5 $width > /dev/tty1
  if [[ ${1} == "Off" ]]; then
	sudo systemctl stop bluetooth.service &
	sudo rfkill block bluetooth
  else
	sudo rfkill unblock bluetooth
	sudo systemctl enable bluetooth.service
	sudo systemctl start bluetooth.service
	sleep 5
  fi
  MainMenu
}

ExitMenu() {
  printf "\033c" > /dev/tty1
  if [[ ! -z $(pgrep -f gptokeyb) ]]; then
    pgrep -f gptokeyb | sudo xargs kill -9
  fi
  if [[ ! -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
    sudo setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
  fi
  exit 0
}

DeleteConnect() {
  cur_ap=`bluetoothctl info | grep Name | cut -c 8-24`
  if [[ -z $cur_ap ]]; then
    cur_ap=`bluetoothctl info | grep Device | cut -c 8-24`
  fi

  dialog --clear --backtitle "Borrar: Conexión con $cur_ap" --title "Eliminando $1" --clear \
  --yesno "\nDeseas eliminar el emparejamiento con: $cur_ap" $height $width 2>&1 > /dev/tty1
  if [[ $? != 0 ]]; then
    exit 1
  fi
  case $? in
    0) 
        sudo bluetoothctl disconnect "$1"
        sleep 1
        sudo rfkill unblock bluetooth
        sleep 1
        sudo bluetoothctl untrust "$1"
        sleep 1
        sudo bluetoothctl remove "$1"
        sleep 1
		pulseaudio -k
		sleep 0.5
		pulseaudio --start
        ;;
  esac

  #Delete
}

Activate() {

clist=`bluetoothctl paired-devices | awk '{$1=""; print $2"-"substr($0, index($0,$3))}'`
  if [ -z "$clist" ]; then
    clist="Atención:-NO HAY DISPOSITIVOS EMPAREJADOS"
  fi
 
  # Set colon as the delimiter
  IFS='-'
  unset coptions
  while IFS= read -r clist; do
    # Read the split words into an array based on colon delimiter
    read -a strarr <<< "$clist"
    MAC=`printf "${strarr[0]}"`
    NOMBRE=`printf "${strarr[1]}"`
    coptions+=("$MAC" "$NOMBRE")
  done <<< "$clist"

  while true; do
    cselection=(dialog \
   	--backtitle "Dispositivos ya emparejados:" \
   	--title "MAC       NOMBRE" \
   	--no-collapse \
   	--clear \
	--cancel-label "Atrás" \
    --menu "" $height $width 15)

    cchoices=$("${cselection[@]}" "${coptions[@]}" 2>&1 > /dev/tty1) || MainMenu
	if [[ $? != 0 ]]; then
	  exit 1
	fi

    for cchoice in $cchoices; do
      case $cchoice in
        *) Select $cchoice ;;
      esac
    done
  done
}

Select() {
  dialog --infobox "\nConectando al Bluetooth $1 ..." 5 $width > /dev/tty1
  clist2=bluetoothctl paired-devices | awk '{$1=""; print $2":"substr($0, index($0,$3))}'
  
  connection_output=$(sudo bluetoothctl trust "$1")
  connection_output=$(sudo bluetoothctl pair "$1")
  connection_output=$(pulseaudio -k -v)
  connection_output=$(pulseaudio --start -v)
  connection_output=$(sudo bluetoothctl connect "$1")

  # Verificar si la conexión fue exitosa
  if echo "$connection_output" | grep -q 'Connection successful'; then
      output="Dispositivo emparejado y conectado al BT ..."
  else
      output="La conexión ha fallado, intentalo nuevamente ..."
  fi

  echo "$output"
  
  dialog --infobox "\n$output" 6 $width > /dev/tty1
  sleep 3
  #Connect
}

Connect() {
  dialog --infobox "\nBuscando dispositivos Bluetooth ..." 5 $width > /dev/tty1
  sleep 1
  # Iniciar el escaneo
  bluetoothctl scan on &
  SCAN_PID=$!
  sleep 20
  bluetoothctl scan off
  kill $SCAN_PID 2>/dev/null

  clist=`bluetoothctl devices | awk '{$1=""; print $2"-"substr($0, index($0,$3))}'`
  if [ -z "$clist" ]; then
    clist="Atención:-NO HAY DISPOSITIVOS CERCANOS"
  fi
    # Set colon as the delimiter
  IFS='-'
  unset coptions
  while IFS= read -r clist; do
    # Read the split words into an array based on colon delimiter
    read -a strarr <<< "$clist"
    MAC=`printf "${strarr[0]}"`
    NOMBRE=`printf "${strarr[1]}"`
    coptions+=("$MAC" "$NOMBRE")
  done <<< "$clist"

  while true; do
    cselection=(dialog \
   	--backtitle "Dispositivos disponibles:" \
   	--title "MAC  NOMBRE" \
   	--no-collapse \
   	--clear \
	--cancel-label "Atrás" \
    --menu "" $height $width 15)

    cchoices=$("${cselection[@]}" "${coptions[@]}" 2>&1 > /dev/tty1) || MainMenu
	if [[ $? != 0 ]]; then
	  exit 1
	fi
    for cchoice in $cchoices; do
      case $cchoice in
        *) Select $cchoice ;;
      esac
    done
  done
}

Delete() {
  dialog --infobox "\nListando dispositivos emparejados ..." 5 $width > /dev/tty1
  sleep 2
  
  # Obtener la lista de dispositivos emparejados
  clist=$(bluetoothctl paired-devices | awk '{$1=""; print $2"-"substr($0, index($0,$3))}')

  # Si la lista está vacía, asignar mensaje de advertencia
  if [ -z "$clist" ]; then
    clist="Atención-NO HAY DISPOSITIVOS EMPAREJADOS"
    no_devices=true
  else
    no_devices=false
  fi

  # Limpiar la variable deloptions antes de llenarla
  unset deloptions

  # Procesar la lista de dispositivos
  IFS=$'\n'
  for line in $clist; do
    IFS='-' read -r MAC NOMBRE <<< "$line"
    deloptions+=("$MAC" "$NOMBRE")
  done

  # Si no hay dispositivos emparejados, mostrar solo el mensaje de advertencia sin permitir selección
  if $no_devices; then
    dialog --msgbox "No hay dispositivos emparejados." 6 $width > /dev/tty1
    return
  fi

  # Menú de selección de dispositivos para eliminar
  while true; do
    delselection=(dialog \
      --backtitle "Dispositivos emparejados:"  \
      --title "MAC  NOMBRE" \
      --no-collapse \
      --clear \
      --cancel-label "Atrás" \
      --menu "" $height $width 15)

    # Mostrar el menú y capturar la selección
    delchoice=$("${delselection[@]}" "${deloptions[@]}" 2>&1 > /dev/tty1) || MainMenu

    # Si el usuario cancela, salir del bucle
    if [[ $? != 0 ]]; then
      exit 1
    fi

    # Llamar a la función para eliminar el dispositivo seleccionado
    DeleteConnect "$delchoice"
  done
}


NetworkInfo() {
  dev=`bluetoothctl list | grep Controller | cut -c 12-45`
  dialog --clear --backtitle "Información del Bluetooth" --title "" --clear \
  --msgbox "\n\nDispositivo: $dev\n" $height $width 2>&1 > /dev/tty1
  if [[ $? != 0 ]]; then
    exit 1
  fi
}

MainMenu() {

  if [[ "$(tr -d '\0' < /proc/device-tree/compatible)" == *"rk3566"* ]]; then
    mainoptions=( 1 "Turn BT $Wifi_MStat (Currently: $Wifi_Stat)" 2 "Connect to new Wifi connection" 3 "Activate existing Wifi Connection" 4 "Delete exiting connections" 5 "Current Network Info" 6 "Change Country Code" 7 "Exit" )
  else
    mainoptions=( 2 "Vincular un dispositivo Bluetooth" 3 "Conectar a dispositivo ya emparejado" 4 "Borrar dispositivo emparejado" 5 "Información del dispositivo" 6 "Salir" )
    
  fi
  IFS="$old_ifs"
  while true; do
    mainselection=(dialog \
   	--backtitle "Bluetooth:" \
   	--title "Menú Principal" \
   	--no-collapse \
   	--clear \
	--cancel-label "Select + Start = Salir" \
    --menu "Elije una opción" $height $width 15)
	
	mainchoices=$("${mainselection[@]}" "${mainoptions[@]}" 2>&1 > /dev/tty1)
	if [[ $? != 0 ]]; then
	  exit 1
	fi
    for mchoice in $mainchoices; do
      case $mchoice in
		1) ToggleWifi $Wifi_MStat ;;
    2) Connect ;;
    3) Activate ;;
		4) Delete ;;
		5) NetworkInfo ;;
		6) ExitMenu ;;
      esac
    done
  done
}

sudo chmod 666 /dev/uinput
export SDL_GAMECONTROLLERCONFIG_FILE="/opt/inttools/gamecontrollerdb.txt"
if [[ ! -z $(pgrep -f gptokeyb) ]]; then
  pgrep -f gptokeyb | sudo xargs kill -9
fi
/opt/inttools/gptokeyb -1 "bt.sh" -c "/opt/inttools/keys.gptk" > /dev/null 2>&1 &
#sudo pkill tm-joypad > /dev/null 2>&1
#sudo /opt/system/Tools/ThemeMaster/tm-joypad Wifi.sh rg552 > /dev/null 2>&1 &
#sudo /opt/wifi/oga_controls Wifi rg552 > /dev/null 2>&1 &
printf "\033c" > /dev/tty1
dialog --clear
trap ExitMenu EXIT
MainMenu