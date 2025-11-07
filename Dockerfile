# Utiliser l'image PowerShell officielle basée sur Alpine Linux
FROM mcr.microsoft.com/powershell:latest

# Définir le répertoire de travail
WORKDIR /app

# Copier le script PowerShell dans le conteneur
COPY keep-alex-alive.ps1 ./keep-alex-alive.ps1

# Définir les variables d'environnement
ENV ALEX_URI="https://alex-route-alex-granitechatbot.apps.ocp.heritage.africa/chat"
ENV MESSAGE_1="Quels sont les services d'Accel Tech ?"
ENV MESSAGE_2="Comment puis-je vous aider aujourd'hui ?"
ENV INTERVAL_MINUTES="2"

# Installer curl pour les health checks (optionnel)
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Exposer un port pour les health checks
EXPOSE 8080

# OpenShift gère automatiquement la sécurité des utilisateurs
# Pas besoin de spécifier USER dans OpenShift

# Commande par défaut pour exécuter le script
CMD ["pwsh", "-File", "./keep-alex-alive.ps1"]
