#!/usr/bin/env bash
echo -n $(date  +"%Y-%m-%dT%H:%M:%S%z") \|; ssh fenrir "sqlite3  /home/bernd/attack.db \"SELECT printf(' %,d ', SUM(numbers)), printf(' %,d ', COUNT(*)), printf(' %,d', COUNT(CASE WHEN numbers >= 1000 THEN 1 END)) FROM attacks\""
