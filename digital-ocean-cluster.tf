variable "do_token" {}

locals {
  do_kube_ver = "1.16.6-do.0"
  region = "blr1"
  size = "s-2vcpu-2gb"
  cluster_name = "honest"
}

# Get a Digital Ocean token from your Digital Ocean account
#   See: https://www.digitalocean.com/docs/api/create-personal-access-token/
# Set TF_VAR_do_token to use your Digital Ocean token automatically
provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_kubernetes_cluster" "my_digital_ocean_cluster" {
  name    = local.cluster_name
  region  = local.region
  version = local.do_kube_ver

  node_pool {
    name       = "worker-pool"
    size       = local.size
    node_count = 2
  }
}

output "cluster-id" {
  value = "${digitalocean_kubernetes_cluster.my_digital_ocean_cluster.id}"
}

resource "null_resource" "get" {
  provisioner "local-exec" {
    command = "curl -X GET -H \"Content-Type: application/json\" -H \"Authorization: Bearer ${var.do_token}\" \"https://api.digitalocean.com/v2/kubernetes/clusters/${digitalocean_kubernetes_cluster.my_digital_ocean_cluster.id}/kubeconfig\" > kubeconfig"
  }

  triggers = {
    build_number = "${timestamp()}"
  }
}

data "local_file" "tiller" {
    filename = "tiller.yaml"
}
resource "null_resource" "tiller" {
  provisioner "local-exec" {
    working_dir = path.module
    command = <<EOS
kubectl --kubeconfig kubeconfig apply -f tiller.yaml
EOS
  }

  triggers = {
    tiller_content = data.local_file.tiller.content
    cluster_id = digitalocean_kubernetes_cluster.my_digital_ocean_cluster.id
  }
}

data "local_file" "mandatory" {
    filename = "mandatory.yaml"
}
resource "null_resource" "mandatory" {
  provisioner "local-exec" {
    working_dir = path.module
    command = <<EOS
kubectl --kubeconfig kubeconfig apply -f mandatory.yaml
EOS
  }

  triggers = {
    tiller_content = data.local_file.mandatory.content
    cluster_id = digitalocean_kubernetes_cluster.my_digital_ocean_cluster.id
  }
}

data "local_file" "cloud-generic" {
    filename = "cloud-generic.yaml"
}
resource "null_resource" "cloud-generic" {
  provisioner "local-exec" {
    working_dir = path.module
    command = <<EOS
kubectl --kubeconfig kubeconfig apply -f cloud-generic.yaml
EOS
  }

  triggers = {
    tiller_content = data.local_file.cloud-generic.content
    cluster_id = digitalocean_kubernetes_cluster.my_digital_ocean_cluster.id
  }
}

data "local_file" "cert-manager" {
    filename = "cert-manager.yaml"
}
resource "null_resource" "cert-manager" {
  provisioner "local-exec" {
    working_dir = path.module
    command = <<EOS
kubectl --kubeconfig kubeconfig apply -f cert-manager.yaml
EOS
  }

  triggers = {
    tiller_content = data.local_file.cert-manager.content
    cluster_id = digitalocean_kubernetes_cluster.my_digital_ocean_cluster.id
  }
}

data "local_file" "prod-issuer" {
    filename = "prod-issuer.yaml"
}
resource "null_resource" "prod-issuer" {
  provisioner "local-exec" {
    working_dir = path.module
    command = <<EOS
kubectl --kubeconfig kubeconfig apply -f prod-issuer.yaml
EOS
  }

  triggers = {
    tiller_content = data.local_file.prod-issuer.content
    cluster_id = digitalocean_kubernetes_cluster.my_digital_ocean_cluster.id
  }
}
