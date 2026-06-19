setup:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml

setup-services:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags services

setup-argo:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags argo

setup-monitoring:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags monitoring

setup-loki:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags loki

delete-monitoring:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags delete-monitoring

delete-loki:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags delete-loki

delete:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags delete