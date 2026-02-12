# Applied

## StT

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
