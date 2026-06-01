# delta-v test script

Simple start up script which downloads containers and runs deltav 

run the script to download the app

```
sh testscript.sh
```

running powershell version

```
powershell -ExecutionPolicy Bypass -File .\testscript-powershell.ps1
```

starting app from command line 

```
docker compose -f ./target/delta-v-smoke/docker-compose.yml -f ./target/delta-v-smoke/docker-compose.dev.yml -f docker-compose-nginx-proxy.yml --profile full --profile metrics up -d
```

