<div align="center"

### My Home Operations Repository :octocat:

_... managed with Flux and Rennovate_

</div>

---

## 📖 Overview

This is a mono repository for my home infrastructure and Kubernetes clusters. I use Infrastructure as Code (Iac) and GitOps practices using [OpenTofu](https://opentofu.org/), [Kubernetes](https://kubernetes.io/), [Flux](https://fluxcd.io/) and [Rennovate](https://github.com/renovatebot/renovate).

### Components

This currently includes the followings:

- Terraform stack and modules to manage my Mikrotik router, switches and access points.
- Terraform stack to deploy a Talos cluster in Proxmox
- Cluster configuration in the `cluster/<clusterName>` folder, watched by Flux.
- Some containers that run in the kubernetes and are published to GitHub packages
- CI code using [Dagger](https://dagger.io/) running in GitHub Actions
