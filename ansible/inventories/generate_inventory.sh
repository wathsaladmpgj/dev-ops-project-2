#!/usr/bin/env bash
set -euo pipefail

TF_DIR="${1:-../terraform-infra}"

OUT_JSON="$(terraform -chdir="$TF_DIR" output -json 2>/dev/null || true)"
if [[ -z "${OUT_JSON}" || "${OUT_JSON}" == "null" ]]; then
  echo "❌ ERROR: terraform output is empty. Terraform state missing. Do NOT delete workspace or use S3 backend."
  exit 1
fi

get_ip () {
  local key="$1"
  local ip
  ip="$(echo "$OUT_JSON" | jq -r ".public_ips.value[\"${key}\"]")"
  if [[ "$ip" == "null" || -z "$ip" ]]; then
    echo "❌ ERROR: IP for ${key} is null. Check terraform outputs and state."
    exit 1
  fi
  echo "$ip"
}

K8S_MASTER_IP="$(get_ip "k8s-master")"
K8S_W1_IP="$(get_ip "k8s-worker-1")"
K8S_W2_IP="$(get_ip "k8s-worker-2")"
NEXUS_IP="$(get_ip "nexus")"
SONAR_IP="$(get_ip "sonarqube")"
MON_IP="$(get_ip "monitoring")"

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

echo "✅ Inventory generated: $(dirname "$0")/hosts.ini"
cat "$(dirname "$0")/hosts.ini"
