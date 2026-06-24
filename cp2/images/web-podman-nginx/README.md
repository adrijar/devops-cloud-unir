# Imagen Nginx para Podman

Imagen de contenedor que ejecuta el servidor web **Nginx** con HTTPS
(certificado autofirmado) y autenticacion basica.

Construida para ejecutarse sobre la maquina virtual Linux del Caso Practico 2
con el motor de contenedores **Podman**, gestionada como servicio de systemd.

## Caracteristicas

- Base: `nginx:1.27-alpine` (~57 MB)
- Servidor HTTPS en puerto 443
- Redireccion HTTP (80) -> HTTPS (443)
- Certificado x.509 autofirmado generado en build-time
- Autenticacion basica con bcrypt
- Contenido HTML del proyecto incluido

## Credenciales

- Usuario: `admin`
- Contrasena: `casopractico2`

> Nota: estas credenciales se generan dentro de la imagen para cumplir
> el requisito del enunciado de "imagen autocontenida". En un entorno
> de produccion deberian generarse aleatoriamente y gestionarse
> mediante un gestor de secretos.

## Construir localmente

```bash
podman build -t web-podman-nginx:casopractico2 .
```

## Probar localmente

```bash
podman run -d -p 8443:443 --name nginx-test web-podman-nginx:casopractico2
curl -k https://localhost:8443 -u admin:casopractico2
```

## Publicar en ACR

```bash
podman tag web-podman-nginx:casopractico2 <acr>.azurecr.io/web-podman-nginx:casopractico2
podman push <acr>.azurecr.io/web-podman-nginx:casopractico2
```