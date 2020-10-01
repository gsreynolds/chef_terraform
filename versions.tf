
terraform {
  required_version = "~> 0.13"

  required_providers {
    aws = {
      source  = "-/aws"
      version = "~> 3.8.0"
    }
    local = {
      source  = "-/local"
      version = "~> 1.4.0"
    }
    null = {
      source  = "-/null"
      version = "~> 2.1.2"
    }
    template = {
      source  = "-/template"
      version = "~> 2.1.2"
    }
    hashiexternal = {
      source  = "hashicorp/external"
      version = "~> 1.2.0"
    }
    hashilocal = {
      source  = "hashicorp/local"
      version = "~> 1.4.0"
    }
    hashinull = {
      source  = "hashicorp/null"
      version = "~> 2.1.2"
    }
    hashitemplate = {
      source  = "hashicorp/template"
      version = "~> 2.1.2"
    }
  }
}
