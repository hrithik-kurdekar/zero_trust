@echo off
setlocal

echo ==============================================
echo      ZERO TRUST VAULT SETUP (CI MODE)
echo ==============================================

:: Ensure we talk to localhost
set VAULT_ADDR=http://127.0.0.1:8200

echo [1/6] Waiting for Vault to be ready...
:check_vault
curl -s %VAULT_ADDR%/v1/sys/health >nul
if %errorlevel% neq 0 (
    echo    Vault not ready, retrying in 2s...
    timeout /t 2 /nobreak >nul
    goto check_vault
)
echo    Vault is UP!

echo [2/6] Enabling Database Engine...
docker exec vault vault secrets enable database

echo [3/6] Configuring MongoDB connection...
docker exec vault vault write database/config/my-mongo ^
    plugin_name=mongodb-database-plugin ^
    allowed_roles="web-role" ^
    connection_url="mongodb://{{username}}:{{password}}@mongodb:27017/admin?ssl=false" ^
    username="admin" ^
    password="initial_bootstrap_password"

echo [4/6] ROTATING ROOT PASSWORD (Zero Trust)...
docker exec vault vault write -force database/rotate-root/my-mongo

echo [5/6] Creating Application Role...
docker exec vault vault write database/roles/web-role ^
    db_name=my-mongo ^
    creation_statements="{\"db\": \"test_db\", \"roles\": [{\"role\": \"readWrite\"}]}" ^
    default_ttl="1h" ^
    max_ttl="24h"

echo [6/6] Configuring AppRole Auth...
docker exec vault vault auth enable approle
docker exec vault vault policy write web-policy - <<EOF
path "database/creds/web-role" {
  capabilities = ["read"]
}
EOF
docker exec vault vault write auth/approle/role/web-app-role ^
    token_policies="web-policy" ^
    token_ttl=1h ^
    token_max_ttl=4h

echo.
echo ==============================================
echo      SETUP COMPLETE
echo ==============================================
:: Removed 'pause' so CI doesn't hang
