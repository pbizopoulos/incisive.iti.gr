.POSIX:

.PHONY: all check clean help

container_engine = docker # For podman first execute `printf 'unqualified-search-registries=["docker.io"]\n' > /etc/containers/registries.conf.d/docker.conf`
debug = 1
debug_args = $$(test -t 0 && printf '%s' '--interactive --tty')
npx_timeout_command = $$(test $(debug) = 1 && printf '%s' '& sleep 1; kill $$!')
user_arg = $$(test $(container_engine) = 'docker' && printf '%s' "--user $$(id -u):$$(id -g)")
work_dir = /work

all: .dockerignore .gitignore bin/cert.pem index.html
	$(container_engine) container run \
		$(debug_args) \
		$(user_arg) \
		--env HOME=$(work_dir)/bin \
		--env NODE_PATH=$(work_dir)/bin \
		--publish 8080:8080 \
		--rm \
		--volume $$(pwd):$(work_dir)/ \
		--workdir $(work_dir)/ \
		node /bin/bash -c "npx --yes http-server --cert bin/cert.pem --key bin/key.pem --ssl $(npx_timeout_command)"

check: bin/check

clean:
	rm -rf bin/

help:
	@printf 'make all 	# Run server (debug=0 for disabling debug).\n'
	@printf 'make check 	# Check code.\n'
	@printf 'make clean 	# Remove binaries.\n'
	@printf 'make help 	# Show help.\n'

.dockerignore:
	printf '*\n' > .dockerignore

.gitignore:
	printf 'bin/\n' > .gitignore

bin:
	mkdir bin

bin/cert.pem: bin
	$(container_engine) container run \
		$(user_arg) \
		--detach-keys 'ctrl-^,ctrl-^' \
		--rm \
		--volume $$(pwd):$(work_dir)/ \
		--workdir $(work_dir)/ \
		alpine/openssl req -newkey rsa:2048 -subj "/C=../ST=../L=.../O=.../OU=.../CN=.../emailAddress=..." -new -nodes -x509 -days 3650 -keyout bin/key.pem -out bin/cert.pem

bin/check: .dockerignore .gitignore bin bin/check-html
	touch bin/check

bin/check-html: .dockerignore .gitignore bin index.html
	$(container_engine) container run \
		$(debug_args) \
		$(user_arg) \
		--env HOME=$(work_dir)/bin \
		--env NODE_PATH=$(work_dir)/bin \
		--rm \
		--volume $$(pwd):$(work_dir)/ \
		--workdir $(work_dir)/ \
		node npx --yes html-validate index.html
	touch bin/check-html

index.html:
	printf '\n' > index.html
