#!/usr/bin/env fish
# Dependencies: curl, jq
# Bar: icon + temperature
# Tooltip: labels aligned; icon followed by NBSP (U+00A0) to keep spacing stable

set -l CITY "Tashkent_Uzbekistan"

# Fetch icon and JSON data
set -l ICON (curl -fsS "https://wttr.in/$CITY?format=%c&lang=en" 2>/dev/null)
set -l JSON (curl -fsS "https://wttr.in/$CITY?format=j1&lang=en" 2>/dev/null)

# Fallbacks
if test -z "$ICON"
  set ICON "?"
end

if test -z "$JSON"
  echo (jq -n --arg text "$ICON" --arg tooltip "Weather: unavailable" '{text:$text, tooltip:$tooltip}')
  exit 0
end

# Build JSON (text = icon + temp, tooltip with NBSP after icon and padded labels)
set -l OUT (echo $JSON | jq -r --arg icon "$ICON" --arg loc_default "$CITY" '
  def fmt(v): if v == null or (v|tostring) == "" then "—" else (v|tostring) end;
  def repeat($s; $n): if $n <= 0 then "" else ($s + repeat($s; $n-1)) end;
  # pad label text (without icon) to fixed width
  def pad($n): . as $s | ($s + repeat(" "; (($n - ($s|length))) ));
  . as $r
  | ($r.nearest_area[0].areaName[0].value // $loc_default) as $loc
  | ($r.current_condition[0]) as $c
  | ($r.weather[0].astronomy[0]) as $a
  | ($c.temp_C // "—") as $tempC
  | {
      text: ($icon + " " + ($tempC|tostring) + "°C"),
      tooltip:
        ([
          " " + "\u00A0" + ("Location"|pad(16))      + $loc,
          " " + "\u00A0" + ("Condition"|pad(16))     + fmt($c.weatherDesc[0].value),
          " " + "\u00A0" + ("Temperature"|pad(16))   + (fmt($c.temp_C) + "°C (Feels " + fmt($c.FeelsLikeC) + "°C)"),
          "󰖝 " + "\u00A0" + ("Wind"|pad(16))          + (fmt($c.winddir16Point) + " " + fmt($c.windspeedKmph) + " km/h" +
                                                       (if ($c.windgustKmph // $c.WindGustKmph) then ", gusts " + (fmt($c.windgustKmph // $c.WindGustKmph)) + " km/h" else "" end)),
          " " + "\u00A0" + ("Humidity"|pad(16))      + (fmt($c.humidity) + "%"),
          " " + "\u00A0" + ("Pressure"|pad(16))      + (fmt($c.pressure) + " hPa"),
          " " + "\u00A0" + ("Precipitation"|pad(16)) + (fmt($c.precipMM) + " mm"),
          " " + "\u00A0" + ("Cloud cover"|pad(16))   + (fmt($c.cloudcover) + "%"),
          " " + "\u00A0" + ("Visibility"|pad(16))    + (fmt($c.visibility) + " km"),
          " " + "\u00A0" + ("Sunrise"|pad(16))       + fmt($a.sunrise),
          "󰖜 " + "\u00A0" + ("Sunset"|pad(16))        + fmt($a.sunset),
          " " + "\u00A0" + ("Moon"|pad(16))          + fmt($a.moon_phase)
        ] | join("\n"))
    }
')

echo $OUT