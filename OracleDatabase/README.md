# Oracle Database 11.2 Standard Edition

## Content

Dockerfile including scripts to build an image containing the following:

* Oracle Linux 7-slim
* Oracle Database 11.2.0.4 Standard Edition

Due to [OTN Developer License Terms](http://www.oracle.com/technetwork/licenses/standard-license-152015.html) I cannot make this image available on a public Docker registry.

## Installation

### Using Default Settings (recommended)

Complete the following steps to create a new container:

1. Create the container

		docker run -v oracle:/u02 -it -p 1158:1158 -p 8081:8081 -p 1521:1521 -h oracle --name oracle oracle/11.2.0.4:db



2. wait around **20 minutes** until the Oracle database instance is created. Check logs with ```docker logs -f -t oracle```. The container is ready to use when the last line in the log is ```Database ready to use. Enjoy! ;-)```. The container stops if an error occurs. Check the logs to determine how to proceed.

Feel free to stop the docker container after a successful installation with ```docker stop -t 60 oracle```. The container should shutdown the database gracefully within the given 60 seconds and persist the data fully (ready for backup). Next time you start the container using ```docker start oracle``` the database will start up.


### Options

#### Environment Variables

You may set the environment variables in the docker run statement to configure the container setup process. The following table lists all environment variables with its default values:

Environment variable | Default value | Comments
-------------------- | ------------- | --------
DBCONTROL | ```true``` | Set to ```false``` if you do not want to use Enterprise Manger Database Control.
DBCA\_TOTAL\_MEMORY | ```2048```| Memory in kilobytes for the Database Creation Assistent.
GDBNAME | ```odb.docker``` | Global database name, used by DBCA
ORACLE_SID | ```odb```| Oracle System Identifier
SERVICE_NAME | ```odb.docker``` | Oracle Service Name (for the container database)
PASS | ```oracle```| Password for SYS, SYSTEM

Here's an example run call amending the PASS environment variable skip DBCONTROL installation:

```
docker run -e PASS=manager -e DBCONTROL=false -d -p 1158:1158 -p 1521:1521 -h oracle --name oracle oracle/11.2.0.4:db
```

#### Volumes

The image defines a volume for ```/u02```. You may map this volume to a storage solution of your choice. Here's an example using a named volume ```oraclevolume```:

```
docker run -v oraclevolume:/u02 -d -p 1158:1158 -p 8081:8081 -p 1521:1521 -h oracle --name oracle oracle/11.2.0.4:db
```

Here's an example mapping the local directory ```$HOME/docker/odb/u02``` to ```/u02```.

```
docker run -v $HOME/docker/odb/u02:/u02 -d -p 1158:1158 -p 1521:1521 -h oracle --name oracle oracle/11.2.0.4:db
```

**Please note**: Volumes mapped to local directories are not stable, at least not in Docker for Mac 1.12.0. E.g. creating a database may never finish. So I recommend not to use local mapped directories for the time being. Alternatively you may use a volume plugin. A comprehensive list of volume plugins is listed [here](https://docs.docker.com/engine/extend/plugins/#volume-plugins).

#### Change Timezone

The default timezone of the container is "Central European Time (CET)". To query the available timezones run:

```
docker exec oracle ls -RC /usr/share/zoneinfo
```

To change the timezone to "Eastern Time" run the following two commands:

```
docker exec oracle unlink /etc/localtime
docker exec oracle ln -s /usr/share/zoneinfo/America/New_York /etc/localtime
```

Restart your container to ensure the new setting take effect.

```
docker restart -t 60 oracle
```

## Access To Database Services

### Enterprise Manager Database Control

[http://localhost:1158/em/](http://localhost:1158/em/)

User | Password
-------- | -----
system | oracle
sys | oracle


### Database Connections

To access the database e.g. from SQL Developer you configure the following properties:

Property | Value
-------- | -----
Hostname | localhost
Port | 1521
SID | oracle
Service | oracle.docker

The configured user with their credentials are:

User | Password
-------- | -----
system | oracle
sys | oracle

Use the following connect string to connect as scott via SQL*Plus or SQLcl: ```sys/oracle@localhost/oracle.docker as sysdba```

## TODO Backup

Complete the following steps to backup the data volume:

1. Stop the container with

		docker stop -t 30 oracle

2. Backup the data volume to a compressed file ```oracle.tar.gz``` in the current directory with a little help from the ubuntu image

		docker run --rm --volumes-from oracle -v $(pwd):/backup ubuntu tar czvf /backup/oracle.tar.gz /u02

3. Restart the container

		docker start oracle

## Restore

Complete the following steps to restore an image from scratch. There are other ways, but this procedure is also applicable to restore a database on another machine:

1. Stop the container with

		docker stop -t 30 oracle

2. Remove the container with its associated volume

		docker rm -v oracle

3. Remove unreferenced volumes, e.g. explicitly created volumes by previous restores

		docker volume ls -qf dangling=true | xargs docker volume rm

4. Create an empty data volume named ```oracle```

		docker volume create --name oracle

5. Populate data volume ```oracle``` with backup from file ```oracle.tar.gz``` with a little help from the ubuntu image

		docker run --rm -v oracle:/u02 -v $(pwd):/backup ubuntu tar xvpfz /backup/oracle.tar.gz -C /

6. Create the container using the ```oracle```volume

		docker run -v oracle:/u02 -p 1158:1158 -p 8081:8081 -p 1521:1521 -h oracle --name oracle oracle/11.2.0.4:db

7. Check log of ```oracle``` container

		docker logs oracle

	The end of the log should look as follows:

		Reuse existing database.

		(...)

		Database ready to use. Enjoy! ;-)

## Credits
This Dockerfile is based on the following work:

- Philipp Salvisberg [docker-odb](https://github.com/PhilippSalvisberg)
- Maksym Bilenko's GitHub project [sath89/docker-oracle-12c](https://github.com/MaksymBilenko/docker-oracle-12c)
- Frits Hoogland's blog post [Installing the Oracle database in docker](https://fritshoogland.wordpress.com/2015/08/11/installing-the-oracle-database-in-docker/)
