# Oracle Database 11.2 Standard Edition Software

## Content

Dockerfile including scripts to build a base image containing the following:

* Oracle Linux Server 7-slim
* Oracle Database 11.2.0.4.0 Standard Edition software installation, including
  * OPatch 11.2.0.3.20 (patch 6880880)

The purpose of this Docker image is to provide all software components to fully automate the creation of additional Docker images.

This Docker image is not designed to create working Docker containers.

The intended use is for other Docker images such [Oracle Database 11.2.0.4](https://github.com/SP-SuperPoney/docker-oracle/tree/master/OracleDatabase).

Due to [OTN Developer License Terms](http://www.oracle.com/technetwork/licenses/standard-license-152015.html) I cannot make this image available on a public Docker registry.

## Environment Variable

The following environment variable values have been used for this image:

Environment variable | Value
-------------------- | -------------
ORACLE_BASE | ```/u01/app/oracle```
ORACLE_HOME | ```/u01/app/oracle/product/11.2.0/dbhome```
ORACLE_ASSETS | ```http://jxt-dev-pgsql.juxta.fr/oracle-assets```
