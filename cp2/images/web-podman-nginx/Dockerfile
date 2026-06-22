# Dockerfile
# Imagen Nginx para Caso Practico 2 - DevOps & Cloud - UNIR
# Construye una imagen autocontenida con:
#  - Nginx
#  - Contenido HTML
#  - Certificado x.509 autofirmado (generado en build-time)
#  - Credenciales htpasswd (admin / casopractico2)

FROM docker.io/library/nginx:1.27-alpine

LABEL maintainer="Adrian Simon Rivas"
LABEL project="casopractico2"
LABEL course="devops-cloud-unir"

# Herramientas necesarias durante el build
RUN apk add --no-cache openssl apache2-utils

# Generar certificado x.509 autofirmado (validez 365 dias)
# Subject Alternative Name (SAN) configurado para evitar warnings de SAN missing
RUN mkdir -p /etc/nginx/certs && \
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/certs/server.key \
        -out /etc/nginx/certs/server.crt \
        -subj "/C=ES/ST=La-Rioja/L=Logrono/O=UNIR/OU=DevOpsCloud/CN=cp2-podman-nginx" \
        -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

# Generar fichero htpasswd con usuario admin / contrasena casopractico2
# El flag -B usa bcrypt (mas seguro que el por defecto)
RUN htpasswd -Bbn admin casopractico2 > /etc/nginx/.htpasswd

# Copiar configuracion personalizada de nginx y contenido HTML
COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /usr/share/nginx/html/index.html

# Permisos correctos
RUN chmod 644 /etc/nginx/.htpasswd /etc/nginx/certs/server.crt && \
    chmod 600 /etc/nginx/certs/server.key

# Limpieza para reducir tamano de la imagen
RUN apk del apache2-utils && \
    rm -rf /var/cache/apk/*

EXPOSE 80 443

# Nginx en foreground para que Podman/systemd lo gestione
CMD ["nginx", "-g", "daemon off;"]