terraform {
  backend "s3" {
    bucket = "siluryan-org"
    key    = "local-cluster"
    region = "us-east-1"
  }
}