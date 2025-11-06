# Utiliser l'image PowerShell officielle basée sur Alpine Linux
FROM mcr.microsoft.com/powershell:latest

# Définir le répertoire de travail
WORKDIR /app

# Copier le script PowerShell dans le conteneur
COPY keep-ollama-alive-container.ps1 ./keep-ollama-alive-container.ps1

# Définir les variables d'environnement
ENV OLLAMA_URI="https://ollamaaccel-chatbotaccel.apps.senum.heritage.africa/api/generate"
ENV MODEL_NAME="granite-code:3b"
ENV INTERVAL_MINUTES="2"
ENV PROMPT="Bonjour"

# Installer curl pour les health checks (optionnel)
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Exposer un port pour les health checks
EXPOSE 8080

# Définir l'utilisateur non-root pour la sécurité
USER 1001

# Commande par défaut pour exécuter le script
CMD ["pwsh", "-File", "./keep-ollama-alive-container.ps1"]
