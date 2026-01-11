pid_file = "/vault/pid"

auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path = "/vault/config/role_id"      # <--- MATCHES MOUNT
      secret_id_file_path = "/vault/config/secret_id"  # <--- MATCHES MOUNT
      remove_secret_id_file_after_reading = false
    }
  }

  sink "file" {
    config = {
      path = "/vault/secrets/.vault-token"
    }
  }
}

template {
  destination = "/vault/secrets/db_creds.json"
  contents = <<EOT
{{ with secret "database/creds/web-role" }}
{
  "username": "{{ .Data.username }}",
  "password": "{{ .Data.password }}"
}
{{ end }}
EOT
}
