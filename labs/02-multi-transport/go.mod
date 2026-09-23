module github.com/rbrus/agent-redteam-labs/labs/02-multi-transport

go 1.27

require github.com/rbrus/redwire v0.0.0

require (
	github.com/google/uuid v1.6.0 // indirect
	github.com/gorilla/websocket v1.5.3 // indirect
)

replace github.com/rbrus/redwire => ../../../redwire
