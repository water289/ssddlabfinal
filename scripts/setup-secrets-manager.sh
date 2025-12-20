#!/bin/bash
# Secrets Manager Setup Script
# Retrieves secrets from AWS Secrets Manager and creates Kubernetes secrets

set -e

AWS_REGION="${AWS_REGION:-us-east-1}"
K8S_NAMESPACE="${K8S_NAMESPACE:-voting-system}"

echo "=== AWS Secrets Manager Setup ==="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI not found. Installing..."
    if sudo apt-get update && sudo apt-get install -y awscli; then
        echo "AWS CLI installed via apt."
    else
        echo "apt install failed; installing AWS CLI via pip..."
        sudo pip3 install awscli==1.32.0 || { echo "AWS CLI install failed"; exit 1; }
    fi
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Installing jq for JSON parsing..."
    sudo apt-get install -y jq
fi

# Check if AWS CLI exists (optional)
echo "Checking for AWS credentials..."
if ! command -v aws &> /dev/null || ! aws sts get-caller-identity &> /dev/null 2>&1; then
    echo "WARNING: AWS CLI not configured or no IAM role. Using Jenkins credentials fallback."
fi

# Function to retrieve secret
get_secret() {
    local secret_name=$1
    local key=$2
    
    echo "Retrieving secret: $secret_name"
    local secret_value=$(aws secretsmanager get-secret-value \
        --secret-id "$secret_name" \
        --region "$AWS_REGION" \
        --query SecretString \
        --output text 2>/dev/null || echo "")
    
    if [ -z "$secret_value" ]; then
        echo "WARNING: Secret $secret_name not found. Using fallback."
        return 1
    fi
    
    echo "$secret_value" | jq -r ".$key"
}

# Check if secrets already exist in Kubernetes
if kubectl get secret voting-secrets -n "$K8S_NAMESPACE" &> /dev/null; then
    echo "✓ Kubernetes secret 'voting-secrets' already exists. Skipping retrieval."
    echo "To force update, delete secret: kubectl delete secret voting-secrets -n $K8S_NAMESPACE"
    exit 0
fi

echo "Retrieving secrets from AWS Secrets Manager..."

# Retrieve database credentials
DB_USERNAME=$(get_secret "voting/database/credentials" "username") || DB_USERNAME="voting_db_user"
DB_PASSWORD=$(get_secret "voting/database/credentials" "password") || DB_PASSWORD="${POSTGRES_PASSWORD:-changeme123}"

# Retrieve backend secret key
SECRET_KEY=$(get_secret "voting/backend/secret-key" "secret_key") || SECRET_KEY="${SECRET_KEY:-$(openssl rand -hex 32)}"

# Retrieve encryption key
ENCRYPTION_KEY=$(get_secret "voting/backend/encryption-key" "encryption_key") || ENCRYPTION_KEY="${VOTE_ENCRYPTION_KEY:-$(openssl rand -base64 32)}"

# Build DATABASE_URL
DATABASE_URL="postgresql://${DB_USERNAME}:${DB_PASSWORD}@postgres:5432/voting_db"

echo "Creating Kubernetes namespace if not exists..."
kubectl create namespace "$K8S_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "Creating Kubernetes secret..."
kubectl create secret generic voting-secrets \
    --from-literal=database_url="$DATABASE_URL" \
    --from-literal=secret_key="$SECRET_KEY" \
    --from-literal=postgres_password="$DB_PASSWORD" \
    --from-literal=vote_encryption_key="$ENCRYPTION_KEY" \
    -n "$K8S_NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

echo "✓ Secrets retrieved and stored in Kubernetes"

# Export for Jenkins environment (optional)
if [ -n "$JENKINS_HOME" ]; then
    echo "Exporting secrets to Jenkins environment..."
    SECRETS_FILE="$WORKSPACE/secrets.env"
    mkdir -p "$(dirname "$SECRETS_FILE")"
    printf 'DATABASE_URL=%s\n' "$DATABASE_URL" >> "$SECRETS_FILE"
    printf 'SECRET_KEY=%s\n' "$SECRET_KEY" >> "$SECRETS_FILE"
    printf 'VOTE_ENCRYPTION_KEY=%s\n' "$ENCRYPTION_KEY" >> "$SECRETS_FILE"
fi

echo "=== Secrets setup complete ==="
