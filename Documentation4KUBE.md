# DOCUMENTATION 4KUBE

## Introduction

Documentation du projet 4KUBE, qui consiste à déployer une application distribuée basée sur des microservices avec Kubernetes. Les services de l'application sont les suivants :

- fleetman-position-simulator : une application Spring Boot émettant en continu des positions fictives de véhicules.
- fleetman-queue : une queue Apache ActiveMQ qui reçoit puis transmet ces positions.
- fleetman-position-tracker : une application Spring Boot qui consomme ces positions reçues pour les stocker dans une base de données MongoDB. Elles sont ensuite disponibles via une API RESTful.
- fleetman-mongo : instance de la base de données MongoDB.
- fleetman-api-gateway : une API Gateway servant de point d'entrée pour l'application web
- fleetman-web-app : l'application web présentée précédemment.

---

## Sommaire

[1. Configuration du Cluster Kubernetes (1 Master, 2 Workers) et installation des packages nécessaires.](#1-configuration-du-cluster-kubernetes)

[2. Création des fichiers YAML pour les deployments, services et volumes.](#2-déploiement-de-lapplication)

---

## Étapes de mise en œuvre

### 1. Configuration du Cluster Kubernetes

Sur chaque nœud (master et workers) :

#### 1.1 Configuration DNS

Ajout de l'adresse IP et du nom de chaque nœud dans le fichier `/etc/hosts` :

```bash
$ sudo nano /etc/hosts
```

```plaintext
    192.168.99.152 debian-master
    192.168.99.153 debian-worker1
    192.168.99.154 debian-worker2
```

#### 1.2 Désactivation du Swap

Pour éviter les problèmes de performance :

```bash
$ sudo swapoff -a
$ sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

#### 1.3 Emulation de l'architecture ARM64 sur x86_64

```bash
apt-get install qemu-system qemu-user  qemu-user-static
```

#### 1.4 Installation de conteneurd

```bash
$ cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

$ sudo modprobe overlay
$ sudo modprobe br_netfilter

$ cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

$ sudo sysctl --system

$ sudo apt  update
$ sudo apt -y install containerd
```

Puis, configuration de containerd pour qu'il puisse fonctionner avec Kubernetes :

```bash
$ containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
$ sudo systemctl restart containerd
$ sudo systemctl enable containerd
```

#### 1.5 Installation de kubelet, kubeadm et kubectl

Installation de `kubeadm`, `kubectl` et `kubelet`

```bash
$ sudo apt update
$ sudo apt install -y apt-transport-https ca-certificates curl gnupg
$ curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
$ echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
$ sudo apt update
$ sudo apt install -y kubelet kubeadm kubectl
$ sudo apt-mark hold kubelet kubeadm kubectl
```

#### 1.6 Initialisation du Cluster

**Sur le nœud master** :
initialisation le cluster avec `kubeadm` :

```bash
$ sudo kubeadm init --control-plane-endpoint=k8s-master
```

Dans la sortie de la commande, récuperation de la commande pour rejoindre le master depuis les noeuds worker.

Copie du fichier de configuration du cluster :

```bash
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

**Sur les nœuds worker** :
Rejoindre le cluster avec la commande récupérée lors de l'initialisation du cluster :

```bash
$ sudo kubeadm join k8s-master:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

#### 1.7 Installation du Plugin Réseau

Utilisation de **Calico** comme plugin réseau :

```bash
$ kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
```

---

### 2. Déploiement de l'Application

#### 2.1 Création des Manifests

Création les fichiers YAML pour chaque service (MongoDB, API, Web App).
Se réferer aux fichiers de configuration fournis.
Deployments :

- fleetman-api-gateway-deployment.yaml
- fleetman-mongo-statefulset-deployment.yaml
- fleetman-position-simulator-deployment.yaml
- fleetman-position-tracker-deployment.yaml
- fleetman-queue-deployment.yaml
- fleetman-web-app-deployment.yaml

Services :

- fleetman-api-gateway-service.yaml
- fleetman-mongo-service.yaml
- fleetman-position-simulator-service.yaml
- fleetman-position-tracker-service.yaml
- fleetman-queue-service.yaml
- fleetman-web-app-service.yaml

Stockage :

on a utilisé un statefulset pour MongoDB. Son avantage principal est que le StatefulSet gère les pods avec un état, ce qui permet de maintenir les données persistantes dans des volumes liés.

On a créé aussi un StorageClass personnalisé vous permet d'avoir une gestion dynamique des volumes persistants. Le StorageClass personnalisé (mongo-classname) permet de spécifier des volumes persistants pour chaque réplique de MongoDB, garantissant que les données de chaque réplique sont correctement stockées et persistées sur des disques locaux.
En associant un StorageClass à un volumeClaimTemplate, on indique à Kubernetes de créer et d'attacher des volumes sans avoir à créer manuellement des PersistentVolumes (PV), ni de PersistentVolumeClaims (PVC).

Avec ce système, on évite la gestion manuelle des PersistentVolumes (PV), car Kubernetes s'occupe de la création des volumes selon les paramètres du StorageClass.

Application des fichiers de configuration :

```bash
$ kubectl apply -f ./deployment
```

---

#### 2.2 Vérification des Déploiements

Vérification de l'état de pods et services :

```bash
$ kubectl get pods
$ kubectl get services
```

Accès à l'application web depuis un navigateur :

```plaintext
http://<adresse_ip_worker>:30080
```

## Conclusion

Le projet 4KUBE a permis de déployer une application distribuée basée sur des microservices avec Kubernetes. Cela se rapproche d'une infrastructure d'entreprise, avec des services déployés sur un cluster Kubernetes. Des améliorations pourront être apportées par la suite pour automatiser le déploiement, ajouter un système de monitoring, mettre en place un pipeline CI/CD et renforcer la sécurité.
