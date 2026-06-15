FROM python:3.12-slim

WORKDIR /app

# Faster, reproducible installs via uv.
RUN pip install --no-cache-dir uv

# Copy the package before install so the wheel build (hatchling) can find `app`,
# which includes the admin-panel Jinja templates under app/admin/templates.
COPY pyproject.toml ./
COPY app ./app
RUN uv pip install --system --no-cache .

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=5 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:8080/health').status==200 else 1)"
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
