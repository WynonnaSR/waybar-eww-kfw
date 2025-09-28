#!/usr/bin/env fish
# Echo chosen MPRIS player using policy:
# If any Playing:
#   - focused if it's Playing
#   - otherwise prefer firefox -> spotify -> vlc -> mpv
# Else:
#   - last (if exists), then focused, then priority, then any.

set -l priority firefox spotify vlc mpv
set -l last_file "$HOME/.cache/eww/last-player"
set -l last ""
test -f "$last_file"; and set last (string trim < "$last_file")

set -l players (playerctl -l 2>/dev/null)
test -n "$players"; or exit 1

# who is playing
set -l playing
for p in $players
  set -l st (playerctl -p $p status 2>/dev/null)
  if test "$st" = "Playing"
    set playing $playing $p
  end
end

# focused class -> candidate
set -l focused_class (hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty' 2>/dev/null)
set -l focused ""
if test -n "$focused_class"
  set -l cls (string lower -- $focused_class)
  switch $cls
    case 'firefox*'; set focused firefox
    case 'spotify*'; set focused spotify
    case 'vlc*';     set focused vlc
    case 'mpv*';     set focused mpv
  end
end

function contains --argument-names needle
  for x in $argv[2..-1]
    if test "$needle" = "$x"
      return 0
    end
  end
  return 1
end

# If there is a playing set
if test -n "$playing"
  if test -n "$focused"; and contains $focused $playing
    echo $focused; exit 0
  end
  for want in $priority
    if contains $want $playing
      echo $want; exit 0
    end
  end
  echo $playing[1]; exit 0
end

# No playing
if test -n "$last"; and contains $last $players
  echo $last; exit 0
end
if test -n "$focused"; and contains $focused $players
  echo $focused; exit 0
end
for want in $priority
  if contains $want $players
    echo $want; exit 0
  end
end

echo $players[1]; exit 0
