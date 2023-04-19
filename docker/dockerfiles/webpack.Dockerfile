FROM chatwoot:development


ARG VUE_APP_VERSION
ENV VUE_APP_VERSION ${VUE_APP_VERSION}

RUN chmod +x docker/entrypoints/webpack.sh

EXPOSE 3035
CMD ["bin/webpack-dev-server"]
