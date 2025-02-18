# Kyverno Demo

This is a repo for a kyverno demo. It uses [demosh](https://github.com/BuoyantIO/demosh/) created by buoyant!

to run this demo you must have the following things installed:
-  a container management system such as [orbstack](https://orbstack.dev), [podman](https://podman.io/), or [docker](https://www.docker.com/products/docker-desktop/)
- [demosh](https://github.com/BuoyantIO/demosh/) `pip install demosh` 
- [kind](https://kind.sigs.k8s.io/) `brew install kind`
- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) `brew install hashicorp/tap && brew install hashicorp/tap/terraform` or use tfswitch.


to run through the demo just run

```bash
demosh demo.md
```

