FROM chatwoot/chatwoot:latest
RUN chmod +x docker/entrypoints/rails.sh

ENTRYPOINT ["docker/entrypoints/rails.sh"]
CMD bundle exec bundle exec rails s -b 0.0.0.0 -p 3000