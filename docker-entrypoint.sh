#!/bin/sh

# Lacework Agent: configure and start the data collector
chmod +x /var/lib/lacework-backup/6.3.0.10639/datacollector 
/var/lib/lacework-backup/6.3.0.10639/datacollector &

python app.py
