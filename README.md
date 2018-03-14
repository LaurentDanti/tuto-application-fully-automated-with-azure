# [FR] [Tuto application totalement automatisée avec Azure Powershell ARM DSC]

## Description
Ce tuto a pour but de vous aider sur de l'infra as code via powershell, Azure, Desired States Configuration (DSC)
J'ai choisi l'installation de la solution Neo4j car c'est une application plutot standard a installer sur une VM (exe appli, jdk)
La solution neo4j utilisé est deja disponible dans [azure]( https://neo4j.com/blog/deploy-neo4j-microsoft-azure-part-2/)
mais l'idée était de vous montrer comment déployer un soft dans une VM Azure via powershell et DSC.

## Contenu 
Ce tutorial permet de déployer une application IAAS de bout en bout via Azure

* PART 1 Infrastructure : Déploiement de l'insfrastructure réseau
    * Boucle object réseau pour fichier ARM
    * Passage d'un object json dans un fichier ARM
* PART 2 Misc : Création d'un automation account, storage account et upload de fichier dans storage account
* PART 3 Configuration DSC : Installation d'un neo4j via DSC
    * Configuration DSC nodes avec credential dans Azure automation
    * Download de fichier depuis storage account Azure
    * Dépendance entre resource pour installation séquencé de multinode
* PART 4 Keyvault et ARM application : Création du RG pour l'application
    * Set de password dans Keyvault
    * ARM avec boucle sur resource pour  création multiple vm
    * Creation du loadbalancer avec les nodes
* PART 5 Register DSC configuration des nodes : Application de la configuration sur les nodes
    * Passage de configuration data vers la configuration DSC
    * Upload de module powershell vers automation 
    * Register de la configuration sur les multinodes avec passage des Credential
    * Test Pester via loadbalancer
* PART 6 webapp maintenance : Page de maintenance a activer si Neo4j fonctionne pas
    * push de page de maintenance de github vers azure web application
* PART 7 trafficmanager : Bascule vers page de maintenance si Neo4j ne répond pas
    * monitoring HTTP 
    * bascule du loadbalancer en cas de ko vers la page de maintenance


## Prerequis
- avoir une souscription et un compte azure
- download les fichiers ci-dessous dans C:\temp
    - https://neo4j.com/download-thanks/?edition=community&release=3.3.1&flavour=winzip&_ga=2.211610133.1220746051.1514542518-151404295.1514542518
    - http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
- Cloner le repository de la page de maintenance 

        cd C:\votreDossier
        git clone https://github.com/LaurentSwiss/Web-Maintenance-Page Web-Maintenance-Page

## Run

Démarrer le déploiement :

        .\start.ps1

Au fil du déploiement des informations s'affiche sur des vérification a faire dans Azure afin de vous faire découvrir


## Glossaire
- [INFO] : informe sur le déploiement
- [TODO] : Tache a faire : récupération de la partie page de maintenance et push vers votre webappmaintenance
- [TUTO] : check point pour vous faire manipuler sur ce tutorial

--------------

# [ENG] [Tuto Application fully automated with Azure Powershell ARM DSC]

## Description
This tutorial help you to do Infrastructure as Code with powershell, Azure, Desired States Configuration (DSC).
I choose neo4j solution because it's an standard soft to install on a vm (exe appli, jdk).
This solution is already available on [azure]( https://neo4j.com/blog/deploy-neo4j-microsoft-azure-part-2/)
but the deal is to show you how to deploy a software on a Azure VM with powershell dans DSC.

## Content 
This tutorial deploy an application IAAS from start to end with Azure.

* PART 1 Infrastructure : Deploy network infrastructure
    * Loop on network object for ARM file
    * Give json object to ARM file
* PART 2 Misc : Create automation account, storage account and upload file to storage account
* PART 3 DSC Configuration : deploying neo4j with DSC
    * DSC nodes Configuration using credential in Azure automation
    * Download files from Azure storage account
    * Dependances between resource and nodes
* PART 4 Keyvault and ARM application : create RG for application
    * Set password in Keyvault
    * ARM with loop on resource to create multinode vm
    * Create loadbalancer with nodes
* PART 5 Register DSC node configuration  : Apply configuration to nodes
    * Follow the configuration data to the DSC configuration
    * Upload module powershell to azure automation 
    * Register the configuration to multi nodes with credential
    * Pester test of the deployment
* PART 6 webapp maintenance : Maintenance web page
    * push web page from github to azure web application
* PART 7 trafficmanager : siwth to maintenance web page if Neo4j doesn't work
    * monitoring HTTP 
    * switch from loadbalancer to maintenance page


## Before
- subscription azure and account
- downloads files below in C:\temp
    - https://neo4j.com/download-thanks/?edition=community&release=3.3.1&flavour=winzip&_ga=2.211610133.1220746051.1514542518-151404295.1514542518
    - http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
- Repository clone of maintenance webpage 

        cd C:\yourDir
        git clone https://github.com/LaurentSwiss/Web-Maintenance-Page Web-Maintenance-Page

## Run

Start deploying :

        .\start.ps1

A long the running you will have some checkpoint to check what is done and what to do to discover Azure 


## Dictionnary
- [INFO] : information 
- [TODO] : task to do : one thing to do get the maintenance web page and push to azure
- [TUTO] : check point

