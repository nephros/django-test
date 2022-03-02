# syntax=docker/dockerfile:1
#FROM python:3.7-slim-buster
FROM debian:bullseye-slim
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
RUN mkdir app/
COPY requirements.txt /app/
COPY manage.py /app/
COPY example /app/
COPY config/nginx/localhost.crt /app/keys/
COPY config/nginx/localhost.key /app/keys/
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    uwsgi \ 
    uwsgi-plugin-python3 \
    python3-pip \
    python3-setuptools \
    python3-cryptography \
    python3-django-allauth \
    python3-django-uwsgi \
    python3-oauthlib \
    python3-openid \
    python3-sqlparse \
    python3-tz


## newer base images may require these:

#ENV PYTHONPATH=$PYTHONPATH:/usr/local/lib/python3.7/dist-packages:/usr/local/lib/python3.7/site-packages
# manually install requirements, use django less than four
#RUN pip install --trusted-host pypy.org --trusted-host files.pythonhosted.org django-multiselectfield django-bootstrap3
# do not rebuild cryptography, as that needs rust etc.
#RUN pip install --trusted-host pypy.org --trusted-host files.pythonhosted.org --no-compile --only-binary :all: cryptography
# this is the cause for cryptography dep, anything higher than 0.43 will have to rebuild cryptography:
#RUN pip install --no-cache-dir --trusted-host pypy.org --trusted-host files.pythonhosted.org "django<4" "django-allauth<0.43"
#RUN pip install --no-cache-dir --trusted-host pypy.org --trusted-host files.pythonhosted.org -r requirements.txt
#ENV PYTHONPATH=$PYTHONPATH:/usr/local/lib/python3.7:/usr/local/lib/python3.7/dist-packages:/usr/local/lib/python3.7/site-packages

RUN pip3 install --no-cache-dir --trusted-host pypy.org --trusted-host files.pythonhosted.org -r requirements.txt
COPY . .

RUN apt autoremove
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

RUN chown -R www-data:www-data /app
USER www-data:www-data
RUN python3 manage.py check
RUN python3 manage.py makemigrations
RUN python3 manage.py migrate
EXPOSE 4000
EXPOSE 4080
EXPOSE 4443

ENTRYPOINT ["uwsgi"]
#    "--daemonize2", "/dev/null", \
CMD [ "--master", \
    "--processes", "1", \
    "--uwsgi-socket", ":4000", \
    "--http-socket",  ":4080", \
    "--https-socket", ":4443,/app/keys/localhost.crt,/app/keys/localhost.key", \
    "--plugins", "python3", \
    "--chdir", "/app" , \
    "--wsgi-file", "example/wsgi.py" ]

