#!/usr/bin/env bash
set -e

REGION="us-east-1"
CLUSTER_NAME="foundational-architecture-cluster"
KARPENTER_NODE_ROLE="foundational-architecture-karpenter-node-role"

# Path check
if [[ "$PWD" != *"/01-infrastructure"* ]]; then
  echo "Error: teardown.sh must be executed from within 01-infrastructure directory."
  exit 1
fi

echo "=== Exporting Terraform Secrets ==="
export TF_VAR_db_password="SuperSecretPassword123!"
export TF_VAR_ec2_public_key=$(tr -d '\r\n' < ~/.ssh/id_ed25519.pub)

echo "=== Pass 0: Graceful Kubernetes & Karpenter Cleanup ==="
if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" >/dev/null 2>&1; then
  aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"

  echo "Deleting Karpenter NodeClaims, NodePools, and EC2NodeClasses..."
  kubectl delete nodeclaim --all --ignore-not-found=true --wait=true || true
  kubectl delete nodepool --all --ignore-not-found=true --wait=true || true
  kubectl delete ec2nodeclass --all --ignore-not-found=true --wait=true || true

  echo "Uninstalling Karpenter Helm release..."
  helm uninstall karpenter -n kube-system 2>/dev/null || true
else
  echo "EKS cluster already deleted; skipping Kubernetes cleanup."
fi

echo "Checking for any leftover Karpenter IAM instance profiles..."
if aws iam get-role --role-name "$KARPENTER_NODE_ROLE" >/dev/null 2>&1; then
  PROFILES=$(aws iam list-instance-profiles-for-role \
    --role-name "$KARPENTER_NODE_ROLE" \
    --query "InstanceProfiles[*].InstanceProfileName" \
    --output text)
  for PROFILE in $PROFILES; do
    echo "Detaching and deleting leftover instance profile: $PROFILE"
    aws iam remove-role-from-instance-profile --instance-profile-name "$PROFILE" --role-name "$KARPENTER_NODE_ROLE" || true
    aws iam delete-instance-profile --instance-profile-name "$PROFILE" || true
  done
fi

echo "=== Pass 1: Destroying EKS Addons, Cluster, Compute, ALB, and Database ==="
terraform destroy \
  -target=aws_eks_pod_identity_association.karpenter \
  -target=aws_eks_pod_identity_association.app \
  -target=aws_eks_addon.pod_identity \
  -target=aws_eks_access_entry.karpenter_node \
  -target=aws_eks_node_group.main \
  -target=aws_eks_cluster.main \
  -target=aws_autoscaling_group.app_asg \
  -target=aws_lb.app_alb \
  -target=aws_db_instance.mysql \
  -auto-approve

echo "=== Waiting 45s for AWS ENIs and target groups to disassociate ==="
sleep 45

echo "=== Pass 2: Destroying Baseline Network, ECR, SQS, and IAM Infrastructure ==="
terraform destroy -auto-approve

echo "=== Teardown Verification (Zero Billable Resources Check) ==="
echo "--- VPCs ---"
aws ec2 describe-vpcs --region "$REGION" --query "Vpcs[*].[VpcId,IsDefault]" --output table

echo "--- Active EC2 Instances ---"
aws ec2 describe-instances --region "$REGION" \
  --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query "Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]" --output table

echo "--- NAT Gateways (Available/Pending) ---"
aws ec2 describe-nat-gateways --region "$REGION" \
  --filter "Name=state,Values=pending,available" \
  --query "NatGateways[*].[NatGatewayId,State]" --output table

echo "--- Elastic IPs ---"
aws ec2 describe-addresses --region "$REGION" --query "Addresses[*].[AllocationId,PublicIp]" --output table

echo "--- EKS Clusters & RDS Instances ---"
aws eks list-clusters --region "$REGION" --output table
aws rds describe-db-instances --region "$REGION" --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]" --output table
