# ton-docker-ctrl

Tested operating systems:
* Ubuntu 20.04
* Ubuntu 22.04
* Ubuntu 24.04
* Debian 11
* Debian 12

To run, you need docker-ce, docker-buildx-plugin, docker-compose-plugin:

* [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
* [Install Docker Engine on Debian](https://docs.docker.com/engine/install/debian/)

Build environment variables (are configured in the .env file):

* **GLOBAL_CONFIG_URL** - URL of the TON blockchain configuration (default: [Testnet](https://ton.org/testnet-global.config.json))
* **MYTONCTRL_VERSION** - MyTonCtrl build branch
* **TELEMETRY** - Enable/Disable telemetry
* **IGNORE_MINIMAL_REQS** - Ignore hardware requirements
* **MODE** - Install MyTonCtrl with specified mode (validator or liteserver)
* **DUMP** - Use pre-packaged dump. Reduces duration of initial synchronization, but it takes time to download the dump. You can view the download status in the logs `docker compose logs -f`

Run MyTonCtrl v2 in Docker:

* Clone: `git clone https://github.com/ton-community/ton-docker-ctrl.git && cd ./ton-docker-ctrl`
* Run: `docker compose up --build -d`
* Connect `docker compose exec -it node bash -c "mytonctrl"`

Upgrade MyTonCtrl:

* Build new image: `docker compose build ton-node`
* Run new version: `docker compose up -d`
