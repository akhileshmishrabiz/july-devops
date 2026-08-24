FROM python:3.14-slim

WORKDIR /app

COPY src/requirements.txt .

RUN pip install -r requirements.txt

COPY src/ .

EXPOSE 8000

RUN chmod +x run.sh

CMD ["./run.sh"]
