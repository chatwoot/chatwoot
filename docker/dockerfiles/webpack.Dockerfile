FROM chatwoot/chatwoot:develop

RUN chmod +x docker/entrypoints/webpack.sh

COPY . /app

EXPOSE 3035
CMD ["bin/webpack-dev-server"]