#!/usr/bin/env fish
# mediactl: control MPRIS with selection policy, or explicit player
# Usage: mediactl [play-pause|play|pause|next|previous] [playerName?]

set -l cmd "$argv[1]"
set -l explicit "$argv[2]"
test -n "$cmd"; or set cmd play-pause

set -l target ""
if test -n "$explicit"
  set target $explicit
else
  set target (~/.local/bin/select_player.fish)
end

set -l ok 1
if test -n "$target"
  playerctl -p $target $cmd >/dev/null 2>&1; and set ok 0
else
  playerctl -a $cmd >/dev/null 2>&1; and set ok 0
end

# remember last controlled if success
if test $ok -eq 0; and test -n "$target"
  mkdir -p "$HOME/.cache/eww"
  echo -n $target > "$HOME/.cache/eww/last-player"
end

# Be quiet on failure (YouTube outside playlist etc.)
exit 0
