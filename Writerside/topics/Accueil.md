# Projet 4KUBE

Documentation du projet 4KUBE, se référer aux sous-parties pour plus de détails.


Création du namespace fleetman
```bash
kubectl create namespace fleetman
```
Ordre d'installation des fichiers yaml

1. Déployement des volumes persistants
```bash
kubectl apply -f mongo-data-pv.yaml
kubectl apply -f mongo-data-pvc.yaml

```
2. Déployement de la base de données MongoDB
```bash
kubectl apply -f mongo.yaml
```
3. Déployement des déploiements et services
```bash
kubectl apply -f fleetman-webapp.yaml
kubectl apply -f fleetman-api.yaml
kubectl apply -f fleetman-positions.yaml
kubectl apply -f fleetman-vehicles.yaml
kubectl apply -f fleetman-vehicles-positions.yaml
```

## Accès à l'application
```bash
minikube service -n fleetman fleetman-webapp
```
