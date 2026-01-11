@echo off
setlocal

echo ==============================================
echo      ZERO TRUST VAULT SETUP (CI MODE)
echo ==============================================

:: Ensure we talk to localhost for the check
set VAULT_ADDR=http://127.0.0.1:8200

echo [1/6] Waiting for Vault to be ready...
:check_vault
curl -s %VAULT_ADDR%/v1/sys/health >nul
if %errorlevel% neq 0 (
    echo    Vault not ready, retrying...
    ping 127.0.0.1 -n 3 > nul
    goto check_vault
)
echo    Vault is UP!

echo [2/6] Enabling Database Engine...
:: FIX: Added "-e VAULT_TOKEN=root-token" to all commands below
docker exec -e VAULT_TOKEN=root-token vault vault secrets enable database

echo [3/6] Configuring MongoDB connection...
docker exec -e VAULT_TOKEN=root-token vault vault write database/config/my-mongo ^
    plugin_name=mongodb-database-plugin ^
    allowed_roles="web-role" ^
    connection_url="mongodb://{{username}}:{{password}}@mongodb:27017/admin?ssl=false" ^
    username="admin" ^
    password="initial_bootstrap_password"

echo [4/6] ROTATING ROOT PASSWORD (Zero Trust)...
docker exec -e VAULT_TOKEN=root-token vault vault write -force database/rotate-root/my-mongo

echo [5/6] Creating Application Role...
docker exec -e VAULT_TOKEN=root-token vault vault write database/roles/web-role ^
    db_name=my-mongo ^
    creation_statements="{\"db\": \"test_db\", \"roles\": [{\"role\": \"readWrite\"}]}" ^
    default_ttl="1h" ^
    max_ttl="24h"

echo [6/6] Configuring AppRole Auth...
docker exec -e VAULT_TOKEN=root-token vault vault auth enable approle

:: FIX: Syntax for HEREDOC (<<EOF) often fails in Batch.
:: We will use separate commands instead to be safe in CI.
docker exec -e VAULT_TOKEN=root-token vault vault policy write web-policy - < policy.hcl 2>nul || (
    echo path "database/creds/web-role" { capabilities = ["read"] } > temp_policy.hcl
    docker cp temp_policy.hcl vault:/tmp/web-policy.hcl
    docker exec -e VAULT_TOKEN=root-token vault vault policy write web-policy /tmp/web-policy.hcl
    del temp_policy.hcl
)

docker exec -e VAULT_TOKEN=root-token vault vault write auth/approle/role/web-app-role ^
    token_policies="web-policy" ^
    token_ttl=1h ^
    token_max_ttl=4h

echo.
echo ==============================================
echo      SETUP COMPLETE
echo ==============================================
