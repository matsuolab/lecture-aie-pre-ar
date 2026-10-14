# --- مرحلة البناء ---
FROM node:22-slim AS builder

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .
RUN npm run build

# --- مرحلة التشغيل ---
# تقديم الملفات الثابتة المبنية باستخدام صورة nginx خفيفة
FROM nginx:alpine AS runner

# وضع ناتج بناء vite فقط (dist) في مجلد الملفات التي يقدمها nginx
COPY --from=builder /app/dist /usr/share/nginx/html

# إعداد الوكيل العكسي لتمرير /app/api إلى حاوية backend
COPY nginx.conf /etc/nginx/conf.d/default.conf

# الاستماع على المنفذ 80 (الإعداد الافتراضي لصورة nginx)
EXPOSE 80
