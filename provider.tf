provider "vault" {
  address        ="https://vault-intenral.pdevops72.online:8200"
  token          = var.vault_token
  skip_tls_verify = true
}
