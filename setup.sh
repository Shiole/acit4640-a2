#!/bin/bash
set -o nounset

declare -r SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

cd "${SCRIPT_DIR}"/infrastructure || exit 1
terraform init
terraform apply -auto-approve

cd .. || exit 1

source "${SCRIPT_DIR}/instances.sh"

aws ec2 wait instance-running --instance-ids $db_ec2_id
aws ec2 wait instance-running --instance-ids $backend_ec2_id
aws ec2 wait instance-running --instance-ids $web_ec2_id

sleep 5
ansible-playbook -i "${SCRIPT_DIR}/service/inventory/webservers.yml" "${SCRIPT_DIR}/service/playbook.yml"

echo "Service Running on:"
echo "${web_dns}"
echo ""
