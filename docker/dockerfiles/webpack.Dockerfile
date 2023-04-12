FROM chatwoot:development

RUN chmod +x docker/entrypoints/webpack.sh

EXPOSE 3035
ENV VUE_APP_VERSION="test_webpack_dockerfile"
ENV VUE_APP_SENTRY_DSN_CHAT="https://02b9c03c61e642228cd22016b7ce452d@o59321.ingest.sentry.io/4504889702023168"

CMD ["bin/webpack-dev-server"]