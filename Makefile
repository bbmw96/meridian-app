# MERIDIAN — Global Business Intelligence OS
# Makefile for development convenience

.PHONY: all up down build test clean mql-build mql-test ios-setup backend-setup

## ── Top-level ────────────────────────────────────────────────────────────────

all: build

## Start all services with Docker Compose
up:
	docker compose -f infrastructure/docker-compose.yml up -d

## Stop all services
down:
	docker compose -f infrastructure/docker-compose.yml down

## Rebuild all Docker images
build:
	docker compose -f infrastructure/docker-compose.yml build

## Run all tests
test: mql-test backend-test

## Remove build artefacts
clean: mql-clean
	@echo "Cleaned build artefacts"

## ── MQL Compiler (Rust) ──────────────────────────────────────────────────────

## Build the MQL compiler in debug mode
mql-build:
	cargo build --manifest-path mql/Cargo.toml

## Build the MQL compiler in release mode
mql-release:
	cargo build --manifest-path mql/Cargo.toml --release

## Run MQL compiler tests
mql-test:
	cargo test --manifest-path mql/Cargo.toml

## Build MQL compiler as WASM module
mql-wasm:
	cd mql && wasm-pack build --target bundler --out-dir ../ios/MERIDIAN/Resources/mql_wasm

## Remove MQL build artefacts
mql-clean:
	cargo clean --manifest-path mql/Cargo.toml

## ── iOS ──────────────────────────────────────────────────────────────────────

## Open the iOS project in Xcode
ios-open:
	open ios/MERIDIAN.xcodeproj

## Resolve Swift Package Manager dependencies
ios-setup:
	cd ios && swift package resolve

## ── Backend Services ─────────────────────────────────────────────────────────

## Install all backend dependencies (runs for all services)
backend-setup:
	cd services/gateway && go mod download
	cd services/intelligence && pip install -r requirements.txt
	cd services/bff && npm install
	cd services/realtime && mix deps.get

## Run backend tests
backend-test:
	cd services/gateway && go test ./...
	cd services/intelligence && python -m pytest
	cd services/bff && npm test
	cd services/realtime && mix test

## ── Intelligence Service (Python) ───────────────────────────────────────────

## Run intelligence service in development
intelligence-dev:
	cd services/intelligence && uvicorn main:app --reload --port 8001

## ── Gateway (Go) ────────────────────────────────────────────────────────────

## Run gateway in development
gateway-dev:
	cd services/gateway && go run main.go

## ── BFF (TypeScript) ────────────────────────────────────────────────────────

## Run BFF in development
bff-dev:
	cd services/bff && npm run dev

## ── Real-time (Elixir) ──────────────────────────────────────────────────────

## Run real-time service in development
realtime-dev:
	cd services/realtime && mix phx.server

## ── Database ────────────────────────────────────────────────────────────────

## Run PostgreSQL migrations
db-migrate:
	docker compose -f infrastructure/docker-compose.yml exec postgres \
		psql -U meridian -d meridian -f /migrations/001_initial.sql

## Open PostgreSQL shell
db-shell:
	docker compose -f infrastructure/docker-compose.yml exec postgres \
		psql -U meridian -d meridian

## ── Terraform ────────────────────────────────────────────────────────────────

## Initialise Terraform
tf-init:
	cd infrastructure/terraform && terraform init

## Preview infrastructure changes
tf-plan:
	cd infrastructure/terraform && terraform plan

## Apply infrastructure changes (confirms before applying)
tf-apply:
	cd infrastructure/terraform && terraform apply

## ── Code Quality ─────────────────────────────────────────────────────────────

## Run all linters
lint:
	cd services/gateway && golangci-lint run
	cd services/intelligence && ruff check .
	cd services/bff && npm run lint
	cd mql && cargo clippy -- -D warnings

## Format all code
format:
	cd services/gateway && gofmt -w .
	cd services/intelligence && ruff format .
	cd services/bff && npm run format
	cd mql && cargo fmt
