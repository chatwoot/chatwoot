# Dockerfile for the Identity Service

# Use the python-base image from the infra directory
# The build context for this Dockerfile should be the root of the monorepo
# Example build command from root:
# docker build -t identity-service -f services/identity-service/Dockerfile . --build-arg PYTHON_BASE_IMAGE_PATH=infra/docker/python-base.Dockerfile

ARG PYTHON_BASE_IMAGE_PATH=infra/docker/python-base.Dockerfile
FROM --platform=linux/amd64 - as python-base
ADD $PYTHON_BASE_IMAGE_PATH /tmp/python-base.Dockerfile
RUN --mount=type=bind,source=.,target=/workspace \
    docker build -t python-base-image -f /tmp/python-base.Dockerfile /workspace

FROM python-base-image

# Copy the service-specific code
COPY ./services/identity-service /usr/src/app

# Set the working directory
WORKDIR /usr/src/app

# The base image already installed dependencies, so we don't need to do it again.
# The CMD is also inherited from the base image.
CMD ["poetry", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
