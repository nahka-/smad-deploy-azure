locals {
  project_name    = terraform.workspace == "default" ? var.project_name : "${terraform.workspace}${var.project_name}"
  k8s_agent_count = terraform.workspace == "default" ? var.k8s_agent_count : var.testing_k8s_agent_count
}

# module "tfstate_storage_azure" {
#     source  = "./modules/tfstate_storage_azure"
#
#     location = "West Europe"
#     project_name = "kuksatrng"
#     environment = "development"
#     tfstate_storage_account_name_suffix = "tfstatesa"
# }

module "k8s_cluster_azure" {
  source                         = "./modules/k8s"
  k8s_agent_count                = local.k8s_agent_count
  k8s_resource_group_name_suffix = var.k8s_resource_group_name_suffix
  project_name                   = local.project_name
}

<<<<<<< HEAD
module "container_registry_for_k8s" {
  source                                   = "./modules/container_registry"
  container_registry_resource_group_suffix = var.container_registry_resource_group_suffix
  project_name                             = local.project_name
  k8s_cluster_node_resource_group          = module.k8s_cluster_azure.k8s_cluster_node_resource_group
  k8s_cluster_kubelet_managed_identity_id  = module.k8s_cluster_azure.kubelet_object_id
}
=======
/* module "container_registry_for_k8s" {
    source = "./modules/container_registry"
    container_registry_resource_group_suffix = var.container_registry_resource_group_suffix
    project_name = local.project_name
    k8s_cluster_node_resource_group = module.k8s_cluster_azure.k8s_cluster_node_resource_group
    k8s_cluster_kubelet_managed_identity_id = module.k8s_cluster_azure.kubelet_object_id
} */
>>>>>>> 37c943c (WIP: Separate container creation)

module "container_deployment" {
  providers  = { kubernetes = kubernetes, helm = helm }
  depends_on = [module.k8s_cluster_azure]
  source     = "./modules/container_deployment"

  #depends_on here or no need? 
  cluster_name = tostring(module.k8s_cluster_azure.k8s_cluster_name)
}


terraform {

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.45.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.1"
    }

  }

  backend "azurerm" {
    # Shared state is stored in Azure
    # (https://www.terraform.io/docs/backends/types/azurerm.html)
    #
    # Use './modules/tfstate_storage_azure/main.tf' to create one if needed.
    # See README.md for more details.
    #
    # Authentication is expected to be done via Azure CLI
    # For other authentication means see documentation provided by Microsoft:
    # https://docs.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage
    #
    # Set to "${lower(var.project_name)}-${var.tfstate_resource_group_name_suffix}"
    resource_group_name = "kuksatrng-tfstate-rg"
    # Set to "${lower(var.project_name)}${var.tfstate_storage_account_name_suffix}"
    storage_account_name = "kuksatrngtfstatesa"
    # Set to var.tfstate_container_name
    container_name = "tfstate"
    # Set up "${lower(var.project_name)}.tfstate"
    key = "kuksatrng.tfstate"
  }
}

provider "azurerm" {
  features {}
}

provider "kubernetes" {
  host                   = module.k8s_cluster_azure.host
  client_key             = base64decode(module.k8s_cluster_azure.client_key)
  client_certificate     = base64decode(module.k8s_cluster_azure.client_certificate)
  cluster_ca_certificate = base64decode(module.k8s_cluster_azure.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.k8s_cluster_azure.host
    client_key             = base64decode(module.k8s_cluster_azure.client_key)
    client_certificate     = base64decode(module.k8s_cluster_azure.client_certificate)
    cluster_ca_certificate = base64decode(module.k8s_cluster_azure.cluster_ca_certificate)
  }
}
