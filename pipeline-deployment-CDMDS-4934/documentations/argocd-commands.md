# ArgoCD CLI Commands

## Table of Contents
- [Authentication & Login](#authentication--login)
- [Application Management](#application-management)
- [Cluster Management](#cluster-management)
- [Project Management](#project-management)
- [Repository Management](#repository-management)
- [User & Access Control](#user--access-control)
- [Role-Based Access Control (RBAC)](#role-based-access-control-rbac)

---

## Authentication & Login

| Command | Description | Example |
|---------|------------|---------|
| `argocd login <server>` | Log in to the ArgoCD API server. | `argocd login argocd.example.com` |
| `argocd logout <server>` | Log out from the ArgoCD API server. | `argocd logout argocd.example.com` |
| `argocd session token` | Generate an authentication token for API access. | `argocd session token` |

---

## Application Management

| Command | Description | Example |
|---------|------------|---------|
| `argocd app list` | List all applications. | `argocd app list` |
| `argocd app get <app-name>` | Get detailed information about an application. | `argocd app get reloader` |
| `argocd app status <app-name>` | Check the sync status of an application. | `argocd app status reloader` |
| `argocd app health <app-name>` | Check the health status of an application. | `argocd app health reloader` |
| `argocd app history <app-name>` | View the deployment history of an application. | `argocd app history reloader` |
| `argocd app rollback <app-name> <revision-number>` | Roll back an application to a specific revision. | `argocd app rollback reloader 3` |
| `argocd app sync <app-name>` | Manually sync an application with its Git repository. | `argocd app sync reloader` |
| `argocd app refresh <app-name>` | Refresh application state from the Git repository. | `argocd app refresh reloader` |
| `argocd app resources <app-name>` | List all Kubernetes resources managed by an application. | `argocd app resources reloader` |
| `argocd app delete <app-name>` | Delete an application from ArgoCD. | `argocd app delete reloader` |
| `argocd app diff <app-name>` | Show the difference between the live state and Git repository. | `argocd app diff reloader` |
| `argocd app wait <app-name>` | Wait until an application reaches a healthy state. | `argocd app wait reloader` |

---

## Cluster Management

| Command | Description | Example |
|---------|------------|---------|
| `argocd cluster list` | List all connected clusters in ArgoCD. | `argocd cluster list` |
| `argocd cluster add <context>` | Add a new Kubernetes cluster to ArgoCD. | `argocd cluster add my-cluster` |
| `argocd cluster remove <context>` | Remove a cluster from ArgoCD. | `argocd cluster remove my-cluster` |

---

## Project Management

| Command | Description | Example |
|---------|------------|---------|
| `argocd proj list` | List all ArgoCD projects. | `argocd proj list` |
| `argocd proj create <project-name>` | Create a new ArgoCD project. | `argocd proj create dev-project` |
| `argocd proj delete <project-name>` | Delete an ArgoCD project. | `argocd proj delete dev-project` |

---

## Repository Management

| Command | Description | Example |
|---------|------------|---------|
| `argocd repo list` | List all configured Git repositories. | `argocd repo list` |
| `argocd repo add <repo-url>` | Add a new Git repository to ArgoCD. | `argocd repo add https://github.com/example/repo.git` |
| `argocd repo remove <repo-url>` | Remove a Git repository from ArgoCD. | `argocd repo remove https://github.com/example/repo.git` |

---

## User & Access Control

| Command | Description | Example |
|---------|------------|---------|
| `argocd account list` | List all ArgoCD user accounts. | `argocd account list` |
| `argocd account get-user-info` | Get information about the currently authenticated user. | `argocd account get-user-info` |
| `argocd account update-password` | Update the password for the current user. | `argocd account update-password` |
| `argocd account update-password --account <username>` | Update the password for a specific user (Admin-only). | `argocd account update-password --account admin` |
| `argocd account enable --account <username>` | Enable a user account. | `argocd account enable --account devuser` |
| `argocd account disable --account <username>` | Disable a user account. | `argocd account disable --account devuser` |
| `argocd account can-i <action> <resource>` | Check if a user has permission to perform an action on a resource. | `argocd account can-i get applications` |

---

## Role-Based Access Control (RBAC)
ArgoCD uses RBAC policies to manage user permissions. The RBAC settings are defined in the `argocd-rbac-cm` ConfigMap.

### Check Current RBAC Policies:
```sh
kubectl get configmap argocd-rbac-cm -n argocd -o yaml
```

### Grant Read-Only Access to a User:
1. Edit the RBAC ConfigMap:
   ```sh
   kubectl edit configmap argocd-rbac-cm -n argocd
   ```
2. Add the following role:
   ```yaml
   policy.csv: |
     p, devuser, applications, get, */*, allow
   ```

### Assign Admin Privileges:
```yaml
policy.csv: |
  g, devuser, role:admin
```
---