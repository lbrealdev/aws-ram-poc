set dotenv-load := true

# ============================================================================
# Aliases
# ============================================================================
alias t := mise-tools
alias sts := aws-check
alias plan := tf-plan
alias apply := tf-apply
alias destroy := tf-destroy
alias fmt := tf-lint
alias validate := tf-check
alias init := tf-init
alias cleanup := tf-cleanup
alias list := tf-list
alias show := tf-show
alias refresh := tf-refresh

# ============================================================================
# AWS & tooling
# ============================================================================

# Check current AWS identity
@aws-check:
    aws sts get-caller-identity

# List mise tools installed for this directory
@mise-tools:
    mise ls --json | jq -r --arg pwd "$(pwd)" 'to_entries[] | select(.value[].source.path != null and (.value[].source.path | contains($pwd))) | .key'

# ============================================================================
# Terraform
# ============================================================================

# Initialize Terraform (providers / modules / backend)
@tf-init *var:
    terraform init {{ var }}

# Remove local Terraform artifacts (does not destroy cloud resources)
[confirm("Remove local Terraform artifacts (.terraform, plan/destroy files, crash logs, local state)? This does not destroy cloud resources.")]
@tf-cleanup:
    rm -rf .terraform
    rm -f plan destroy crash.log crash.*.log *.tfstate *.tfstate.*
    echo "Local Terraform artifacts removed."

# Create a plan and save it to a file
@tf-plan *var:
    terraform plan -out plan {{ var }}

# Apply the saved plan
@tf-apply *var:
    terraform apply plan {{ var }}

# Create a destroy plan and apply it
@tf-destroy *var:
    terraform plan -destroy -out destroy {{ var }}
    just _tf-destroy

[confirm("Are you sure you want to destroy all Terraform resources? This action cannot be undone.")]
@_tf-destroy:
    terraform apply destroy

# Format Terraform files in place
@tf-lint:
    terraform fmt -write=true -recursive

# Validate Terraform configuration
@tf-check:
    terraform validate

# Show Terraform state
@tf-show:
    terraform show

# List resources in Terraform state
@tf-list:
    terraform state list

# Refresh Terraform state
@tf-refresh:
    terraform refresh
