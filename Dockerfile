# syntax=docker/dockerfile:1
FROM python:3.9-slim
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
    python3-minimal \
    python3-cryptography \
    python3-tz \
    python3-sqlparse \
    python3-django-allauth \
    python3-django-timezone-field \
    python3-django-uwsgi \
    python3-django
#    nginx \

# manually install requirements, use django less than four
RUN pip install --trusted-host pypy.org --trusted-host files.pythonhosted.org "Django<4" django-multiselectfield django-bootstrap3
# do not rebuild cryptography, as that needs rust etc.
RUN pip install --trusted-host pypy.org --trusted-host files.pythonhosted.org --no-compile --only-binary :all: cryptography
# this is the cause for cryptography dep, anything higher than 0.43 will have to rebuild cryptography:
RUN pip install --trusted-host pypy.org --trusted-host files.pythonhosted.org "django-allauth<0.43"
RUN pip install --trusted-host pypy.org --trusted-host files.pythonhosted.org -r requirements.txt
COPY . .
ENV PYTHONPATH=/usr/lib/python3.9:/usr/local/lib/python3.9:/usr/local/lib/python3.9/dist-packages::/usr/local/lib/python3.9/site-packages

RUN chown -R www-data:www-data /app
USER www-data:www-data
#RUN ./manage.py check
#RUN python3 manage.py test
RUN python3 manage.py makemigrations
RUN python3 manage.py migrate
EXPOSE 4000
EXPOSE 4080
EXPOSE 4443

ENTRYPOINT ["uwsgi"]
CMD [ "--master", \
    "--processes", "1", \
    "--uwsgi-socket", "0.0.0.0:4000", \
    "--http-socket", "0.0.0.0:4080", \
    "--https-socket", "0.0.0.0:4443,/app/keys/localhost.crt,/app/keys/localhost.key", \
    "--plugins", "python3", \
    "--chdir", "/app" , \
    "--wsgi-file", "example/wsgi.py" ]

