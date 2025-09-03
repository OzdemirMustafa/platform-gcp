inputs = {
  project_id         = get_env("GCP_PROJECT_ID", "")
  gcs_bucket_name    = get_env("BUCKET_NAME", "")
  domain_name        = get_env("DOMAIN_NAME", "")
  organization_id    = get_env("GCP_ORG_ID", "")
  billing_account    = get_env("GCP_BILLING_ACCOUNT", "")
}