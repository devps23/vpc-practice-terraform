provider "vault" {
  address        ="https://3.84.152.116:8200"
  token          = var.vault_token
  skip_tls_verify = true
}
