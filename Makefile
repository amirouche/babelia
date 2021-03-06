help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

init: ## Install dependencies with guix
	guix package -i guile3.0-bytestructures guile3.0-gcrypt guile3.0-fibers guile3.0-gnutls guile-arew wiredtiger@3.2.0-0

check: ## Run tests
	guile -L . check.scm
	@echo "\033[95m\n\nWin!\n\033[0m"

todo: ## Things that should be done
	@grep -nR --color=always --after-context=4 TODO .

xxx: ## Things that require attention
	@grep -nR --color=always --after-context=4 XXX .

bug-guix: bug-guix.tar.gz
	tar xf bug-guix.tar.gz
	./babelia.scm index bug-guix/

benchmarks: bug-guix compile ## Wanna be benchmarks
	bash benchmarks.sh > benchmarks.org

repl:  ## Start a guile REPL with rlwrap
	rlwrap guile -L .

web: ## start the default web server
	guile -L . babelia.scm scheme-lang-index/ web run

compile:  ## Compile every file at maximum optimization level
	guild compile -L . -O3 ./babelia.scm
	guild compile -L . -O3 ./babelia/wiredtiger.scm
	guild compile -L . -O3 ./babelia/fash.scm
	guild compile -L . -O3 ./babelia/okvs/wiredtiger.scm
	guild compile -L . -O3 ./babelia/okvs/counter.scm
	guild compile -L . -O3 ./babelia/okvs/mapping.scm
	guild compile -L . -O3 ./babelia/okvs/engine.scm
	guild compile -L . -O3 ./babelia/okvs/ustore.scm
	guild compile -L . -O3 ./babelia/okvs/nstore.scm
	guild compile -L . -O3 ./babelia/okvs/fts.scm
	guild compile -L . -O3 ./babelia/okvs/pack.scm
	guild compile -L . -O3 ./babelia/okvs/ulid.scm
	guild compile -L . -O3 ./babelia/okvs/multimap.scm
	guild compile -L . -O3 ./babelia/generator.scm
	guild compile -L . -O3 ./babelia/cffi.scm
	guild compile -L . -O3 ./babelia/bytevector.scm
	guild compile -L . -O3 ./babelia/stemmer.scm
	guild compile -L . -O3 ./babelia/thread.scm
	guild compile -L . -O3 ./babelia/wiredtiger/config.scm
