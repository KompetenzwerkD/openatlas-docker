#!/bin/sh
/etc/init.d/postgresql restart
python3 ./runapp.py
#gunicorn -w 4 runserver:app