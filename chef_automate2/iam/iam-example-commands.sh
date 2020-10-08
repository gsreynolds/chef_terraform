curl -s -H "api-token: $TOKEN" https://localhost/apis/iam/v2/policies -k | jq
curl -s -H "api-token: $TOKEN" https://localhost/apis/iam/v2/policies/administrator-access -k | jq

# Add members
curl -s -H "api-token: $TOKEN" -H "Content-Type: application/json" https://localhost/apis/iam/v2/policies/administrator-access/members:add -k -d @administrator-access-members-add.json | jq
# Replace members
curl -s -H "api-token: $TOKEN" -H "Content-Type: application/json" https://localhost/apis/iam/v2/policies/administrator-access/members -k -d @administrator-access-members-add.json -X PUT | jq
