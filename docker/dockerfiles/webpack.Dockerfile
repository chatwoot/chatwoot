FROM chatwoot:development

RUN chmod +x docker/entrypoints/webpack.sh

RUN npm install webpack-dev-server -g

EXPOSE 3035
CMD ["bin/webpack-dev-server"]