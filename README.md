# Common Development Environment

This repository contains the code for a development environment that can be used across teams and projects. It is designed to allow collections of applications to be loaded from a separate configuration repository, and maximising consistency between them.

It provides several hooks for applications to take advantage of, including:

* Docker container creation and launching via docker-compose
* Automatic creation of commodity systems such as Postgres or Elasticsearch (with further hooks to allow for initial provisoning such as running SQL, Alembic DB upgrades or Elasticsearch index creation)

## Getting started

### Prerequisites

* **Docker and Docker Compose**. Exactly what toolset you use depends on your OS and personal preferences, but recommended are:
  * [Docker For Mac](https://docs.docker.com/docker-for-mac/)
  * [Docker for Windows 10](https://docs.docker.com/docker-for-windows/) (See [the wiki](https://github.com/LandRegistry/common-dev-env/wiki/Windows-setup) for more information on getting a working Windows environment set up)
  * [Docker CE for Linux](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
* **Git**
* **Ruby 2.5+**

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
* `repair` - sets the Docker-compose configuration to use the fragments from applications in _this_ dev-env instance (in case you are switching between several or are in a different terminal window to the one you ran `up` in)
* `quickup` and `quickreload` - as per `up` and `reload` except they do not update anything from git (apps or config), rebuild Docker images or provision any commodity fragments.

#### Extra functionality

* `--nopull` (or `-n`) can go after `up` or `reload` - e.g. `source run.sh up -n`. This will stop images FROMed in Dockerfiles being checked for updates if a copy already exists on the system. Use to avoid Docker Hub pull rate limits.

## Usage guide

### Configuration Repository

This is a Git repository that must contain a single file  -
`configuration.yml`. The configuration file has an `applications` key that contains a list of the applications that will be running in the dev-env, each specifying the URL of their Git repository (the `repo` key) plus which branch/tag/commit should be initially checked out (the `ref` key), and any optional Compose fragment variant name to use (the `variant` key) if appropriate.

The name of the application should match the repository name so that things dependent on the directory structure like volume mappings in the app's compose-fragment.yml will work correctly.

Any Compose fragment variant name, if defined, should also match with a variant Compose file in the repository, in the format `compose-fragment.xyz.yml` (where "xyz" is the variant name).

The application repositories will be pulled and updated on each `up` or `reload`, _unless_ the current checked out branch does not match the one in the configuration. This allows you to create and work in feature branches while remaining in full control of updates and merges.

If you are creating a new app that doesn't have a remote Git repository to clone from yet, you can manually put a directory into `/apps/` and add it to the configuration with the `repo` key set to `none` and no `ref` key.

This file can also optionally contain a `post-up-message` key that provides a message to be displayed after the dev-env has finished starting all applications.

[Example](snippets/configuration.yml)

### Application support

For an application repository to leverage the full power of the dev-env...

Docker containers are used to run all apps. So some files are needed to support that.

#### Fragments

##### `/fragments/compose-fragment.yml`

This is used by the environment to construct an application container and then launch it. Standard [Compose Spec](https://github.com/compose-spec/compose-spec/blob/master/spec.md) structure applies - but some recommendations are:

* Container name and service name should match
* Any ports that need to be accessed from the host machine (as opposed to from other containers) should be mapped
* A `volumes` entry should map the path of the app folder to wherever the image expects source files to be (if they are to be accessed dynamically, and not copied in at image build time)
* If the provided log collator is to be used, then a syslog logging driver needs to be present, forwarding to logstash:25826.
* If you wish to run the container as the host user so you have full access to any files created by the container (this is only a problem on Linux and WSL), environment variables `OUTSIDE_UID` and `OUTSIDE_GID` are provided for use in the fragment as build args (which can then be used in the `Dockerfile` to create a matching user and set them as the container-executor).

Although generally an application should only have itself in its compose fragment, there is no reason why other containers based on other Docker images cannot also be listed in this file, if they are not provided already by the dev-env.

Note that when including directives such as a Dockerfile build location or host volume mapping for the source code, the Compose context root `.` is considered to be the dev-env's /apps/ folder, not the location of the fragment. Ensure relative paths are set accordingly.

##### `/fragments/compose-fragment.<variant>.yml`

Optional variants of `compose-fragment.yml` designed for specific use cases, such as offering slimmed-down or extended configurations. The syntax for a variant compose fragment is the same as that for a default unversioned compose fragment (see above).

Replace `<variant>` with the specific name of the variant configuration required, such as `slim` or `full`.

A default `compose-fragment.yml` is still required in addition to any optional variants.

[Example](snippets/compose-fragment.yml)

##### `/fragments/docker-compose-fragment.yml` and `/fragments/docker-compose-fragment.3.7.yml`

Optional variants of `compose-fragment.yml` with a version of `2` and `3.7` respectively. Support for these is still present for backwards compatibility with older apps.The development environment will select the highest compose file version supplied by _all_ applications in the environment (2 --> 3.7 --> unversioned).

If the environment cannot identify a universal compose file version, then provisioning will fail.

Compose fragment variants are unsupported when used in conjunction with older compose fragment versions.

[2 Example](snippets/docker-compose-fragment.yml)

[3.7 Example](snippets/docker-compose-fragment.3.7.yml)

#### Other

##### `/Dockerfile`

This is a file that defines the application's Docker image. The Compose fragment may point to this file. Extend an existing image and install/set whatever is needed to ensure that containers created from the image will run. See the [Dockerfile reference](https://docs.docker.com/engine/reference/builder/) for more information.

[Example - Python/Flask](snippets/flask_Dockerfile)

[Example - Java](snippets/java_Dockerfile)

##### `/configuration.yml`

This file specifies which commodities the dev-env should create and launch for the application to use. If the commodity must be started before your application, ensure that it is also present in the appropriate section of the `docker-compose-fragment` file (e.g. `depends_on`).

The list of allowable commodity values is:

1. postgres-13
2. db2_community
4. elasticsearch5
5. elasticsearch7
6. nginx
7. rabbitmq
8. redis
9. swagger
10. wiremock
11. squid
12. auth
13. cadence
14. cadence-web
15. activemq
16. ibmmq
17. localstack

The file may optionally also indicate that one or more services are resource intensive ("expensive") when starting up. The dev env will start those containers seperately - 3 at a time - and wait until each are declared healthy (or crash and get restarted 10 times) before starting any more.

This requires a healthcheck command specified here or in the Dockerfile/docker-compose-fragment (in which case just use 'docker' in this file).

If one of these expensive services prefers another one to be considered "healthy" before a startup attempt is made (such as a database, to ensure immediate connectivity and no expensive restarts) then the dependent service can be specified here, with a healthcheck command following the same rules as above.

[Example](snippets/app_configuration.yml)

#### Commodities

Individual commodities may require further files in order to set them up correctly even after being specified in the application's `configuration.yml`, these are detailed below.

Note that unless specified, any fragment files will only be run once. This is controlled by a generated `.commodities.yml` file in the root of the this repository, which you can change to allow the files to be read again - useful if you've had to delete and recreate a commodity container.

##### PostgreSQL

**`/fragments/postgres-init-fragment.sql`**

This file contains any one-off SQL to run in Postgres - at the minimum it will normally be creating a database and an application-specific user.

[Example](snippets/postgres-init-fragment.sql)

If you want to spatially enable your database see the following example:

[Example - Spatial](snippets/spatial_postgres-init-fragment.sql)

The default Postgres port 5432 will be available for connections from other containers. Port 5434 is exposed for external connections from the host.

**`/manage.py`**

This is a standard Alembic management file - if it exists, then a database migration will be run on every `up` or `reload`. This functionality can be enabled by setting the key `perform_alembic_migration` to `true` in `configuration.yml`. It is recommended however that you do your own migration during app startup.

##### DB2 Community

Note that DB2 Community is exposed on 30002/35002 to avoid port clashes.

**`/fragments/db2-community-init-fragment.sql`**

This file contains any one-off SQL to run in DB2 - at the minimum it will normally be creating a database.

[Example](snippets/db2-community-init-fragment.sql)

##### ElasticSearch 5

**`/fragments/elasticsearch5-fragment.sh`**

This file is a shell script that contains curl commands to do any setup the app needs in elasticsearch - creating indexes etc. It will be passed a single argument, the host and port, which can be accessed in the script using `$1`.

The ports 9300 and 9302 are exposed on the host.

[Example](snippets/elasticsearch5-fragment.sh)

##### ElasticSearch 7

The ports 9207 and 9307 are exposed on the host.

If the ElasticSearch 7 container is returning the follow error log message:
```
max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
```
Run the following command in a terminal to set the system's max map count.
```
sysctl -w vm.max_map_count=262144
```

##### Nginx

**`/fragments/nginx-fragment.conf`**

This file forms part of an NGINX configration file. It will be merged into the server directive of the main configuration file.

Important - if your app is adding itself as a proxied location{} behind NGINX, NGINX must start AFTER your app, otherwise it will error with a host not found. So your app's docker-compose-fragment.yml must actually specify NGINX as a service and set the depends_on variable with your app's name.

Compose will automatically merge this with the dev-env's own NGINX fragment. See the end of the [example Compose fragment](snippets/docker-compose-fragment.yml) for the exact code.

[Example](snippets/nginx-fragment.conf)

##### Wiremock

**`/fragments/wiremock-fragment.json`**

This is a file that contains stub mappings that Wiremock will pick up and use, as an alternative to dynamic programming via its API. See the official Wiremock documentation for help on the structure and contents of the file.

[Example](snippets/wiremock-fragment.json)

**`/fragments/wiremock/`**

This is a directory that can contain multiple stub mappings files that Wiremock will pick up and use. The files should all be in the same format as the example above. If such a wiremock directory exists, it will take precedence over any `wiremock-fragment.json` file.

##### RabbitMQ

There are no fragments needed when using this. The Management Console will be available on <http://localhost:15672> (guest/guest).

Rabbit is available over port 5672 and TLS on port 5671.

TLS presents a self signed cert. If verification is needed a copy of the ca certificate is [here](scripts/docker/rabbitmq/certs/ca_certificate.crt). The host has been set to `rabbitmq` for host verification in most common libraries, although will only work within the docker network.

MTLS is not enabled, although a [client certificate pem](scripts/docker/rabbitmq/certs/client_certificate.pem) and [client key pem](scripts/docker/rabbitmq/certs/client_key.pem) have been generated as part of the certificate set for potential future use.

Currently, only the `rabbitmq_management`, `rabbitmq_consistent_hash_exchange`, `rabbitmq_shovel`, `rabbitmq_shovel_management` and `rabbitmq_stream` plugins are enabled.

##### ActiveMQ

There are no fragments needed when using this. The Management Console will be available on <http://localhost:8161> (admin/admin).

##### IBM MQ

There are no fragments needed when using this. The Web Console will be available on <https://localhost:9443> (admin/passw0rd) and MQ itself on port 1414. To access IBM MQ through a service use the username `app` with no password.

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

When running, Keycloak's admin console is available at <http://localhost:8180/> with username `admin` and password `admin`.

Applications using OAuth flows or the OpenID Connect protocol can use Keycloak for this purpose with the following configuration parameters:

* Client ID: `oauth-client`
* Authentication URL: <http://localhost:8180/auth/realms/development/protocol/openid-connect/auth>  (must be resolvable by the user agent, hence we use `localhost` assuming that the user agent will be a web browser on the host system)
* Token URL: <http://keycloak:8080/auth/realms/development/protocol/openid-connect/token> (use `localhost:8180` if connecting from the host system)
* OpenID Connect configuration endpoint: <http://keycloak:8080/auth/realms/development/.well-known/openid-configuration> (use `localhost:8180` if connecting from the host system)

JWT tokens issued from the `development` realm have been configured to mimic those issued by Microsoft ADFS servers. In particular, the LDAP `cn` field is mapped to the `UserName` claim in JWT tokens along with the `Office` claim mapped from the `physicalDeliveryOfficeName` in the LDAP database and the `group` claim listing the user's group memberships.

A [JSON export](scripts/docker/auth/keycloak/development_realm.json) of the `development` realm is used to configure the realm. If further configuration of the realm is required, you can make changes in the admin console and re-export the realm using the procedure described in "Exporting a realm" [here](https://hub.docker.com/r/jboss/keycloak/#exporting-a-realm).

The exported JSON can then be merged back into this repository and reused.

###### Cadence

Cadence is the Uber-developed HA orchestrator. It's configured to use an auto-setup mode to automatically create postgres schema and tables required for cadence functioning.
Use the following configuration to connect your application:

From within a Docker container:

* Host: cadence
* Port: 7933 (default cadence frontend port)

From the host system:

* Host: localhost
* Port: 7933

###### Cadence Web

[Cadence Web](https://github.com/uber/cadence-web) is a web-based user interface which is used to view workflows from Cadence, see what's running, and explore and debug workflow executions. This also comes with a RESTful API that allows us query
cadence core services.

*Running Cadence web locally*
- In a web browser enter <http://localhost:5004>

###### Localstack

[Localstack](https://localstack.cloud) is a cloud stack testing and mocking framework for developing against various AWS services.

A default Localstack configuration is provided with a minimal number of enabled services available (S3 only at present). Localstack does not _require_ the use of any other external configuration file (as applications can manage buckets programatically through methods such as the [AWS SDK](https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/examples-s3-buckets.html)).

However, if additional configuration (such as new buckets) are necessary before application startup, you can use a `localstack-init-fragment.sh` to perform this provisioning; an example of which is provided [here](snippets/localstack-init-fragment.sh).

Localstack is available at <http://localstack:4566> within the Docker network, and <http://localhost:4566> on the host.

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
* A memory limit of 384mb is set for intermediate containers during the image build process - but only if using Docker Compose V1 and you have Buildkit disabled in advanced Docker settings.

### Useful commands

If you hate typing long commands then the commands below have been added to the dev-env for you, just type `devenv-help` after an up for a full list.

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
