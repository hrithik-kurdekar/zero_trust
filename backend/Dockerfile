FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
# Wait for the JSON file to exist before starting (simple loop)
CMD ["sh", "-c", "while [ ! -f /app/secrets/mongodb-creds.json ]; do echo Waiting for secrets...; sleep 2; done; uvicorn main:app --host 0.0.0.0 --port 8000"]