.PHONY: help doc

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

todo: ## Things that should be done
	@grep -nR --color=always  --before-context=2  --after-context=2 TODO found/

xxx: ## Things that require attention
	@grep -nR --color=always --before-context=2  --after-context=2 XXX found/

# The above can be shared among several projects
