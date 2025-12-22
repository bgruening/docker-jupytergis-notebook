#!/bin/bash

echo "Starting Ollama server..."
nohup ollama serve > /import/ollama.log 2>&1 &
echo "Ollama server running in background (log: /import/ollama.log)"
# Wait 5s to let it initialize
sleep 5

