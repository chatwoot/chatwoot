FROM chatwoot/chatwoot:latest
COPY docker/entrypoints/rails.sh docker/entrypoints/rails.sh
RUN chmod +x docker/entrypoints/rails.sh
ENTRYPOINT ["docker/entrypoints/rails.sh"]
CMD bundle exec rails db:chatwoot_prepare ; bundle exec rails db:migrate ; bundle exec sidekiq -C config/sidekiq.yml