locals {
  project_name = terraform.workspace == "default" ? var.project_name : "${terraform.workspace}${var.project_name}"
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.45.1"
    }
  }
}

<<<<<<< HEAD
provider "azurerm" {
  features {}
=======
  provider "azurerm" {
      features {}
  }

module "k8s_cluster_azure" {
    source = "../k8s"
    project_name = local.project_name
>>>>>>> 37c943c (WIP: Separate container creation)
}
# data "azurerm_user_assigned_identity" "aks_kubelet_mi_id" {
#   name                = "${var.k8s_cluster_managed_identity_id}"
#   resource_group_name = "${var.k8s_cluster_node_resource_group}"
# }

resource "azurerm_resource_group" "acr_rg" {
    name     = "${lower(local.project_name)}-${var.container_registry_resource_group_suffix}"
    location = var.location
}

resource "azurerm_container_registry" "acr" {
  # alpha numeric characters only are allowed
  name                     = "${lower(local.project_name)}${var.container_registry_name_suffix}"
  resource_group_name      = azurerm_resource_group.acr_rg.name
  location                 = azurerm_resource_group.acr_rg.location
/*       lifecycle {
        prevent_destroy = true
    } */
  sku                      = "Standard"
  admin_enabled            = false
}

resource "azurerm_role_assignment" "acrpull_role" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = module.k8s_cluster_azure.kubelet_object_id
  skip_service_principal_aad_check = true
}
