#!/usr/bin/env bash
set -euo pipefail

TF_DIR="${1:-../terraform-infra}"
OUT_JSON="$(terraform -chdir="$TF_DIR" output -json)"

# Use public IPs (LAB MODE)
K8S_MASTER_IP="$(echo "$OUT_JSON" | jq -r '.public_ips.value["k8s-master"]')"
K8S_W1_IP="$(echo "$OUT_JSON" | jq -r '.public_ips.value["k8s-worker-1"]')"
K8S_W2_IP="$(echo "$OUT_JSON" | jq -r '.public_ips.value["k8s-worker-2"]')"
NEXUS_IP="$(echo "$OUT_JSON" | jq -r '.public_ips.value["nexus"]')"
SONAR_IP="$(echo "$OUT_JSON" | jq -r '.public_ips.value["sonarqube"]')"
MON_IP="$(echo "$OUT_JSON" | jq -r '.public_ips.value["monitoring"]')"

cat > "$(dirname "$0")/hosts.ini" <<EOF
[k8s_master]
k8s-master ansible_host=${K8S_MASTER_IP} ansible_user=ubuntu

[k8s_workers]
k8s-worker-1 ansible_host=${K8S_W1_IP} ansible_user=ubuntu
k8s-worker-2 ansible_host=${K8S_W2_IP} ansible_user=ubuntu

[tools]
nexus ansible_host=${NEXUS_IP} ansible_user=ubuntu
sonarqube ansible_host=${SONAR_IP} ansible_user=ubuntu
monitoring ansible_host=${MON_IP} ansible_user=ubuntu

[k8s:children]
k8s_master
k8s_workers
EOF

echo "✅ Inventory generated at ansible/inventories/hosts.ini"
