## **Introduction du sujet** 

Comprendre les concepts de base de Kubernetes. 

Installer et configurer un cluster Kubernetes. 

Déployer et gérer des applications sur Kubernetes. 

Utiliser des services, des volumes, des ConfigMaps, et des Secrets. Superviser et gérer un cluster Kubernetes. 

Comprendre et utiliser Helm pour déployer des applications. 

## **PS : Merci de lire complètement cet ordre de mission avant de commencer !** 

# **Et Pensez à documenter les commandes et étapes que vous suivez tout au** 

**long de la mission** 

## **Job 01** 

Vous devez faire 3 VM Debian ( sans GUI )  , une par étudiant ( kubes-01.local , kubes-02.local, kubes-03.local ) . Installer K3S sur chaque VM. 

## **Job 02** 

Déployer des applications conteneurisées sur chaque VM ( nginx , apache , mysql/mariadb ) 

## **Job 03** 

Maintenant vous allez créer le cluster K3s, choisir une VM qui sera le « master », les 2 autres seront les « workers » . Vérifier vos applications installées après  la mise en cluster. 

## **Job 04** 

Supprimer toutes les applications,  et les réinstaller en activant la haute disponibilité (HA) ( replicas ). 

Tester la HA, en arrêtant un worker et vérifier  toutes les applications sont redéployées 

## **Job 05** 

Les **Volumes** permettent à vos applications de conserver des données même 

après le redémarrage des pods. 

Mettre en place la gestion du stockage persistant , pour nginx et Mariadb 

## **Job 06** 

Gérer la configuration des applications avec ConfigMaps 

## **Job 07** 

Données sensibles « Secret » 

A activer pour le conteneur Mariadb 

## **Job 08** 

Mettre en place Les Règles RBAC 

## **Job 09** 

Installer et configurer Helm sur un cluster Kubernetes. 

Rechercher, installer, personnaliser, mettre à jour et désinstaller des applications à l'aide de Helm. 

Gérer des applications à l'aide de charts Helm, tout en apprenant à utiliser des configurations personnalisées. 

## **Pour aller plus loin** 

comparer k3s avec docker , docker swarm . Avantages , inconvénients 

Dans quel cas l’utiliser 

## **Rendu** 

**L’évaluation se fera sous forme de présentation avec support à l’équipe pédagogique.** 

## **Compétences visées** 

➔ Administrer et sécuriser les infrastructures systèmes 

➔ Administrer et sécuriser les infrastructures virtualisées 

➔ Mettre en œuvre et optimiser la supervision des infrastructures 

## **Base de connaissances** 

## ➔ K3S 

## ➔ Kubernetes 

## ➔ Helm 

