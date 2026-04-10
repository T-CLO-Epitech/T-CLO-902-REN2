setup:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml

setup-traefik:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags services

setup-argo:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags argo

setup-observability:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags taints,monitoring

normalize-taints:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags taints
