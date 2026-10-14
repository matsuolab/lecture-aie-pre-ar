# --- مرحلة البناء ---
FROM python:3.12-slim AS builder

WORKDIR /app

# إنشاء بيئة افتراضية
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
# التنفيذ بالتتابع باستخدام &&
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt


# --- مرحلة التشغيل ---
FROM python:3.12-slim AS runner
WORKDIR /app

# نسخ البيئة الافتراضية بالكامل من مرحلة البناء
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# وضع شيفرة التطبيق في موضعها
COPY . /app/

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]