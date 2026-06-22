# Dockerfile
# Imagen WordPress para el Caso Practico 2 - DevOps & Cloud - UNIR
#
# Esta imagen se basa en la imagen oficial de WordPress sin modificaciones,
# unicamente reetiquetada para cumplir con el requisito del enunciado de
# que cada imagen se aloje en una carpeta separada del repositorio y
# utilice el tag "casopractico2".
#
# La configuracion concreta de WordPress (URL del sitio, base de datos,
# credenciales) se inyecta en tiempo de despliegue desde Kubernetes
# mediante variables de entorno y volumenes persistentes.

FROM docker.io/library/wordpress:6.4-php8.2-apache

LABEL maintainer="Adrian Simon Rivas"
LABEL project="casopractico2"
LABEL course="devops-cloud-unir"
LABEL version="casopractico2"
LABEL description="WordPress 6.4 con PHP 8.2 sobre Apache para despliegue en AKS"
