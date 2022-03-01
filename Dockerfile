# syntax=docker/dockerfile:1
FROM python:3-slim
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
RUN mkdir code/
COPY requirements.txt /code/
COPY manage.py /code/
COPY example /code/
WORKDIR /code
ENV CRYPTOGRAPHY_DONT_BUILD_RUST=1
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-cryptography \
    python3-django-uwsgi \
    nginx \
    python3-django-allauth 
RUN pip install --trusted-host pypy.org --trusted-host files.pythonhosted.org django-multiselectfield django-bootstrap3
#RUN pip install --trusted-host pypy.org --trusted-host files.pythonhosted.org -r requirements.txt
