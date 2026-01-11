# 🔐 Zero Trust Vault--MongoDB--FastAPI Stack

A **Zero Trust reference architecture** using **FastAPI**, **React**,
**MongoDB**, and **HashiCorp Vault**.

This project demonstrates how to **completely eliminate hardcoded
database passwords**.\
Instead of long-lived credentials, applications and administrators must
request **short-lived, dynamically generated credentials** from Vault
that automatically rotate every few minutes.

------------------------------------------------------------------------

## 🏗 Architecture

``` mermaid
graph TD
    User[User / Browser] -->|Port 3000| Frontend[React Frontend]
    Frontend -->|Fetch /data| Backend[FastAPI Backend]

    subgraph "Docker Network"
        Backend -->|1. Request Creds| Vault[HashiCorp Vault]
        Vault -->|2. Generate Dynamic User| MongoDB[(MongoDB)]
        Backend -->|3. Connect with Temp User| MongoDB

        Agent[Vault Agent] -.->|Rotate Secret File| Backend
    end
```

------------------------------------------------------------------------

## 🚀 Features

-   Dynamic Secrets (5-minute TTL)
-   Automatic credential rotation via Vault Agent
-   Zero Trust admin access (no static DB passwords)
-   Full-stack demo with live credential refresh

------------------------------------------------------------------------

## 🧰 Tech Stack

Frontend: React\
Backend: FastAPI\
Database: MongoDB\
Security: HashiCorp Vault + Vault Agent\
Runtime: Docker & Docker Compose

------------------------------------------------------------------------

## 🛠 Prerequisites

-   Docker Desktop
-   Windows OS
-   Ports: 3000, 8000, 8200

------------------------------------------------------------------------

## ⚡ Quick Start

``` bash
git clone <your-repo-url>
cd zero_trust
docker-compose up -d vault mongodb
setup-vault.bat
docker-compose up -d --build backend frontend vault-agent
```

------------------------------------------------------------------------

## 📊 Manual Zero Trust DB Access

``` bash
docker exec -e VAULT_TOKEN=root-token vault vault read database/creds/web-role
docker exec -it mongodb mongosh -u <username> -p <password> --authenticationDatabase admin
```

------------------------------------------------------------------------

## 📂 Project Structure

    backend/
    frontend/
    setup-vault.bat
    docker-compose.yml

------------------------------------------------------------------------

## 🔐 Zero Trust Proof

Static MongoDB credentials will fail after Vault initialization.
