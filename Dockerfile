FROM python:3.11-slim

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

ENV FLASK_APP=app.py
ENV FLASK_ENV=production
ENV REDIS_HOST=redis
ENV REDIS_PORT=6379

EXPOSE 5001

CMD ["gunicorn", "--bind", "0.0.0.0:5001", "--workers", "4", "app:app"]
