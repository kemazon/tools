#!/bin/bash
# Reproducir todos los videos en /roms2/movies/ y subcarpetas usando MPV

CARPETA="/roms2/movies"

# Buscar todos los archivos de video (recursivo e insensible a mayúsculas)
VIDEOS=$(find "$CARPETA" -type f \( \
  -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" -o \
  -iname "*.wmv" -o -iname "*.flv" -o -iname "*.webm" -o -iname "*.m4v" \) | sort)

# Verificar si se encontraron videos
if [ -z "$VIDEOS" ]; then
  echo "No se encontraron archivos de video en $CARPETA ni en sus subcarpetas."
  exit 1
fi

# Mostrar cantidad de videos encontrados
COUNT=$(echo "$VIDEOS" | wc -l)
echo "Se encontraron $COUNT videos. Iniciando reproducción con MPV..."

# Reproducir todos los videos
mpv --shuffle --loop-playlist=inf --fs $VIDEOS