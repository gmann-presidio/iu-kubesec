# Kubernetes Security Recommendations for Indiana University

This repository contains example code for use by Indiana University. In response to the security incident on the week of June 22, 2025, Presidio consultants were brought in to help heal their webserver. Engineers were engaged further to help make recommendations on Kubernetes and container security.

- [Kubernetes Security Recommendations for Indiana University](#kubernetes-security-recommendations-for-indiana-university)
  - [Components](#components)
  - [Concepts](#concepts)
    - [1. Continuous Delivery and Enforcement of Web Apps with ArgoCD](#1-continuous-delivery-and-enforcement-of-web-apps-with-argocd)
    - [2. Pod Governance with OPA Gatekeeper](#2-pod-governance-with-opa-gatekeeper)
    - [3. Governance of Kubernetes ingress and egress](#3-governance-of-kubernetes-ingress-and-egress)
    - [4. Continuous scan of Web Content](#4-continuous-scan-of-web-content)
  - [Installation](#installation)
  - [Using this Delivery](#using-this-delivery)
    - [The Argo Apps](#the-argo-apps)
    - [Change an App in ArgoCD](#change-an-app-in-argocd)
    - [Try to change an App in Kubectl](#try-to-change-an-app-in-kubectl)
    - [Turn Off Self-Healing](#turn-off-self-healing)
    - [The Sidecar Scanner](#the-sidecar-scanner)
    - [OPA Gatekeeper](#opa-gatekeeper)
    - [Network Policy](#network-policy)

## Components

This repository is built around the following components for simplicity of use and adaptibility:

- [Minikube](https://minikube.sigs.k8s.io/docs/start)
- [ArgoCD](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/docs/)
- [Stakater Reloader](https://github.com/stakater/Reloader)
    - Helps with visuals on the config-map based web apps

## Concepts

Example code written here is meant to address some subjects discussed with Indiana University on the week of the incident. The goal of this exercise was to deliver a suggested extension to their existing Argo infrastructure which would help them to update and govern their apps with reduced error and effort. The following improvements were suggested.

1. Continuous Delivery and Enforcement of Web Apps with ArgoCD
2. Pod Governance with OPA Gatekeeper
3. Governance of Kubernetes ingress and egress
4. Continuous scan of web Content

### 1. Continuous Delivery and Enforcement of Web Apps with ArgoCD

Two small web applications are provided, each served as a single HTML file by nginx. The ArgoCD application keeps them in place and self-healed. An example is provided for changing each and watching them self-heal. Each app is defined under an umbrella "app of apps" in ArgoCD, which governs apps in a single folder.

```sh
argo-apps.yaml   # This is an "app of apps"
|_ apps
   |_ blue
      |_ values.yaml
   |_ green
      |_ values.yaml
```

The two web apps are each created by helm templates that are maintined centrally. Templates are stored in ./charts/gitops-html/templates. 

### 2. Pod Governance with OPA Gatekeeper

The OPA Gatekeeper plugin is installed in the cluster as an ArgoCD application. It includes one basic constraint written in the OPA language, "Rego." The constraint template defines a single pod label, "app." The constraint template enforces the label. Should any pods attempt to join the cluster without the "app" label, the OPA Gatekeeper will reject them.

### 3. Governance of Kubernetes ingress and egress

A network policy is included in the web app helm template. It is written to allow inbound traffic from a single CIDR, and restrict any traffic inside the cluster.

### 4. Continuous scan of Web Content

Each web app includes a sidecar container to scan NFS repositories, and report on vulnerabilities. In this example, the open source clamscan scans the simple "html-volume" mount, but this is easily adjustable. This solution was chosen based on the fact that the IU Web CMS requires content-ops, which can introduce risk of XSS and malware. NFS volume scans may be executed in Kubernetes. This example delivers scan results to stdout.

## Installation

1. Install [minikube](https://minikube.sigs.k8s.io/docs/start)
2. Install ArgoCD on minikube
   
    ```sh
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    # This exposes the ArgoCD API locally
    kubectl port-forward svc/argocd-server -n argocd 8080:443

    # Get the initial Admin password
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    ```

3. Clone (or fork) this GIT Repository to a new repository under your control
4. In your local editor, find and replace all instances of this repo with your own:

    ```sh
    # FIND
    https://github.com/gmann-presidio/iu-kubesec.git

    # REPLACE WITH
    https://github.com/<your-organizatoin>/<your-repo>.git
    ```
5. Push all changes
6. Browse to you ArgoCD instance, which should be available at your port-forwarded path, `https://localhost:8080`
7. You should see applications begin to appear as app tiles

## Using this Delivery

### The Argo Apps

Each application is set up in the directory `argo-apps`. For simplicity, one file is provided per app, but there are many opportunities to streamline or automate this approach. Argo Event triggers are recommended in a more mature version of this solution.

Both cluster infrastructure and user-level applications are placed in this repository. All are under a single *argo project*, "default." In a more mature delivery, separate argo projects should be defined to support other levels of applications. This is left as an exercise for the user, and is well documented by the Argo project.

Content sources: 

    - For the apps "blue" and "green," the content is sourced from this repository. Other apps may be created in a similar way by cloning each of these. 
    - For infra apps such as the stakater-reloader and OPA Gatekeeper, content is sourced from their project's repositories. Other infra apps may be installed in a similar way, by following patterns on those files.

App values:

Application-specific configuration values are kept in the /apps directories. For clarity, each app is given its own folder. (This is not necessarily required by ArgoCD.) App folders contain values.yaml (where applicable) or application specific files. Argo apps often point to app values files, and the values may be tuned outside of the lifecycle of any other app. These are meant to stay small and very specific. 

Common values such as web server versions are meant to live in a more general location. That is kept in their helm chart directory at `/argo-apps/charts/gitops-html/values.yaml`.

### Change an App in ArgoCD

1. Navigate to apps/blue or apps/green
2. Find the htmlcontent field
3. Change any part of the htmlcontent - background color, text, etc
4. Push changes to GIT
5. Watch the ArgoCD tile - it will continuously check for GIT changes, then refresh the app

### Try to change an App in Kubectl

Make a small change to the configmap in the "blue" namespace: `kubectl edit cm -n blue blue-configmap`

    - Change "GitOps" to "ArgoCD"
    - Save and close the configmap

Get the configmap again, examine it for your changes: `kubectl get cm -n blue blue-configmap -o yaml`

Your change should not be there. ArgoCD reverted it!

Click into the tile for the blue app in ArgoCD. Sync status will show that the app was self-healed.

### Turn Off Self-Healing

1. In the ArgoCD portal, find the Blue app.
2. Click the "blue" tile on the left hand side
3. Scroll down to "Sync Policy"
4. Click to toggle "Self Heal."

Repeat the exercise above, and watch your changes appear in the browser.

Reset "Self Heal" to restore the app to your Git revision. You may also need to "Sync" or "Refresh" the app via the Argo console.

### The Sidecar Scanner

A sidecar scanning container is sketched in to the application deployment. It is managed centrally via a shared Helm chart, and may be adjusted as desired. The chart is located at charts/gitops-htlm/deployment.yaml

Access clamscan reports via stdout like this:

**Bash**
`kubectl logs -n blue $(kubectl get pod -n blue -l app=blue -o jsonpath='{.items[0].metadata.name}') -c clamav`

**Powershell**
`$podName = kubectl get pod -n blue -l app=blue -o jsonpath="{.items[0].metadata.name}"`
`kubectl logs -n blue $podName -c clamav`

### OPA Gatekeeper

OPA Gatekeeper is installed as an ArgoCD application under argo-apps. It is defined as a cluster infrastructure app at `/argo-apps/opa-gatekeeper.yaml`.

One simple constraint and constraint template is loaded for demonstration. It is defined at:

- `/argo-apps/opa-gatekeeper-policies.yaml` (Argo App)
- `/apps/opa-gatekeeper/policies` (OPA Constraints)

A constraint template defines a label enforcement of "app." A constraint then enforces the label "app" for pods only. This is provided for demonstration only. Improvement is encouraged.

### Network Policy

The default helm chart for the web apps includes a network policy that is set to allow traffic from a single CIDR defined in the common values.yaml. For demonstration, traffic is allowed from 127.0.0.1/32. Ingress and egress are both defined, with egress locking down all traffic outside the pod's namespace. (This was considered important due to risk of XSS and virus injection via NFS-mounted web content.) All egress traffic to the internet is allowed.

The policy may be adjusted easily, and is available at `/charts/gitops-html/templates/network.yaml`.