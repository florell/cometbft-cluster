docker build -t config-abci:local -f DOCKERFILE .
minikube image load config-abci:local
