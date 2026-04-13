# Applied

## StT

### nerd-dictation

#### Setup on wayland

<https://github.com/ideasman42/nerd-dictation/blob/main/readme-ydotool.rst>

ydotoold

```bash
cd ~/utils
git clone https://github.com/ReimuNotMoe/ydotool.git
cd ydotool
mkdir build
cd build
cmake ..
make -j `nproc`

cp ./ydotool /usr/local/bin
cp ./ydotoold /usr/local/bin
sudo cp ./ydotoold.service /etc/systemd/system/

echo 'KERNEL=="uinput", GROUP="users", MODE="0660", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/80-uinput.rules > /dev/null

sudo usermod -aG input $USER

cat /etc/systemd/system/ydotoold.service
# [Service]
# ExecStart=
# ExecStart=/usr/local/bin/ydotoold --socket-path="/run/user/1215401105/.ydotool_socket" --socket-perm="0666"

udo systemctl daemon-reload
sudo systemctl enable --now ydotoold
sudo reboot
```

nerd-dictation

```bash
cd ~/utils
git clone https://github.com/ideasman42/nerd-dictation.git
python3 -m venv ./
. ./bin/activate
pip3 install vosk
cd nerd-dictation
wget https://alphacephei.com/kaldi/models/vosk-model-small-en-us-0.15.zip
unzip vosk-model-small-en-us-0.15.zip
mv vosk-model-small-en-us-0.15 model

nvim nd-start.sh
# #!/bin/sh
# DIR="$(dirname "$0")"
# export XDG_RUNTIME_DIR="/run/user/$(id -u)"
# "$DIR/bin/python" "$DIR/nerd-dictation" begin --vosk-model-dir="$DIR/model" --simulate-input-tool=YDOTOOL

nvim nd-stop.sh
# #!/bin/sh
# DIR="$(dirname "$0")"
# "$DIR/bin/python" "$DIR/nerd-dictation" end

chmod +x ~/utils/nerd-dictation/nd-start.sh ~/utils/nerd-dictation/nd-stop.sh

nvim ~/.config/sway/config
# bindsym $mod+F9 exec /home/$USER/utils/nerd-dictation/nd-start.sh
# bindsym $mod+F10 exec /home/$USER/utils/nerd-dictation/nd-stop.sh
```

### whisper

#### Usage

```bash
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp
cmake -B build
cmake --build build -j --config Release
```

Transcribe:

```bash
arecord -r 16000 -c 1 -f S16_LE /tmp/input.wav || true
ffmpeg -y -i /tmp/input.wav -ar 16000 -ac 1 -c:a pcm_s16le /tmp/output.wav > /dev/null 2>&1
~/utils/whisper.cpp/build/bin/whisper-cli -m ~/utils/whisper.cpp/models/ggml-base.en.bin -f /tmp/output.wav
```
