# Utilise une image Python officielle comme base
FROM python:3.11-slim

# Définit le répertoire de travail à l'intérieur du conteneur
WORKDIR /app

# Cree virtual environment dans le container
# RUN python -m venv /app/venv

# Prevents Python from writing pyc files to disk
ENV PYTHONDONTWRITEBYTECODE=1
#Prevents Python from buffering stdout and stderr
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH="/app"

RUN apt-get update
RUN apt-get install netcat-traditional
# Upgrade pip
RUN pip install --upgrade pip 

# Copie le fichier de dépendances dans le conteneur
COPY tools/requirements.txt /app/

# Installe les dépendances Python
RUN pip install --no-cache-dir -r requirements.txt

# copy entrypoint.sh
COPY tools/entrypoint.sh /
RUN chmod +x /entrypoint.sh

# Copie le projet Django entier dans le container
COPY . /app/

# Expose le port 8000 pour le serveur de développement Django
EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]

# Définit la commande de démarrage par défaut (j'ai change parce que le precedent etait difficile a lire pour moi)
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

#Run avec "docker run -p 8000:8000 $nom"
