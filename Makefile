GITHUB_SHA ?= $(shell git rev-parse --short HEAD)
PACKER_STATUS_FILE:=.packer_success

# provision the machine
playbook:
	# -c makes the connection local
	# -i sets list of hosts to use
	ansible-playbook -c local -i hosts desktop.yaml

# targets for GH actions, used to run on the remote instance
# runs the build on a VM
.PHONY: packer
packer: install_packer
	rm -rf $(PACKER_STATUS_FILE)
	packer validate packer.json 
	GITHUB_SHA=$(GITHUB_SHA) PACKER_STATUS_FILE=$(PACKER_STATUS_FILE) packer build packer.json || true && \
	if [[ -f $(PACKER_STATUS_FILE) ]]; then exit 0; else echo "packer failed" && exit 235; fi

# installs packer for CD runner
.PHONY: install_packer
install_packer:
	if ! hash packer; then \
	  cd $$(mktemp -d) && \
	  curl -LO https://releases.hashicorp.com/packer/1.5.5/packer_1.5.5_linux_amd64.zip && \
	  unzip *.zip && \
	  sudo mv packer /usr/local/bin/packer; \
	fi
