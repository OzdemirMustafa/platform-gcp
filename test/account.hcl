inputs = {
  project_id         = get_env("GCP_PROJECT_ID", "my-first-project")
  gcs_bucket_name    = get_env("BUCKET_NAME", "platform-gcp-test-terragrunt-tf-states")
  domain_name        = "gcp"
  organization_id    = "123456789012"
  billing_account    = "012345-6789AB-CDEF01"
}
