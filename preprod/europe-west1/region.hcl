inputs = {
  region = get_env("GCP_REGION", "europe-west1")
  zone = get_env("GCP_ZONE", "europe-west1-b")
  vpc_cidr_block = "10.80.0.0/18"
}