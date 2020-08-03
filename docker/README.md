# elcora oracle docker

## clone repository

```bash
➜ git clone git@github.com:aarlt/elcaro.git
➜ cd elcaro
➜ git submodule update --init
```

## build docker

```bash
➜  cd elcaro/docker
➜  docker build .
Sending build context to Docker daemon   35.1MB
Step 1/40 : FROM golang:1.14.2-buster
...
Successfully built fd8a7e1f2cc1
```
Here `fd8a7e1f2cc1` is the `${IMAGE_ID}`.

## start daemon

```bash
➜ docker run -d --name elcaro-node \
  -v /tmp/ipfs-docker-staging:/export -v /tmp/ipfs-docker-data:/data/ipfs \
  -p 8081:8080 -p 4002:4001 -p 127.0.0.1:5002:5001 ${IMAGE_ID}
81c33bfed10e23870b2d1bb8f9bb05c8fb51c0e02ceec27e4d36079461f7a36b
➜ CID=81c33bfed10e23870b2d1bb8f9bb05c8fb51c0e02ceec27e4d36079461f7a36b
```
Here `81c33bfed10e23870b2d1bb8f9bb05c8fb51c0e02ceec27e4d36079461f7a36b` is `${CID}`.

## ipfs interaction

```bash
docker exec $CID ipfs cat QmZrPf6xunDiwsdbPS33oxiPQoTeztmP6KkWfFPjBjdWH7
```

## stop container

```bash
➜ docker stop elcaro-node
➜ docker rm elcaro-node
```

