# delta-v test script

> [!NOTE]
> This Version runs with release candidate: 1.3.0-rc3

Delta-V is a refactoring of OpenNMS code to run as docker microservices. 

This test script is an adaption of Delta-v smoke tests to create a simple running example of the current delta v releases

Two versions of the test script are provided; one for linux using `bash`, and one for Windows using `powershell`.
Both require Docker to be pre-installed. 
On windows this is best achieved by installing [Docker Desktop](https://www.docker.com/products/docker-desktop/)

The test script offers an option to delete previous versions of the container images from your machine and download new versions. 
Note that this option will remove ALL non-running containers including containers from other projects, so use with caution.
Do not use this option if you want to avoid re-dowloading containers later.

The script will 

1. Ask if you want to remove/prune existing containers.
2. Copy the docker compose files from the delta-v release selected in the script
3. check and Pull any containers mentioned in the docker compose scripts. 
4. Start the docker compose project.

Not that the smoke test scripts are downloaded to the `target/delta-v-smoke` folder and will not e checked into this repository (.gitignore).

The start up script also contains reference to an additional docker compose file `docker-compose-ngnx-proxy.yml` which includes an nginx-proxy configuration, kafka ui and pgadmin4 which are not in the smoke-test scripts. 

This provides a start page with links to all of the UIs proxed from http://localhost:80. 

THe nginx-proxy also has a configuration for lets-encrypt if you wish to run on https from a public site.

## Running the script

Linux

```
cd deltav-testscript
sh testscript.sh
```

Running Power Shell version

```
cd deltav-testscript
powershell -ExecutionPolicy Bypass -File .\testscript-powershell.ps1
```

Once the smoke test files are downloaded ,you can start and stop the app directly from the command line using the docker compose commands:

Bring Up:

```
docker compose -f ./target/delta-v-smoke/docker-compose.yml -f ./target/delta-v-smoke/docker-compose.dev.yml -f docker-compose-nginx-proxy.yml --profile full --profile metrics up -d
```

Shut down:

```
docker compose -f ./target/delta-v-smoke/docker-compose.yml -f ./target/delta-v-smoke/docker-compose.dev.yml -f docker-compose-nginx-proxy.yml --profile full --profile metrics down
```

If you want to completely remove ONLY the containers associated with this project from your system, you can use the following command:

```
docker compose -f ./target/delta-v-smoke/docker-compose.yml -f ./target/delta-v-smoke/docker-compose.dev.yml -f docker-compose-nginx-proxy.yml --profile full --profile metrics down -v --rmi all 
```
