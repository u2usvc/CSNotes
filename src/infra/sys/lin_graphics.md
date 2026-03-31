# Linux graphics

## Font

### install nerd fonts

```bash
wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip \
&& cd ~/.local/share/fonts \
&& unzip JetBrainsMono.zip \
&& rm JetBrainsMono.zip \
&& fc-cache -fv
```

## wayland

### Traverse through all displays and set max resolution

```bash
#!/bin/bash

echo "Fetching display outputs and finding maximum resolutions..."

swaymsg -t get_outputs | \
jq -r '.[] | select(.modes != null and (.modes | length) > 0) | .name as $name | (.modes | max_by(.width * .height)) | "\($name) \(.width)x\(.height)"' | \
while read -r name resolution; do

    echo "-----------------------------------"
    echo "Output detected: $name"

    echo "Applying maximum resolution: $resolution"
    swaymsg output "$name" resolution "$resolution"

done

echo "-----------------------------------"
echo "All outputs have been set to their maximum resolutions!"
```

### flameshot alternative for sway

```bash
bindsym Print exec grim -g "$(slurp)" - | swappy -f -
```
