SHELL:=$(shell echo $$(which bash)) # bash syntax is used in packer target
GITHUB_SHA ?= $(shell git rev-parse --short HEAD)
PACKER_STATUS_FILE:=.packer_success

# provision the machine
playbook:
	ansible-galaxy install -r requirements.yaml
	ansible-galaxy collection install -r requirements.yaml
	# -c makes the connection local
	# -i sets list of hosts to use
	ansible-playbook -v -c local -i hosts playbook.yaml

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
	  curl -LO https://releases.hashicorp.com/packer/1.7.2/packer_1.7.2_linux_amd64.zip && \
	  unzip *.zip && \
	  sudo mv packer /usr/local/bin/packer; \
	fi

.PHONY: install_hcloud
install_hcloud:
	# install hcloud
	curl -LO https://github.com/hetznercloud/cli/releases/download/v1.19.1/hcloud-linux-amd64.tar.gz
	tar -xf hcloud-linux-amd64.tar.gz
	sudo mv hcloud /usr/local/bin/hcloud

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

# check for updates in installed packages
.PHONY: check_updates
check_updates:
	ruby hack/check_updates.rb
