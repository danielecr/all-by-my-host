FROM alpine:latest as builder

RUN apk add --update gcc make alpine-sdk

COPY src/msgpassing.c msgpassing.c

RUN make msgpassing

FROM alpine:latest

COPY --from=builder /msgpassing /msgpassing

COPY ./src/sender.sh /sender.sh

COPY ./src/receiver.sh /receiver.sh

CMD "ls -l /"
