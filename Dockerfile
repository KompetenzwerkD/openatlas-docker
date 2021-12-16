FROM debian:latest

RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

RUN apt update && apt install -y python3 python3-bcrypt python3-dateutil python3-psycopg2 \
    python3-fuzzywuzzy python3-flask python3-flask-babel \
    python3-flask-login python3-flaskext.wtf python3-markdown \
    python3-numpy python3-pandas python3-jinja2 python3-flask-cors \
    python3-flask-restful p7zip-full python3-wand \
    apache2 libapache2-mod-wsgi-py3 \
    postgresql \
    postgresql-13-postgis-3 postgresql-13-postgis-3-scripts \
    gettext npm python3-pip \
    git

WORKDIR /var/www/

RUN git clone https://github.com/craws/OpenAtlas.git && \
    pip3 install calmjs && \
    cd OpenAtlas/openatlas/static && \
    pip3 install -e ./ && \
    pip3 install rdflib gunicorn && \
    /usr/local/bin/calmjs npm --install openatlas && \
    echo "listen_addresses = '*'" >> /etc/postgresql/13/main/postgresql.conf 
    

RUN pg_ctlcluster 13 main start

WORKDIR /var/www/OpenAtlas/install/

USER postgres

RUN  /etc/init.d/postgresql restart && \
    psql --command "CREATE USER openatlas WITH SUPERUSER PASSWORD 'CHANGE ME';" && \
    createdb openatlas -O openatlas && \
    psql openatlas -c "CREATE EXTENSION postgis; CREATE EXTENSION unaccent;" && \
    cat 1_structure.sql 2_data_model.sql 3_data_web.sql 4_data_node.sql | psql -d openatlas -f -

USER root

RUN cp /var/www/OpenAtlas/instance/example_production.py /var/www/OpenAtlas/instance/production.py
WORKDIR /var/www/OpenAtlas

COPY ./runapp.py .
COPY ./run.sh .
RUN chmod 755 ./run.sh

ENTRYPOINT [ "./run.sh" ]