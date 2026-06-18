setup:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml

setup-services:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags services

setup-argo:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags argo

setup-monitoring:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags monitoring

delete:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags delete