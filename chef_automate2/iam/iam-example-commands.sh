curl -sk -H "api-token: $TOKEN" https://localhost/apis/iam/v2/policies | jq
curl -sk -H "api-token: $TOKEN" https://localhost/apis/iam/v2/policies/administrator-access | jq

# Add members
curl -sk -H "api-token: $TOKEN" -H "Content-Type: application/json" https://localhost/apis/iam/v2/policies/administrator-access/members:add -d @administrator-access-m
# Assign "ingest" token to ingest policy
# sudo chef-automate iam token create ingest
curl -sk -H "api-token: $TOKEN" -H "Content-Type: application/json" https://localhost/apis/iam/v2/policies/administrator-access/members:add -d '{"members":["token:ingest"]}' | jq
# Replace members
curl -sk -H "api-token: $TOKEN" -H "Content-Type: application/json" https://localhost/apis/iam/v2/policies/administrator-access/members -d @administrator-access-members-add.json -X PUT | jq

# Create projects
curl -sk -H "api-token: $TOKEN" -H "Content-Type: application/json" https://localhost/apis/iam/v2/projects -d '{"id": "development", "name": "Development"}' | jq

# List project rules
curl -sk -H "api-token: $TOKEN" -H "Content-Type: application/json" https://localhost/apis/iam/v2/projects/development/rules | jq
curl -sk -H "api-token: $TOKEN" -H "Content-Type: application/json" https://localhost/apis/iam/v2/projects/development/rules -d @project-development-rules.json | jq

# Apply project rules
curl -sk -H "api-token: $TOKEN" https://localhost/apis/iam/v2/apply-rules -X POST | jq
