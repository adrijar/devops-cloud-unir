# Imagen WordPress para AKS

Imagen de contenedor que ejecuta **WordPress 6.4** sobre Apache con PHP 8.2,
preparada para desplegarse en el cluster Azure Kubernetes Service (AKS) del
Caso Practico 2.

## Caracteristicas

- Base: `docker.io/library/wordpress:6.4-php8.2-apache`
- Apache HTTP server en puerto 80
- PHP 8.2 con extensiones requeridas por WordPress
- Configuracion inyectada por Kubernetes via variables de entorno y volumen persistente

## Configuracion en tiempo de despliegue

La imagen no incluye ninguna configuracion preestablecida. Cuando se despliega
en AKS, el manifiesto de Kubernetes proporciona:

- `WORDPRESS_DB_HOST`: host de MySQL (servicio interno del cluster).
- `WORDPRESS_DB_USER`: usuario de la base de datos.
- `WORDPRESS_DB_PASSWORD`: contrasena (montada desde Secret).
- `WORDPRESS_DB_NAME`: nombre de la base de datos.
- `PersistentVolumeClaim`: montado en `/var/www/html` para persistir contenidos.

## Construir localmente

```bash
podman build -t web-aks-wordpress:casopractico2 .
```

## Probar localmente (requiere MySQL)

Para una prueba rapida sin MySQL real, se puede levantar con SQLite mediante
un plugin, o simplemente desplegar directamente en AKS donde se cuenta con
el StatefulSet de MySQL.

## Publicar en ACR

```bash
podman tag web-aks-wordpress:casopractico2 <acr>.azurecr.io/web-aks-wordpress:casopractico2
podman push <acr>.azurecr.io/web-aks-wordpress:casopractico2
```
