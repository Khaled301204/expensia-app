# ── Stage 1: Build Flutter web ─────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Restore dependencies first (cache layer)
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# API_BASE_URL is injected at build time via --build-arg
ARG API_BASE_URL=http://localhost:8080/api

RUN flutter build web --release \
      --dart-define=API_BASE_URL=$API_BASE_URL

# ── Stage 2: Serve with nginx ──────────────────────────────────────────────────
FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
