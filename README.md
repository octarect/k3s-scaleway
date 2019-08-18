# k3s-scaleway

Build a [k3s](https://github.com/rancher/k3s) cluster on Scaleway by using Terraform.

## Requirements

- [Scaleway](https://www.scaleway.com/) account
- [Cloudflare](https://www.cloudflare.com/) account
- [Terrafrom](https://www.terraform.io/) (If you have never used it, see https://learn.hashicorp.com/terraform/getting-started/install.html)

It costs money to create instances on Scaleway, but compared to other services, they are reasonable.

## Usage

### Copy and edit .tfvars file

```
cp terraform.tfvars.example terraform.tfvars
```

Edit terraform.tfvars.

### Deploy

```
terraform apply
```

### Destroy

```
terraform destroy
```

### Get kubeconfig

After deploying cluster, you may want to get kubeconfig file. Execute the following command;

> It may take a few minutes until the original file is generated on remote server.

```
make config
```
