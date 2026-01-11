vault {
  address = "http://vault:8200"
}

auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      # These files are mounted from ./backend on the host
      role_id_file_path = "/app/auth/role_id"
      secret_id_file_path = "/app/auth/secret_id"
      remove_secret_id_file_after_reading = false
    }
  }
}

template {
  contents = <<EOH
  {
    "username": "{{ with secret "database/creds/web-role" }}{{ .Data.username }}{{ end }}",
    "password": "{{ with secret "database/creds/web-role" }}{{ .Data.password }}{{ end }}"
  }
  EOH
  destination = "/app/secrets/mongodb-creds.json"
}