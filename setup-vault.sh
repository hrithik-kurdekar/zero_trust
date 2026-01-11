#!/bin/bash

# Define a helper function to avoid typing the token every time
# This makes the commands cleaner and easier to read
function vault_cmd {
    docker exec -e VAULT_TOKEN=root-token vault vault "$@"
}

echo "Waiting for Vault..."
sleep 5

# 1. Enable Database Engine
echo "Enabling Database Engine..."
vault_cmd secrets enable database

# 2. Configure MongoDB connection
echo "Configuring MongoDB connection..."
vault_cmd write database/config/my-mongo \
    plugin_name=mongodb-database-plugin \
    allowed_roles="web-role" \
    connection_url="mongodb://admin:initial_bootstrap_password@mongodb:27017/admin" \
    username="admin" \
    password="initial_bootstrap_password"

# 3. Rotate Root Password
echo "ROTATING ROOT PASSWORD..."
vault_cmd write -force database/rotate-root/my-mongo

# 4. Create Role
echo "Creating web-role..."
vault_cmd write database/roles/web-role \
    db_name=my-mongo \
    creation_statements='{ "db": "admin", "roles": [{ "role": "readWrite", "db": "test_db" }] }' \
    default_ttl="5m" \
    max_ttl="1h"

# 5. Enable AppRole
echo "Enabling AppRole..."
vault_cmd auth enable approle

# 6. Create Policy
echo "Creating Policy..."
# Note: We can't use the function easily with heredocs (<<EOF), so we use the full command here
docker exec -e VAULT_TOKEN=root-token -i vault vault policy write web-policy - <<EOF
path "database/creds/web-role" {
  capabilities = ["read"]
}
EOF

# 7. Create AppRole
echo "Creating AppRole..."
vault_cmd write auth/approle/role/web-app-role \
    token_policies="web-policy" \
    token_ttl=1h

# 8. Generate Credentials
echo "Generating AppRole Credentials..."
vault_cmd read -field=role_id auth/approle/role/web-app-role/role-id > backend/role_id
vault_cmd write -f -field=secret_id auth/approle/role/web-app-role/secret-id > backend/secret_id

echo "Setup Complete! Restarting services..."
docker restart vault-agent backend