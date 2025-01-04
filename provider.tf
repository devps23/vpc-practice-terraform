provider "vault" {
  address        ="https://18.206.180.186:8200"
  token          = var.vault_token
  skip_tls_verify = true
}
