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

### flameshot alternative for sway

```bash
bindsym Print exec grim -g "$(slurp)" - | swappy -f -
```
