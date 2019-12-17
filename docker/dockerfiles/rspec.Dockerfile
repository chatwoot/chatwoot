FROM chatwoot:test

RUN chmod +x docker/entrypoints/webpack.sh

CMD ["rspec"]