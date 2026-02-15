# Obfuscation

## OLLVM

### Build

```Dockerfile
FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    cmake \
    python \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src
RUN git clone -b llvm-4.0 https://github.com/obfuscator-llvm/obfuscator.git

WORKDIR /usr/src/build

RUN cmake -DCMAKE_BUILD_TYPE=Release -DLLVM_INCLUDE_TESTS=OFF ../obfuscator/

RUN make -j$(nproc)

RUN ./bin/clang --version

CMD ["/bin/bash"]
```

```bash
sudo docker build -t obfuscator-llvm .
sudo docker cp $CONTAINER_ID:/usr/src/build/bin ~/utils/ollvm/
```
