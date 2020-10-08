SHELL:=$(shell echo $$(which bash)) # bash syntax is used in packer target
GITHUB_SHA ?= $(shell git rev-parse --short HEAD)
PACKER_STATUS_FILE:=.packer_success

# provision the machine
playbook:
	ansible-galaxy install -r requirements.yaml
	ansible-galaxy collection install -r requirements.yaml
	# -c makes the connection local
	# -i sets list of hosts to use
	ansible-playbook -c local -i hosts playbook.yaml

# targets for GH actions, used to run on the remote instance
# runs the build on a VM
.PHONY: packer
packer: install_packer
	rm -rf $(PACKER_STATUS_FILE)
	touch head.zip # repo zip, needed to pass packer validation
	packer validate packer.json
	GITHUB_SHA=$(GITHUB_SHA) packer build packer.json
	rm -rf head.zip

# installs packer for CD runner
.PHONY: install_packer
install_packer:
	if ! hash packer; then \
	  cd $$(mktemp -d) && \
	  curl -LO https://releases.hashicorp.com/packer/1.5.5/packer_1.5.5_linux_amd64.zip && \
	  unzip *.zip && \
	  sudo mv packer /usr/local/bin/packer; \
	fi

# run the commandline firmware update process
.PHONY: update_fw
update_fw:
	sudo fwupdmgr update

# sync secrets from bw
.PHONY: sync_secrets
sync_secrets:
	./hack/bw_sync.rb

# copy out or in the current dotfiles
.PHONY: sync_dotfiles
sync_dotfiles_%:
	./hack/sync_home_dir_files.rb $*
