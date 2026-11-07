# terraform/modules/acr/tasks.tf
resource "azurerm_container_registry_task" "trivy_scan" {
  name                = "trivy-scan"
  container_registry_id = azurerm_container_registry.acr.id
  run_on_update       = true

  container_image {
    source_image {
      repository = "payments-api"
      tag        = "latest"
    }
    target_images {
      repository = "payments-api"
      tag        = "scanned"
    }
  }

  command = "trivy image --severity HIGH,CRITICAL --exit-code 1 {{source}}"

  triggers {
    schedule {
      schedule_type = "Daily"
      time          = "02:00"
      day           = "Monday"
    }
  }
}   