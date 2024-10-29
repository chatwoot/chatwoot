FROM chatwoot:development

RUN chmod +x docker/entrypoints/vite.sh

EXPOSE 5173
CMD ["pnpm", "run", "dev"]
