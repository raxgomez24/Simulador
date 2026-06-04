#!/bin/bash
# Script para iniciar el servidor WebSocket

echo "Iniciando servidor WebSocket..."
echo "El servidor se ejecutará en ws://localhost:8080"
echo ""
echo "Presiona Ctrl+C para detener el servidor"
echo ""

dart bin/server.dart
