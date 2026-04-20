FROM mcr.microsoft.com/devcontainers/python:1-3.11-bookworm

RUN rm -f /etc/apt/sources.list.d/yarn.list

RUN apt-get update && apt-get install -y default-jdk-headless

RUN pip install pyspark==3.5.1 trino pandas jupyterlab

ENV JAVA_HOME=/usr/lib/jvm/default-java