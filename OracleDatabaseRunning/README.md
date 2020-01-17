# Oracle Database 11.2 Standard Edition

## Content

Dockerfile including scripts to build an image containing the following:

* Oracle Linux 7-slim
* **Up and Running** Oracle Database 11.2.0.4 Standard Edition

Due to [OTN Developer License Terms](http://www.oracle.com/technetwork/licenses/standard-license-152015.html) I cannot make this image available on a public Docker registry.

## Installation

### Using Default Settings (recommended)

Complete the following steps to create a new container:

1. Pull the base image ```oracle-db``` from Juxta custom repository. Add the custom ```jxt-dev-pgsql.juxta.fr:5000``` insecure URL in your ```deamon.json``` file (or for Docker Desktop : "settings -> deamon") :

  /etc/docker/daemon.json
  C:\ProgramData\docker\config\daemon.json

  change ```insecure-registries``` :

  "insecure-registries": [
   "jxt-dev-pgsql.juxta.fr:5000"
  ],

 Restart docker then finally pull the image :

  docker pull jxt-dev-pgsql.juxta.fr:5000/oracle-db

2. Create the base container with or without import using the base image ```oracle-db``` environment parameters (see ```Options``` section below). IE:

  docker run -v juxta:/u01 -it -p 1158:1158 -p 1521:1521 -h juxta --name juxta --env DBCONTROL=false --env GDBNAME=juxta.docker --env ORACLE_SID=juxta --env SERVICE_NAME=juxta.docker --env PASS=sys --env DUMPFILE='' jxt-dev-pgsql.juxta.fr:5000/oracle-db

3. wait around **20 minutes** until the Oracle database instance is created. Check logs with ```docker logs -f -t oracle```. The container is ready to use when the last line in the log is ```Database ready to use. Enjoy! ;-)```. The container stops if an error occurs. Check the logs to determine how to proceed.

4. get the container id : ```docker ps```

5. [docker commit](https://docs.docker.com/engine/reference/commandline/commit/) the running container to a fully re-usable one:

  docker commit --message "Running JUXTA instance"--change='CMD ["apachectl", "-DFOREGROUND"]' --change "EXPOSE 80" container_id  oracle/11.2.0.4:juxta

  ? --change='CMD ["apachectl", "-DFOREGROUND"]'  
  ? --change "EXPOSE 80" container_id

Feel free to stop the docker container after a successful installation with ```docker stop -t 60 juxta```. The container should shutdown the database gracefully within the given 60 seconds and persist the data fully (ready for backup).

TODO : Next time you start the container using ```docker start oracle``` the database will start up.


# Options

#### Environment Variables

You may set the environment variables in the docker run statement to configure the container setup process. The following table lists all environment variables with its default values:

Environment variable | Default value | Comments
-------------------- | ------------- | --------
DBCONTROL | ```true``` | Set to ```false``` if you do not want to use Enterprise Manger Database Control.
DBCA\_TOTAL\_MEMORY | ```2048```| Memory in kilobytes for the Database Creation Assistent.
GDBNAME | ```oracle.docker``` | Global database name, used by DBCA
ORACLE_SID | ```oracle```| Oracle System Identifier
SERVICE_NAME | ```oracle.docker``` | Oracle Service Name (for the container database)
PASS | ```oracle```| Password for SYS, SYSTEM
DUMPFILE | ```expdp.dmp```| dump file to import after database creation
ORACLE\_ASSETS | [http://jxt-dev-pgsql.juxta.fr/oracle-assets]| assets base root retrieved using [wget](https://www.gnu.org/software/wget/manual/html_node/index.html).
REMOTE\_ROOT | ```expdp.dmp```| dump file to import after database creation
RUN\_SCRIPTS\_IN\_SCHEMA | FSV| In behalf of which schema the scripts in the ```SCRIPTS_ROOT``` folder are executed.
SCRIPTS\_ROOT | /patch/fsv| Script's root folder derived from ```ORACLE_ASSETS``` base. IE: if ```ORACLE_ASSETS``` equals ftp://test.org and ```SCRIPTS_ROOT``` equals ```/patch```, all scripts located in ftp://test.org/patch will be unzipped (if detected as a compressed file) then executed.


## Credits
This Dockerfile is based on the following work:

- Philipp Salvisberg [docker-odb](https://github.com/PhilippSalvisberg)
- Offical Oracle docker-images' GitHub project [oracle/docker-images](https://github.com/oracle/docker-images)
