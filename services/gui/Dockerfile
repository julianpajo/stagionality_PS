FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt requirements.txt

RUN pip install -r requirements.txt
RUN apt-get update && apt-get install -y curl

COPY . .

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:5000 || exit 1

CMD ["python", "src/app.py"]
