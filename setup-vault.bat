@echo off
echo Waiting for Vault to start...
timeout /t 5 /nobreak >nul

REM --- 1. Enable Database Engine ---
echo Enabling Database Engine...
docker exec -e VAULT_TOKEN=root-token vault vault secrets enable database

REM --- 2. Configure MongoDB connection ---
echo Configuring MongoDB connection...
REM FIX: We used {{username}} and {{password}} so Vault updates the URL automatically after rotation
docker exec -e VAULT_TOKEN=root-token vault vault write database/config/my-mongo ^
    plugin_name=mongodb-database-plugin ^
    allowed_roles="web-role" ^
    connection_url="mongodb://{{username}}:{{password}}@mongodb:27017/admin" ^
    username="admin" ^
    password="initial_bootstrap_password"

REM --- 3. Rotate Root Password ---
echo ROTATING ROOT PASSWORD...
docker exec -e VAULT_TOKEN=root-token vault vault write -force database/rotate-root/my-mongo

REM --- 4. Create Role ---
echo Creating web-role...
docker exec -e VAULT_TOKEN=root-token vault vault write database/roles/web-role ^
    db_name=my-mongo ^
    creation_statements="{ \"db\": \"admin\", \"roles\": [{ \"role\": \"readWrite\", \"db\": \"test_db\" }] }" ^
    default_ttl="5m" ^
    max_ttl="1h"

REM --- 5. Enable AppRole ---
echo Enabling AppRole...
docker exec -e VAULT_TOKEN=root-token vault vault auth enable approle

REM --- 6. Create Policy ---
echo Creating Policy...
echo path "database/creds/web-role" { capabilities = ["read"] } | docker exec -i -e VAULT_TOKEN=root-token vault vault policy write web-policy -

REM --- 7. Create AppRole ---
echo Creating AppRole...
docker exec -e VAULT_TOKEN=root-token vault vault write auth/approle/role/web-app-role ^
    token_policies="web-policy" ^
    token_ttl=1h

REM --- 8. Generate Credentials ---
echo Generating AppRole Credentials...
docker exec -e VAULT_TOKEN=root-token vault vault read -field=role_id auth/approle/role/web-app-role/role-id > backend\role_id
docker exec -e VAULT_TOKEN=root-token vault vault write -f -field=secret_id auth/approle/role/web-app-role/secret-id > backend\secret_id

echo Setup Complete! Restarting services...
docker restart vault-agent backend
pause