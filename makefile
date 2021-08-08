.PHONY: help doc

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

database-clear:  ## Remove all data from the database
	fdbcli --exec "writemode on; clearrange \x00 \xFF;"

todo: ## Things that should be done
	@grep -nR --color=always  --before-context=2  --after-context=2 TODO found/

xxx: ## Things that require attention
	@grep -nR --color=always --before-context=2  --after-context=2 XXX found/

# The above can be shared among wny projects

init-fdb: ## install fdb client and server
	rm -rf fdb-clients.deb fdb-server.deb
	wget https://www.foundationdb.org/downloads/6.3.15/ubuntu/installers/foundationdb-clients_6.3.15-1_amd64.deb -O fdb-clients.deb
	sudo dpkg -i fdb-clients.deb
	wget https://www.foundationdb.org/downloads/6.3.15/ubuntu/installers/foundationdb-server_6.3.15-1_amd64.deb -O fdb-server.deb
	sudo dpkg -i fdb-server.deb
