playbook:
	# -c makes the connection local
	# -i sets list of hosts to use
	ansible-playbook -c local -i hosts desktop.yaml
