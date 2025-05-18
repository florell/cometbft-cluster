package main

import (
	"encoding/json"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/cometbft/cometbft/abci/server"
	"github.com/cometbft/cometbft/abci/types"
)

type Config struct {
	Version int               `json:"version"`
	Data    map[string]string `json:"data"`
}

type ConfigApp struct {
	types.BaseApplication
	currentConfig Config
	history       []Config
}

func NewConfigApp() *ConfigApp {
	return &ConfigApp{
		currentConfig: Config{
			Version: 1,
			Data:    map[string]string{"initial": "config"},
		},
		history: []Config{},
	}
}

func (app *ConfigApp) DeliverTx(req types.RequestDeliverTx) types.ResponseDeliverTx {
	var msg map[string]interface{}
	if err := json.Unmarshal(req.Tx, &msg); err != nil {
		return types.ResponseDeliverTx{Code: 1, Log: "Invalid JSON"}
	}

	action, ok := msg["action"].(string)
	if !ok {
		return types.ResponseDeliverTx{Code: 1, Log: "No action specified"}
	}

	switch action {
	case "PUBLISH_CONFIG":
		data, ok := msg["data"].(map[string]interface{})
		if !ok {
			return types.ResponseDeliverTx{Code: 1, Log: "Invalid config data"}
		}
		configData := make(map[string]string)
		for k, v := range data {
			configData[k] = v.(string)
		}
		app.history = append(app.history, app.currentConfig)
		app.currentConfig.Version++
		app.currentConfig.Data = configData
		log.Printf("Published new config version: %d", app.currentConfig.Version)

	case "REVERT_CONFIG":
		if len(app.history) == 0 {
			return types.ResponseDeliverTx{Code: 1, Log: "No previous config"}
		}
		app.currentConfig = app.history[len(app.history)-1]
		app.history = app.history[:len(app.history)-1]
		log.Printf("Reverted to config version: %d", app.currentConfig.Version)

	default:
		return types.ResponseDeliverTx{Code: 1, Log: "Unknown action"}
	}

	return types.ResponseDeliverTx{Code: 0}
}

func (app *ConfigApp) Query(req types.RequestQuery) types.ResponseQuery {
	configJSON, err := json.Marshal(app.currentConfig)
	if err != nil {
		return types.ResponseQuery{Code: 1, Log: "Failed to marshal config"}
	}
	return types.ResponseQuery{Code: 0, Value: configJSON}
}

func main() {
	defer func() {
		if r := recover(); r != nil {
			log.Printf("ABCI panic: %+v", r)
		}
	}()
	app := NewConfigApp()
	srv := server.NewSocketServer("tcp://0.0.0.0:26658", app)
	if err := srv.Start(); err != nil {
		log.Fatal(err)
	}
	log.Println("ABCI socket server started on 0.0.0.0:26658")
	defer srv.Stop()

	c := make(chan os.Signal, 1)
	signal.Notify(c, syscall.SIGTERM, syscall.SIGINT)
	<-c
	log.Println("stopping ABCI server…")
	_ = srv.Stop()
}
