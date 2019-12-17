# docker-oracle

## Introduction
docker-oracle provides Dockerfiles to build Oracle Database Docker images.

Due to [OTN Developer License Terms](http://www.oracle.com/technetwork/licenses/standard-license-152015.html) I cannot make the resulting images available on a public Docker registry.

## Components

| Component                     | Version  | Docker Image |
| ----------------------------- | -------- | ------------ |
| [Oracle Database Software](https://github.com/SP-SuperPoney/docker-oracle/tree/master/OracleDatabaseSoftware/)  | [11.2.0.4](https://github.com/SP-SuperPoney/docker-oracle/tree/master/OracleDatabaseSoftware/) | oracle/11.2.0.4:base 
| [Oracle Database](https://github.com/SP-SuperPoney/docker-oracle/tree/master/OracleDatabase) | [11.2.0.4](https://github.com/SP-SuperPoney/docker-oracle/tree/master/OracleDatabase) | oracle/11.2.0.4:db |

## License

docker-oracle is licensed under the Apache License, Version 2.0. You may obtain a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>.

See [OTN Developer License Terms](http://www.oracle.com/technetwork/licenses/standard-license-152015.html) and [Oracle Database Licensing Information User Manual](https://docs.oracle.com/database/122/DBLIC/Licensing-Information.htm#DBLIC-GUID-B6113390-9586-46D7-9008-DCC9EDA45AB4) regarding Oracle Database licenses.