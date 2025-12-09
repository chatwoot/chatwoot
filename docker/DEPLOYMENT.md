# Guia de Deployment de BlazeChat

Esta guia explica como desplegar BlazeChat en produccion usando Docker.

## Requisitos Previos

- Docker y Docker Compose instalados
- Minimo 4GB de RAM
- Dominio configurado (opcional pero recomendado)

## Pasos de Instalacion

### 1. Clonar el Repositorio

```bash
git clone https://github.com/blazesphere/blazechat.git
cd blazechat
```

### 2. Configurar Variables de Entorno

```bash
cp docker/.env.production.example .env
```

Edita el archivo `.env` y configura:

- `SECRET_KEY_BASE`: Genera con `openssl rand -hex 64`
- `FRONTEND_URL`: URL publica de tu instalacion
- `POSTGRES_PASSWORD`: Contrasena segura para PostgreSQL
- `REDIS_PASSWORD`: Contrasena segura para Redis
- Configuracion SMTP para emails

### 3. Iniciar los Servicios

```bash
docker-compose -f docker-compose.production.yaml up -d
```

### 4. Preparar la Base de Datos

```bash
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails db:chatwoot_prepare
```

### 5. Crear Usuario Super Admin

```bash
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails db:seed
```

## Comandos Utiles

### Ver logs
```bash
docker-compose -f docker-compose.production.yaml logs -f
```

### Reiniciar servicios
```bash
docker-compose -f docker-compose.production.yaml restart
```

### Detener servicios
```bash
docker-compose -f docker-compose.production.yaml down
```

### Actualizar a nueva version
```bash
docker-compose -f docker-compose.production.yaml pull
docker-compose -f docker-compose.production.yaml up -d
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails db:migrate
```

## Configuracion de Proxy Inverso (Nginx)

Ejemplo de configuracion para Nginx:

```nginx
server {
    listen 80;
    server_name tu-dominio.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name tu-dominio.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Registries de Docker

### Registry Privado (BlazeSphere)
```bash
docker pull registry.blaze.do/blazechat:latest
```

### Docker Hub
```bash
docker pull papalocord/blazechat-v1:latest
```

## Soporte

Para soporte tecnico, contacta a BlazeSphere:
- Web: https://www.blazesphere.com
- Email: soporte@blazesphere.com
