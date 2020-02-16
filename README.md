# k3s-scaleway

Build a [k3s](https://github.com/rancher/k3s) cluster on Scaleway by using Terraform.
## Branch `heavy-armed` contains the following supports:

- longhorn

## Requirements

- [Terrafrom](https://www.terraform.io/): v0.12 or above
- [Scaleway](https://www.scaleway.com/) account and provider: <= v1.12
- [Cloudflare](https://www.cloudflare.com/) account

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
