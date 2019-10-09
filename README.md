# Common Development Environment

This repository contains the code for a development environment that can be used across teams and projects. It is designed to allow collections of applications to be loaded from a separate configuration repository, and maximising consistency between them.

It provides several hooks for applications to take advantage of, including:

* Docker container creation and launching via docker-compose
* Automatic creation of commodity systems such as Postgres or Elasticsearch (with further hooks to allow for initial provisoning such as running SQL, Alembic DB upgrades or Elasticsearch index creation)

## Getting started

### Prerequisites

#### Recommended setup

* **Docker and Docker Compose**. Exactly what toolset you use depends on your OS and personal preferences, but recommended are:
  * [Docker For Mac](https://docs.docker.com/docker-for-mac/)
  * [Docker for Windows 10](https://docs.docker.com/docker-for-windows/) (See [the wiki](https://github.com/LandRegistry/common-dev-env/wiki/Windows-setup) for more information on getting a working Windows environment set up)
  * [Docker CE for Linux](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
* **Git**
* **Ruby 2.3+**

#### Alternative setup

* **Vagrant** (v1.9.5+)
* **VirtualBox** (v5.1+)

A Vagrantfile is provided so `vagrant up` will result in a virtual machine containing all the prerequisites from the Recommended setup above. From there, just `vagrant ssh` in and use the dev-env as you would natively.

### Git/SSH

You must ensure the shell you are starting the dev-env from can access all the necessary Git repositories - namely the config repo and the application repos it specifies. If they are to be accessed via SSH, [this wiki page](https://github.com/LandRegistry/common-dev-env/wiki/Git---SSH-setup) has some proven techniques for generating keys and making them available to the shell.

### Controlling the dev-env

To begin:

1. Start Docker.
2. Using Git, clone this repository into a directory of your choice.
3. Open a terminal in that directory, and run `source run.sh up`
4. If this is the first time you are launching the machine you will be prompted for the url of a configuration repository (both SSH or HTTP(S) Git formats will work). Paste it in and press enter.

**TIP:** You can add a # onto the end of the configuration repository location followed by a branch, tag or commit you want to check out, if the default branch is not good enough.

Other `run.sh` parameters are:

* `halt` - stops all containers
* `reload` - stops all containers then rebuilds and restarts them (including running any commodity fragments)
* `destroy` - stops/removes all containers, removes all built images (i.e. leaving any pulled from Docker Hub) and resets all dev-env configuration files.
* `repair` - sets the Docker-compose configuration to use the fragments from applications in _this_ dev-env instance (in case you are switching between several)

## Usage guide

### Configuration Repository

This is a Git repository that must contain a single file  -
`configuration.yml`. The configuration file has an `applications` key that contains a list of the applications that will be running in the dev-env, each specifying the URL of their Git repository (the `repo` key) plus which branch/tag/commit should be initially checked out (the `ref` key). The name of the application should match the repository name so that things dependent on the directory structure like volume mappings in the app's docker-compose-fragment.yml will work correctly.

The application repositories will be pulled and updated on each `up` or `reload`, _unless_ the current checked out branch does not match the one in the configuration. This allows you to create and work in feature branches while remaining in full control of updates and merges.

If you are creating a new app that doesn't have a remote Git repository to clone from yet, you can manually put a directory into `/apps/` and add it to the configuration with the `repo` key set to `none` and no `ref` key.

This file can also optionally contain a `post-up-message` key that provides a message to be displayed after the dev-env has finished starting all applications.

[Example](snippets/configuration.yml)

### Application support

For an application repository to leverage the full power of the dev-env...

Docker containers are used to run all apps. So some files are needed to support that.

##### `/fragments/docker-compose-fragment.yml`

This is used by the environment to construct an application container and then launch it. Standard [Compose file](https://docs.docker.com/compose/compose-file/) structure applies - and all apps must use the same Compose file version (which must be 2) - but some recommendations are:

* Container name and service name should match
* Any ports that need to be accessed from the host machine (as opposed to from other containers) should be mapped
* A `volumes` entry should map the path of the app folder to wherever the image expects source files to be (if they are to be accessed dynamically, and not copied in at image build time)
* If the provided log collator is to be used, then a syslog logging driver needs to be present, forwarding to logstash:25826.
* If you wish to run the container as the host user so you have full access to any files created by the container (this is only a problem on Linux and Windows), environment variables `OUTSIDE_UID` and `OUTSIDE_GID` are provided for use in the fragment as build args (which can then be used in the `Dockerfile` to create a matching user and set them as the container-executor).

Although generally an application should only have itself in it's compose fragment, there is no reason why other containers based on other Docker images cannot also be listed in this file, if they are not provided already by the dev-env.

Note that when including directives such as a Dockerfile build location or host volume mapping for the source code, the Compose context root `.` is considered to be the dev-env's /apps/ folder, not the location of the fragment. Ensure relative paths are set accordingly.

[Example](snippets/docker-compose-fragment.yml)

##### `/fragments/docker-compose-fragment.3.7.yml`

An optional variant of `docker-compose-fragment.yml` with a version of `3.7`. The development environment will select the highest compose file version supplied by all applications in the environment. If all applications supply a `docker-compose-fragment.3.7.yml`, then the environment will use the `3.7` files, otherwise it falls back to the version `2` compose files.

Compose 3.7 support requires Docker engine version 18.06.0 or later.

If the environment cannot identify a universal compose file version, then provisioning will fail.

[Example](snippets/docker-compose-fragment.3.7.yml)

##### `/Dockerfile`

This is a file that defines the application's Docker image. The Compose fragment may point to this file. Extend an existing image and install/set whatever is needed to ensure that containers created from the image will run. See the [Dockerfile reference](https://docs.docker.com/engine/reference/builder/) for more information.

[Example - Python/Flask](snippets/flask_Dockerfile)

[Example - Java](snippets/java_Dockerfile)

##### `/configuration.yml`

This file specifies which commodities the dev-env should create and launch for the application to use. If the commodity must be started before your application, ensure that it is also present in the appropriate section of the `docker-compose-fragment` file (e.g. `depends_on`).

The list of allowable commodity values is:

1. postgres
2. postgres-9.6
3. db2 (**Warning:** source image no longer available on Docker Hub; use db2_community instead)
4. db2_devc (**Warning:** source image deprecated by IBM; use db2_community instead)
5. db2_community
6. elasticsearch
7. elasticsearch5
8. nginx
9. rabbitmq
10. redis
11. swagger
12. wiremock
13. squid
14. auth

* The file may optionally also indicate that one or more services are resource intensive when starting up. The dev env will start those containers seperately - 3 at a time - and wait until each are declared healthy before starting any more. This requires a healthcheck command specified here or in the Dockerfile/docker-compose-fragment (in which case just use 'docker' in this file).
  * If one of these expensive services prefers another one to be considered "healthy" before a startup attempt is made (such as a database, to ensure immediate connectivity and no expensive restarts) then the dependent service can be specified here, with a healthcheck command following the same rules as above.

[Example](snippets/app_configuration.yml)

#### Commodities

Individual commodities may require further files in order to set them up correctly even after being specified in the application's `configuration.yml`, these are detailed below. Note that unless specified, any fragment files will only be run once. This is controlled by a generated `.commodities.yml` file in the root of the this repository, which you can change to allow the files to be read again - useful if you've had to delete and recreate a commodity container.

##### PostgreSQL

**`/fragments/postgres-init-fragment.sql`**

This file contains any one-off SQL to run in Postgres - at the minimum it will normally be creating a database and an application-specific user.

[Example](snippets/postgres-init-fragment.sql)

If you want to spatially enable your database see the following example:

[Example - Spatial](snippets/spatial_postgres-init-fragment.sql)

The default Postgres port 5432 will be available for connections from other containers and on the host. Postgres 9.6 will be exposed on port 5433.

**`/manage.py`**

This is a standard Alembic management file - if it exists, then a database migration will be run on every `up` or `reload`.

##### DB2

`db2_community` (DB2 Community Edition 11.5) is recommended over `db2_devc` (DB2 Developer C 11.0) or `db2` (DB2 Express 10.5)

Note that DB2 Developer C is exposed on the host ports 50001/55001 and DB2 Community on 50002/55002 to avoid port clashes.

**`/fragments/db2-init-fragment.sql`**
**`/fragments/db2-devc-init-fragment.sql`**
**`/fragments/db2-community-init-fragment.sql`**

This file contains any one-off SQL to run in DB2 - at the minimum it will normally be creating a database.

[Example](snippets/db2-community-init-fragment.sql)

##### ElasticSearch

**`/fragments/elasticsearch-fragment.sh`**
**`/fragments/elasticsearch5-fragment.sh`**

This file is a shell script that contains curl commands to do any setup the app needs in elasticsearch - creating indexes etc. It will be passed a single argument, the host and port, which can be accessed in the script using `$1`.

The ports 9200/9300 and 9202/9302 are exposed on the host for Elasticsearch versions 2 and 5 respectively.

[Example](snippets/elasticsearch-fragment.sh)

##### Nginx

**`/fragments/nginx-fragment.conf`**

This file forms part of an NGINX configration file. It will be merged into the server directive of the main configuration file.

Important - if your app is adding itself as a proxied location{} behind NGINX, NGINX must start AFTER your app, otherwise it will error with a host not found. So your app's docker-compose-fragment.yml must actually specify NGINX as a service and set the depends_on variable with your app's name. Compose will automatically merge this with the dev-env's own NGINX fragment. See the end of the [example Compose fragment](snippets/docker-compose-fragment.yml) for the exact code.

[Example](snippets/nginx-fragment.conf)

##### RabbitMQ

There are no fragments needed when using this. The Management Console will be available on <http://localhost:45672> (guest/guest).

##### Redis

There are no fragments needed when using this. Redis will be available at <http://localhost:16379> on the host and at <http://redis:6379> inside the Docker network.

You can monitor Redis activity using the CLI:

```shell
bashin redis
redis-cli monitor
```

##### Squid

There are no fragments needed when using this. An HTTP proxy will be made available to all containers at runtime, at hostname `squid` and port 3128. It will be available on the host on port 30128.

It also supports HTTPS, however you will need to ensure the self signed [root CA](https://github.com/LandRegistry/docker-base-images/blob/master/squid/devenv-squid-rootca.der?raw=true) is loaded into wherever it needs to go, depending on what is using the proxy (Java cacerts etc). This is best to do in your Dockerfile, alongside setting any variables needed to point to use the proxy itself.

##### Auth

The `auth` commodity can be used by applications requiring authentication functionality and adds two containers: `openldap` and `keycloak`.

###### OpenLDAP

The OpenLDAP container has been customised with a schema similar to that present in Microsoft's Active Directory and the base objects required to use it for authentication have been added. Use the following configuration to connect your application:

From within a Docker container:

* Host: openldap
* Port: 389 (the default LDAP port)

From the host system:

* Host: localhost
* Port: 1389

Other parameters:

* Base DN (AKA search base, search path, etc.): `dc=dev,dc=domain`
* Bind DN (user account for administration): `cn=admin,dc=dev,dc=domain`
* Admin password: `admin`

**`/fragments/*.ldif`**

No users are added to the LDAP database by default. To add users, groups, etc, appropriate for your application, add LDIF files to your application's fragments. Any files in the fragments directory with a `.ldif` extension will be added to the LDAP database. Entries you add must fall under the `dc=dev,dc=domain` base DN.

[Example](snippets/ldap-entries.ldif)

###### Keycloak

Keycloak is an identity and access management system supporting the OAuth and OpenID Connect protocols. This container is built containing a `development` realm configured to use the OpenLDAP service to perform user authentication.

When running, Keycloak's admin console is available at http://localhost:8180/ with username `admin` and password `admin`.

Applications using OAuth flows or the OpenID Connect protocol can use Keycloak for this purpose with the following configuration parameters:

* Client ID: `oauth-client`
* Authentication URL: http://localhost:8180/auth/realms/development/protocol/openid-connect/auth  (must be resolvable by the user agent, hence we use `localhost` assuming that the user agent will be a web browser on the host system)
* Token URL: http://keycloak:8080/auth/realms/development/protocol/openid-connect/token (use `localhost:8180` if connecting from the host system)
* OpenID Connect configuration endpoint: http://keycloak:8080/auth/realms/development/.well-known/openid-configuration (use `localhost:8180` if connecting from the host system)

JWT tokens issued from the `development` realm have been configured to mimic those issued by Microsoft ADFS servers. In particular, the LDAP `cn` field is mapped to the `UserName` claim in JWT tokens along with the `Office` claim mapped from the `physicalDeliveryOfficeName` in the LDAP database and the `group` claim listing the user's group memberships.

A [JSON export](scripts/docker/auth/keycloak/development_realm.json) of the `development` realm is used to configure the realm. If further configuration of the realm is required, you can make changes in the admin console and re-export the realm using the procedure described in "Exporting a realm" [here](https://hub.docker.com/r/jboss/keycloak/#exporting-a-realm). The exported JSON can then be merged back into this repository and reused.

#### Other files

**`/fragments/custom-provision.sh`**

This file contains anything you want - for example, initial data load. It will be executed on the host, not in the container. It is only ever run once (during the first `run.sh up`), and the file `.custom_provision.yml` is used by the dev-env to keep track of whether they have been run or not. Like `.commodities.yml`, this can be manually modified to trigger another run.

**`/fragments/custom-provision-always.sh`**

This works the same way as `custom-provision.sh` except it is executed on every `run.sh up`.

**`/fragments/host-fragments.yml`**

This file contains details of hosts to be forwarded on the host; if it exists then requests to the second address shall be forwarded to the first address.

[Example](snippets/host-fragments.yml)

**`/fragments/docker-compose-<any value>-fragment.yml`**

This file can be used to override the default settings for a docker container such as environment variables. It will not be loaded by default but can be applied using the add-to-docker-compose alias.

## Logging

Any messages that get forwarded to the logstash\* container on TCP port 25826 will be output both in the logstash container's own stdout (so `livelogs logstash` can be used to monitor all apps) and in ./logs/log.txt.

\* Note that it is not really logstash, but we kept the container name that for backwards compatibility purposes.

If you want to make use of this functionality, ensure that `logstash` is also present in the appropriate section of the `docker-compose-fragment` file (e.g. `depends_on`).

## Hints and Tips

* Ensure that you give Docker enough CPU and memory to run all your apps.
* The `run.sh destroy` command should be a last resort, as you will have to rebuild all images from scratch. Try the `fullreset` alias as that will just remove your app containers and recreate them. They are most likely to be the source of any corruption. Remember to alter `.commodities.yml` and `.custom_provision.yml` if you need to, and `run.sh reload`.

### Useful commands

If you hate typing long commands then the commands below have been added to the dev-env for you:

```bash
gitlist                                          -     lists all apps and the current branch
status                                           -     view the status of all running containers
stop <name of container>                         -     stop a container
start <name of container>                        -     start a container
restart <name of container>                      -     restart a container
logs <name of container>                         -     view the logs of a container (from the past)
livelogs <name of container>                     -     view the logs of a container (as they happen)
ex <name of container> <command to execute>      -     execute a command in a running container
run <options> <name of container> <command>      -     creates a new container and runs the command in it.
remove <name of container>                       -     remove a container
fullreset <name of container>                    -     Performs stop, remove then rebuild. Useful if a container (like a database) needs to be wiped. Remember to reset .commodities if you do though to ensure init fragments get rerun
rebuild <name of container>                      -     checks if a container needs rebuilding and rebuilds/recreates/restarts it if so, otherwise does nothing. Useful if a file has changed that the Dockerfile copies into the image.
bashin <name of container>                       -     bash in to a container
unit-test <name of container>                    -     run the unit tests for an application (this expects there to a be a Makefile with a unittest command). If you add -r it will output reports to the test-output folder.
integration-test <name of container>             -     run the integration tests for an application (this expects there to a be a Makefile with a integrationtest command).
acceptance-test | acctest                        -     run the acceptance tests run_tests.sh script inside the given container. If using the skeleton, any further parameters will be passed to cucumber.
          <name of container> <cucumber args>
acceptance-lint | acclint                        -     run the acceptance tests run_linting.sh script inside the given container.
          <name of container>
psql[96] <name of database>                      -     run psql in the postgres/posrgres-96 container
db2[c][co]                                       -     run db2 command line in the db2/db2_devc/db2_community container
manage <name of container> <command>             -     run manage.py commands in a container
alembic <name of container> <command>            -     run an alembic db command in a container, with the appropriate environment variables preset
add-to-docker-compose
  <name of new compose fragment>                 -     looks in fragments folder of loaded apps to search for a new docker-compose-fragment including the provided parameter eg docker-compose-syt2-fragment then runs docker-compose up
```

If you prefer using docker or docker-compose directly then below is list of useful commands (note: if you leave out \<name of container\> then all containers will be affected):

```bash
docker-compose run --rm <name of container> <command>    -    spin up a temporary container and run a command in it
docker-compose rm -v -f <name of container>              -    remove a container
docker-compose down --rmi all -v --remove-orphans        -    stops and removes all containers, data, and images created by up. Don't use `--rmi all` if you want to keep the images.
docker-compose stop|start|restart <name of container>    -    (aliases: stop/start/restart) starts, stops or restarts a container (it must already be built and created)
docker exec -it <name of container> bash                 -    (alias: bashin) gets you into a bash terminal inside a running container (useful for then running psql etc)
```

For those who get bored typing docker-compose you can use the alias dc instead. For example "dc ps" rather than "docker-compose ps".

### Adding Breakpoints to Applications Running in Containers

In order to interact with breakpoints that you add to your applications you need to run the container in the foreground and attach to the container terminal. You do that like so:

```bash
docker-compose stop <name of container>
docker-compose run --rm --service-ports <name of container>
```

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available and the changelog, see the [releases page](https://github.com/LandRegistry/common-dev-env/releases).

## Authors

* Simon Chapman ([GitHub](https://github.com/sdchapman))
* Ian Harvey ([GitHub](https://github.com/IWHarvey))

See also the list of [contributors](https://github.com/LandRegistry/common-dev-env/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Acknowledgments

* Matthew Pease ([GitHub](https://github.com/Skablam)) - for helping create the original internal version
