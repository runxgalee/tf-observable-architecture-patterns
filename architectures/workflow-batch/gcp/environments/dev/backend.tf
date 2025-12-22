# =============================================
# Terraform Backend Configuration (Development)
# =============================================
# Development environment uses local backend
# State file is stored locally
# =============================================

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
