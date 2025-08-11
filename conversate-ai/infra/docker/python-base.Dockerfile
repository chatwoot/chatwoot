# Base Dockerfile for Python services in Conversate AI

# Use the official Python image
FROM python:3.11-slim

# Set the working directory
WORKDIR /usr/src/app

# Install poetry for dependency management
RUN pip install poetry

# Copy only the dependency files to leverage Docker cache
COPY ./pyproject.toml ./poetry.lock* /usr/src/app/

# Install dependencies
RUN poetry config virtualenvs.create false && \
    poetry install --no-root --no-dev

# Copy the rest of the application
COPY . /usr/src/app

# Expose the port the app runs on
EXPOSE 8000

# Command to run the application
CMD ["poetry", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
