# Utilise une image Python officielle comme base
FROM python:3.11-slim

# Définit le répertoire de travail à l'intérieur du conteneur
WORKDIR /app

# Cree virtual environment dans le container
# RUN python -m venv /app/venv

# Copie le fichier de dépendances dans le conteneur
COPY tools/requirements.txt /app/

# Installe les dépendances Python
RUN pip install --no-cache-dir -r requirements.txt

# Copie le projet Django entier dans le container
COPY . /app/

# Expose le port 8000 pour le serveur de développement Django
EXPOSE 8000
ENV PYTHONPATH="/app"

# Définit la commande de démarrage par défaut (j'ai change parce que le precedent etait difficile a lire pour moi)
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
