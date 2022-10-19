FROM python:3.8

ENV PYTHONUNBUFFERED=1
# prevents python creating .pyc files
ENV PYTHONDONTWRITEBYTECODE=1
# pip
ENV PIP_NO_CACHE_DIR=off
ENV PIP_DISABLE_PIP_VERSION_CHECK=on
ENV PIP_DEFAULT_TIMEOUT=100
# poetry
# https://python-poetry.org/docs/configuration/#using-environment-variables

WORKDIR $SETUP_PATH

RUN pip install tensorflow
RUN pip install rasa

EXPOSE 5005


RUN rasa init --no-prompt

CMD rasa run -m models --enable-api --log-file out.log
