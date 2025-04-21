# Fase 1: Build del frontend
FROM node:20 AS frontend

WORKDIR /app

COPY ./frontend/package*.json ./
RUN npm install

COPY ./frontend ./
RUN npm run build

# Fase 2: Backend Laravel
FROM php:8.2-fpm AS backend

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    git \
    unzip \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd zip pdo pdo_mysql

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copiar todo el proyecto Laravel
COPY . .

# Instalar dependencias de PHP
RUN composer install --no-interaction --optimize-autoloader

# Si usas Vite y ya configuraste el build en public/build, este paso NO es necesario:
# COPY --from=frontend /app/dist /var/www/public/build

# Comandos artisan (excepto migrate)
# RUN php artisan key:generate
RUN php artisan optimize
RUN php artisan config:cache
RUN php artisan route:cache
RUN php artisan view:cache
RUN php artisan storage:link

# Permisos
RUN chown -R www-data:www-data /var/www
RUN chmod -R 775 storage bootstrap/cache

EXPOSE 80
CMD ["php-fpm"]
# FROM nginx:stable-alpine

# # Copiar configuración personalizada de nginx
# COPY ./nginx.conf /etc/nginx/nginx.conf

# # Copiar el código desde backend
# COPY --from=backend /var/www /var/www

# # Copiar el socket PHP-FPM desde la fase backend
# COPY --from=backend /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf
# COPY --from=backend /usr/local/sbin/php-fpm /usr/local/sbin/php-fpm

# # Exponer puerto HTTP
# EXPOSE 80

# # Comando por defecto
# CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]
