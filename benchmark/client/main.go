package main

import (
	"context"
	"fmt"
	"log"

	tmhttp "github.com/tendermint/tendermint/rpc/client/http"
)

func main() {
	// from minikube service tendermint-rpc --url
	client, err := tmhttp.New("http://127.0.0.1:63726")
	if err != nil {
		log.Fatal(err)
	}

	status, err := client.Status(context.Background())
	if err != nil {
		log.Fatal("Failed to get status:", err)
	}

	fmt.Printf("Node Info: %s\n", status.NodeInfo.ID())
}
