FROM chatwoot:test

RUN chmod +x docker/entrypoints/rspec.sh

EXPOSE 3000
CMD ["rspec"]