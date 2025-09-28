#!/usr/bin/env fish
# Emit JSON once per call: full state for Eww UI
# {name,title,artist,status,position,positionStr,length,lengthStr,canNext,canPrev,thumbnail}

set -l base_dir "$HOME/.config/eww"
set -l image_file "$base_dir/image.jpg"
mkdir -p "$base_dir"

function fmt_time --argument-names s
  set -l secs (math -s0 "floor($s)")
  set -l mins (math -s0 "$secs / 60")
  set -l rems (math -s0 "$secs % 60")
  printf "%d:%02d" $mins $rems
end

set -l name (~/.local/bin/select_player.fish)

set -l title ""; set -l artist ""; set -l status ""; set -l pos 0; set -l len 0; set -l canN 0; set -l canP 0

if test -n "$name"
  # metadata via playerctl
  set -l t (playerctl -p $name metadata title 2>/dev/null)
  set -l a (playerctl -p $name metadata artist 2>/dev/null)
  set -l st (playerctl -p $name status 2>/dev/null)
  test -n "$t"; and set title "$t"
  test -n "$a"; and set artist "$a"
  test -n "$st"; and set status "$st"

  # duration (us -> s)
  set -l len_us (playerctl -p $name metadata mpris:length 2>/dev/null)
  if test -n "$len_us"; and string match -rq '^[0-9]+$' -- "$len_us"
    set len (math -s2 "$len_us / 1000000")
  end

  # position (s)
  set -l p (playerctl -p $name position 2>/dev/null)
  if string match -rq '^[0-9]+(\\.[0-9]+)?$' -- "$p"
    set pos $p
  end

  # capabilities via busctl (user session)
  set -l vN (busctl --user get-property org.mpris.MediaPlayer2.$name /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player CanGoNext 2>/dev/null)
  set -l vP (busctl --user get-property org.mpris.MediaPlayer2.$name /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player CanGoPrevious 2>/dev/null)
  string match -rq 'b true' -- "$vN"; and set canN 1
  string match -rq 'b true' -- "$vP"; and set canP 1

  # cover-art (file:// or http(s))
  set -l art (playerctl -p $name metadata mpris:artUrl 2>/dev/null)
  if string match -rq '^file://.*' -- "$art"
    set -l local_path (string replace -r '^file://' '' -- "$art")
    if test -f "$local_path"
      cp "$local_path" "$image_file"
    else
      cp "$base_dir/scripts/cover.png" "$image_file"
    end
  else if string match -rq '^https?://.*' -- "$art"
    curl -Ls --max-time 5 "$art" -o "$image_file" 2>/dev/null
    if test $status -ne 0
      cp "$base_dir/scripts/cover.png" "$image_file"
    end
  else
    cp "$base_dir/scripts/cover.png" "$image_file"
  end
else
  # no player -> default cover
  cp "$base_dir/scripts/cover.png" "$image_file"
end

set -l posStr (fmt_time $pos)
set -l lenStr (fmt_time $len)
jq -n -c \
  --arg name "$name" \
  --arg title "$title" \
  --arg artist "$artist" \
  --arg status "$status" \
  --argjson position "$pos" \
  --arg positionStr "$posStr" \
  --argjson length "$len" \
  --arg lengthStr "$lenStr" \
  --arg thumbnail "$image_file" \
  --argjson canNext "$canN" \
  --argjson canPrev "$canP" \
  '{name:$name,title:$title,artist:$artist,status:$status,position:$position,positionStr:$positionStr,length:$length,lengthStr:$lengthStr,thumbnail:$thumbnail,canNext:$canNext,canPrev:$canPrev}'
