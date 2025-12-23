FROM ruby:3.2.2-slim-bullseye

ENV TZ="Europe/London"

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y install --no-install-recommends \
  apt-utils \
  build-essential \
  curl \
  git \
  vim \
  zsh

RUN gem install bundler

WORKDIR /workspace
