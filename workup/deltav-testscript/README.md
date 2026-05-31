# delta-v test script

Simple start up script which downloads containers and runs deltav 

run the script to download the app
```
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile full --profile metrics up -d
```

running powershell version

```
powershell -ExecutionPolicy Bypass -File .\testscript-powershell.ps1
```