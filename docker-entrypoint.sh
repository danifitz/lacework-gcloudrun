#!/bin/sh

## LW Agent (4) running the agent
/var/lib/lacework/datacollector &

python app.py