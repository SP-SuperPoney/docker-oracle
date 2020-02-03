# Oracle Database on Docker
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle Database please see the [Oracle Database Online Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/index.html).

## How to build and run
This project offers sample Dockerfiles for:
 * Oracle Database 11g Release 2 (11.2.0.4) Standard Edition.

To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

### Building Oracle Database Docker Install Images
**IMPORTANT:** You will have to provide the installation binaries of Oracle Database and put them into the `dockerfiles/<version>` folder. You only need to provide the binaries for the edition you are going to install. The binaries can be downloaded from the [Oracle Technology Network](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html), make sure you use the linux link: *Linux x86-64*. The needed file is named *linuxx64_<version>_database.zip*. You also have to make sure to have internet connectivity for yum. Note that you must not uncompress the binaries. The script will handle that for you and fail if you uncompress them manually!

Before you build the image make sure that you have provided the installation binaries and put them into the right folder. Once you have chosen which edition and version you want to build an image of, go into the **dockerfiles** folder and run the **buildDockerImage.sh** script:

    [oracle@localhost dockerfiles]$ ./buildDockerImage.sh -h
    
    Usage: buildDockerImage.sh [-o] [-d] [-t target] [Docker build option][Docker build option]
    Builds a Docker Image for Oracle Database.
    
    Parameters:
    -d: debug mode, do not remove dangling images (intermitten images with tag <none>)
    -t: target a specific intermitten images (base, builder, database)
    -o: passes on Docker build option
    -h: usage

**IMPORTANT:** The resulting images will be an image with the Oracle binaries installed. On first startup of the container a new database will be created, the following lines highlight when the database is ready to be used:

    #########################
	DATABASE IS READY TO USE!
	#########################

You may extend the image with your own Dockerfile and create the users and tablespaces that you may need.

The character set for the database is set during creating of the database. You can set the character set during the first run of your container and may keep separate folders containing different tablespaces with different character sets.

### Running Oracle Database in a Docker container

#### Running Oracle Database 11gR2 Standard Edition in a Docker container

Windows path :

	docker run -d -p 1158:1158/tcp -p 1521:1521/tcp -e ORACLE_PWD=juxta -v ${PWD}\scripts\setup:/opt/oracle/scripts/setup juxta/oracle:11.2.0.4-se

Linux path :

	docker run -d -p 1158:1158/tcp -p 1521:1521/tcp -e ORACLE_PWD=juxta -v ${PWD}/scripts/setup:/opt/oracle/scripts/setup juxta/oracle:11.2.0.4-se

Locate id of the dockerized DB:

	docker ps

Wait end of setup optionnaly open bash inside DB container:

	docker logs -f 0f4acaaca803
	docker exec -it 0f4acaaca803 /bin/bash

Start DB terminal:

	sqlplus / as sysdba

Do your configuration tasks inside the container then commit. Example :

	docker commit --author "Eric Clement <eric.clement@juxta.fr>" --message "Empty snapshot" 0f4acaaca803 juxta/oracle:latest

#### Push the commited image to JUXTA's repository:

	docker tag juxta/oracle jxt-dev-pgsql.juxta.fr:5000/oracle
	docker push jxt-dev-pgsql.juxta.fr:5000/oracle

#### Running Oracle Database Enterprise and Standard Edition 2 in a Docker container
To run your Oracle Database Docker image use the **docker run** command as follows:

	docker run --name <container name> \
	-p <host port>:1521 -p <host port>:5500 \
	-e ORACLE_SID=<your SID> \
	-e ORACLE_PWD=<your database passwords> \
	-e ORACLE_CHARACTERSET=<your character set> \
	-v [<host mount point>:]/opt/oracle/oradata \
	juxta/oracle
	
	Parameters:
	   --name:        The name of the container (default: auto generated)
	   -p:            The port mapping of the host port to the container port. 
	                  Two ports are exposed: 1521 (Oracle Listener), 1158 (Enterprise Manager)
	   -e ORACLE_CHARACTERSET:
	                  The character set to use when creating the database (default: WE8MSWIN1252)
	   -v /opt/oracle/oradata
	                  The data volume to use for the database.
	                  Has to be writable by the Unix "oracle" (uid: 54321) user inside the container!
	                  If omitted the database will not be persisted over container recreation.
	   -v /opt/oracle/scripts/startup | ./scripts/startup
	                  Optional: A volume with custom scripts to be run after database startup.
	                  For further details see the "Running scripts after setup and on startup" section below.
	   -v /opt/oracle/scripts/setup | ./scripts/setup
	                  Optional: A volume with custom scripts to be run after database setup.
	                  For further details see the "Running scripts after setup and on startup" section below.

