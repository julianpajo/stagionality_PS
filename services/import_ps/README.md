#Readme
Update readme version during release phase

## Run import in IntelliJ IDE

Edit configurations for src[bootRun] 
- VM options: -Xms1g -Xmx1g
- Arguments: -Dspring.config.additional-location=/home/vagrant/Desktop/rheticus/rheticus_import_ps/config_examples/
Note: change the "Arguments" and "VM options" in the proper way based on your system

Edit the application-default.properties setting the correct database and other parameters

## Run import container
    docker run -d --name pkt284_rheticus_import_ps --mount type=bind,source=/home/dockermanager/shared_data/production/shapefiles/import_config/,target=/usr/local/rheticus_import_ps_config/,readonly --mount type=bind,source=/home/dockermanager/shared_data/production/shapefiles/,target=/home/shapefiles_uploader/,readonly dockerhub.planetek.it/pkt284_rheticus_import_ps:<tag_immagine>

###Prerequisites for dockerization
* git
* Docker version>=17.12.1~ce-0~ubuntu
* Logged in dockerhub.planetek.it to push the images

###Examples: prepare the docker image

######Read the help
    ./build.sh -h to read the help

######Build branch "develop" and tag the docker image as "dev"
    ./build.sh dev -b develop

######Build local branch using as docker base image the one tagged as "develop" and tag the built image as "develop"
    ./build.sh develop -b develop -l

######Build local branch using as docker base image the one tagged as "master" and tag the built image as "v1.0.0"
    ./build.sh v1.0.0 -b master -l

######Build tag "v1.0.0" using as docker base image the one tagged as "master" and tag the built image as "v1.0.0"
    ./build.sh v1.0.0 -t v1.0.0
