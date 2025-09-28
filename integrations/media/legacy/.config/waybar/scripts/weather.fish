#!/usr/bin/env fish
set -l CITY "Tashkent_Uzbekistan"
set -l FORMAT "%c+%t"
curl -s "wttr.in/$CITY?format=$FORMAT"
