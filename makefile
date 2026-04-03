setup:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml

setup-traefik:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags services

setup-argo:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags argo