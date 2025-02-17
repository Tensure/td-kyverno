# This is a demo of Kyverno which is greek for Govern. 
```bash
clear
```
<!-- @SHOW -->
First we're going to setup our local cluster with kind. 

```bash
kind create cluster -n kyverno-demo
```
<!-- @nowaitbefore -->
Sweet we have a cluster. Now I'm going to use terraform to bootstrap it with ArgoCD and Kyverno
<!-- @noshow -->
```bash
terraform init && terraform apply -auto-approve
```
<!-- @SHOW -->
<!-- @wait_clear -->
Now we're ready to start our demo!
Kyverno is running but no policies have been setup to enforce. 

Okay Lets take a look at a deployment of nginx. 

```bash
cat no-requests-or-limits-deploy.yaml
```

As you can see this pod doesn't have requests or limits defined
which is NOT a best practice for K8S deployments. 

If we apply this yaml it will get deployed as normal without a policy to enforce:

```bash
kubectl apply -f no-requests-or-limits-deploy.yaml
```

Joe you should wait a  second for the apply to work here and then press enter ;D 

```bash
kubectl get deployments
```

Okay so that's not ideal lets go ahead and delete that. 

```bash
kubectl delete deployment nginx-deployment
```

<!-- @wait_clear -->

Lets look at a Kyverno policy that will help us out here

```bash
cat requests-and-limits-policy.yaml
```

```bash
kubectl apply -f requests-and-limits-policy.yaml
```

```bash
kubectl get clusterpolicy -A
``` 

Okay with our new policy applied that will enforce our policy lets see what happens!

```bash
kubectl apply -f no-requests-or-limits-deploy.yaml
```

<!-- @wait_clear -->   

Lets look at what happens when we adhere to the policy's rules

```bash
cat requests-and-limits-deploy.yaml
```

```bash
kubectl apply -f requests-and-limits-deploy.yaml
```

```bash
kubectl get deployments nginx-deployment
```

<!-- @noshow -->
```bash
kubectl delete deployment nginx-deployment
```

<!-- @SHOW -->
<!-- @wait_clear -->

Lets look at the other kind of policy. We can also use policies to CHANGE or even ADD things to our running resources. 

Instead of denying deployments outright we can change them so they are 
as our best practices desire. 

Lets look at example policy

```bash
cat label-orphaned-deployments-policy.yaml
```

This policy should add the orphaned label to deployments missing owner lets apply it

```bash
kubectl apply -f label-orphaned-deployments-policy.yaml
```
```bash
kubectl get clusterpolicy -A
```
and lets put our nginx deployment back without the proper owner labels

```bash
kubectl apply -f requests-and-limits-deploy.yaml
```

Lets see what happened!

```bash
kubectl get deployment nginx-deployment -o jsonpath='{.metadata.labels}'
```
<!-- @wait_clear -->

What happens if we combine the power of kyverno with the power of ArgoCD?

```bash
kubectl apply -f argo-policies.yaml
```

```bash
kubectl port-forward service/argo-cd-argocd-server 8080:80 -n argocd
```
<!-- @wait -->
<!-- @HIDE -->

```bash
terraform destroy -auto-approve
```
<!-- @nowaitbefore -->
```bash
kind delete cluster --name kyverno-demo
```