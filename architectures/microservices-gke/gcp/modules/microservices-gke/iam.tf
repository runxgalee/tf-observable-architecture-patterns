# Service Accounts for Workload Identity
resource "google_service_account" "workload_identity" {
  for_each = var.enable_workload_identity ? var.service_accounts : {}

  account_id   = "${local.resource_prefix}-${each.key}"
  display_name = each.value.display_name
  project      = var.project_id
}

# IAM roles for Service Accounts
resource "google_project_iam_member" "workload_identity_roles" {
  for_each = var.enable_workload_identity ? {
    for pair in flatten([
      for sa_key, sa in var.service_accounts : [
        for role in sa.roles : {
          key  = "${sa_key}-${role}"
          sa   = sa_key
          role = role
        }
      ]
    ]) : pair.key => pair
  } : {}

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.workload_identity[each.value.sa].email}"
}

# Workload Identity binding (GCP SA -> K8s SA)
resource "google_service_account_iam_member" "workload_identity_binding" {
  for_each = var.enable_workload_identity ? var.service_accounts : {}

  service_account_id = google_service_account.workload_identity[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${each.value.k8s_namespace}/${each.value.k8s_service_account}]"
}
