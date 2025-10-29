FROM flutter/flutter:latest

WORKDIR /app

COPY ./mobile /app

RUN flutter pub get

CMD ["flutter", "run", "--release", "--web-port=5000"]