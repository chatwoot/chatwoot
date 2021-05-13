FROM chatwoot/chatwoot:develop

RUN chmod +x docker/entrypoints/rails.sh

COPY . /app

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]