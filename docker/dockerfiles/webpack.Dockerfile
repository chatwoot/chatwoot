FROM chatwoot:development

RUN chmod +x docker/entrypoints/vite.sh

EXPOSE 3035
CMD ["bin/vite"]