Example, minimal container:

	docker run -d -p 1158:1158 -p 1521:1521 juxta/oracle:latest

With startup scripts:

	docker run -d -p 1521:1521 -v ${PWD}\scripts\startup\test:/opt/oracle/scripts/startup juxta/oracle:latest

	docker run -d -p 1521:1521 -v /mnt/OracleCI:/opt/oracle/scripts/startup juxta/oracle

With volume:

	docker run -d -p 1521:1521 -v /opt/oracle/oradata juxta/oracle:latest

Once the container has been started and the database created you can connect to it just like to any other database (port 1521 must be exposed):

	sqlplus sys/<your password>@//<server>:1521/<your SID> as sysdba
	sqlplus sys/juxta@//jxt-dev-pgsql.juxta.fr:1521/orcl as sysdba


**NOTE**: Mount network share as volume. Oracle user and group id are ```uid=54321,gid=54321``` :

	sudo mount -t cifs -o username=${USER},domain=JUXTA,vers=2.0,uid=54321,gid=54321 //JUXTASTOCKAGE.juxta.fr/juxta/Developpement/OracleCI/impdp /mnt/OracleCI

Use [autofs](https://help.ubuntu.com/community/Autofs) tool to automatically mount a share, even if previoulsy disconnected or unmounted.

## Enterprise Manager (EM)

The Oracle Database inside the container also has Oracle Enterprise Manager Express configured. ```DB_CONTROL``` must be set to ```true``` whil building the base image. To access OEM Express, start your browser and follow the URL:

	https://localhost:1158/em/

**NOTE**: Oracle Database bypasses file system level caching for some of the files by using the `O_DIRECT` flag. It is not advised to run the container on a file system that does not support the `O_DIRECT` flag.

#### Changing the admin accounts passwords

On the first startup of the container a random password will be generated for the database if not provided. You can find this password in the output line:  
	
	ORACLE PASSWORD FOR SYS, SYSTEM :

The password for those accounts can be changed via the **docker exec** command. **Note**, the container has to be running:

	docker exec <container name> ./setPassword.sh <your password>

### Running scripts after setup and on startup
The docker images can be configured to run scripts after setup and on startup. Currently `sh` and `sql` extensions are supported.
For post-setup scripts just mount the volume `/opt/oracle/scripts/setup` or extend the image to include scripts in this directory.
For post-startup scripts just mount the volume `/opt/oracle/scripts/startup` or extend the image to include scripts in this directory.
Both of those locations are also represented under the symbolic link `/docker-entrypoint-initdb.d`. This is done to provide
synergy with other database Docker images. The user is free to decide whether to put the setup and startup scripts
under `/opt/oracle/scripts` or `/docker-entrypoint-initdb.d`.

After the database is setup and/or started the scripts in those folders will be executed against the database in the container.
SQL scripts will be executed as sysdba, shell scripts will be executed as the current user. To ensure proper order it is
recommended to prefix your scripts with a number. For example `01_users.sql`, `02_permissions.sql`, etc.

**Note:** The startup scripts will also be executed after the first time database setup is complete.  

The example below mounts the local directory myScripts to `/opt/oracle/myScripts` which is then searched for custom startup scripts:

    docker run --name oracle-se -p 1521:1521 -v /home/oracle/myScripts:/opt/oracle/scripts/startup -v /home/oracle/oradata:/opt/oracle/oradata juxta/oracle
    
## Known issues
* The [`overlay` storage driver](https://docs.docker.com/engine/userguide/storagedriver/selectadriver/) on CentOS has proven to run into Docker bug #25409. We recommend using `btrfs` or `overlay2` instead. For more details see issue #317.
