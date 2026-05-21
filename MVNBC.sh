#!/bin/bash
# Copyright (c) 2026, Darkveda All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

BASE_DIR="backups"
TEMPLATE_DIR="templates"

clear

echo "======================================"
echo " Multi-Vendor Backup configuration"
echo "======================================"
echo ""

echo "1. Cisco"
echo "2. Arista"
echo "3. Mikrotik"
echo "4. H3c"
echo ""

read -p "Please choose vendor: " CHOICE

case "$CHOICE" in
    1) VENDOR="cisco" ;;
    2) VENDOR="arista" ;;
    3) VENDOR="mikrotik" ;;
    4) VENDOR="h3c" ;;
    *)
        echo "❌ Invalid selection"
        exit 1
        ;;
esac

echo ""
read -p "Enter username: " USER
read -s -p "Enter password: " PASS
echo ""

ENABLE=""

if [[ "$VENDOR" == "cisco" || "$VENDOR" == "arista" ]]; then
    read -s -p "Enter enable password: " ENABLE
    echo ""
fi

echo ""
read -p "Enter IP (multiple IPs comma-separated): " IPS

mkdir -p "$BASE_DIR/$VENDOR"

IFS=',' read -ra IP_ARRAY <<< "$IPS"

for IP in "${IP_ARRAY[@]}"; do

    IP=$(echo "$IP" | xargs)

    DATE=$(date +%Y%m%d_%H%M%S)
    FILE="$BASE_DIR/$VENDOR/${IP}_${DATE}.log"

    echo ""
    echo "======================================"
    echo "Backing up $VENDOR : $IP"
    echo "======================================"

    START=$(date +%s)

    expect "$TEMPLATE_DIR/${VENDOR}.exp" \
        "$IP" "$USER" "$PASS" "$ENABLE" \
        > "$FILE" 2>&1

    STATUS=$?

    END=$(date +%s)
    RUNTIME=$((END - START))

    if [ $STATUS -eq 0 ]; then
        SIZE=$(du -h "$FILE" | awk '{print $1}')
        echo "✅ SUCCESS: $IP | ${RUNTIME}s | $SIZE"
    else
        echo "❌ FAILED: $IP"
        [ -s "$FILE" ] || rm -f "$FILE"
    fi

done

find "$BASE_DIR" -type f -name "*.log" -mtime +90 -exec rm -f {} \;

echo ""
echo "Backup Completed"
