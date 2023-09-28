docker build . -t messagepassingipc -t danielecr/msgexchange:v0.1 -t danielecr/msgexchange:latest

docker push danielecr/msgexchange:v0.1

docker push danielecr/msgexchange:latest
