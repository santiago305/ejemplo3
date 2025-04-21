# ==========================================
# Fase 1: Construcción del Frontend (React)
# ==========================================
FROM node:20 AS frontend

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY resources/ ./resources/
COPY vite.config.js ./
COPY public ./public
COPY .env ./

RUN npm run build


# ==========================================
# Fase 2: Backend Laravel + PHP + Composer
# ==========================================
FROM php:8.2-fpm AS backend

# Instalar extensiones y herramientas
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libpq-dev zip unzip git curl nginx supervisor \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd zip pdo_pgsql pgsql

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Crear directorio de trabajo
WORKDIR /var/www

# Copiar proyecto Laravel
COPY . .

# Instalar dependencias de PHP
RUN composer install --no-interaction --optimize-autoloader

# Copiar frontend ya compilado por Vite
COPY --from=frontend /app/public/build /var/www/public/build

# Comandos Laravel
RUN php artisan config:cache \
 && php artisan route:cache \
 && php artisan view:cache \
 && php artisan storage:link

# Permisos
RUN chown -R www-data:www-data /var/www \
 && chmod -R 775 storage bootstrap/cache

# Configuración de Nginx y Supervisor
COPY ./docker/nginx.conf /etc/nginx/nginx.conf
COPY ./docker/supervisord.conf /etc/supervisord.conf

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
