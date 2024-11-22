@echo off
REM Script pour déployer tous les services Kubernetes

echo Deploiement en cours...

REM Naviguer vers le répertoire contenant les volumes
cd .\volume\

echo Creation du pv et pvc pour MongoDB...
kubectl apply -f mongo-data-pv.yaml
kubectl apply -f mongo-data-pvc.yaml

REM Navigation vers le répertoire contenant les deployments
cd ..\deployment\

REM Appliquer les fichiers deploiements YAML
echo Application des fichiers de deploiement...
kubectl apply -f fleetman-mongo-deployment.yaml
kubectl apply -f fleetman-api-gateway-deployment.yaml
kubectl apply -f fleetman-position-simulator-deployment.yaml
kubectl apply -f fleetman-position-tracker-deployment.yaml
kubectl apply -f fleetman-queue-deployment.yaml
kubectl apply -f fleetman-web-app-deployment.yaml

REM Navigation vers le répertoire contenant les services
cd ..\service\

REM Appliquer les fichiers services YAML
echo Application des fichiers de service...
kubectl apply -f fleetman-mongo-service.yaml
kubectl apply -f fleetman-api-gateway-service.yaml
kubectl apply -f fleetman-position-simulator-service.yaml
kubectl apply -f fleetman-position-tracker-service.yaml
kubectl apply -f fleetman-queue-service.yaml
kubectl apply -f fleetman-web-app-service.yaml

REM Affichage des services
echo Services deployes...
kubectl get services 

REM Affichage des deploiements
echo Deploiements deployes...
kubectl get deployments


echo Deploiement termine !
pause
