# IAM Example Commands
See https://docs.chef.io/automate/api/ for full documentation

## View policies
```bash
curl -sk -H "api-token: $TOKEN" https://localhost/apis/iam/v2/policies | jq
curl -sk -H "api-token: $TOKEN" https://localhost/apis/iam/v2/policies/administrator-access | jq
```

## Add members
```bash
curl -sk -H "api-token: $TOKEN" -H "Content-Type: application/json" https://localhost/apis/iam/v2/policies/administrator-access/members:add -d @administrator-access-members-add.json | jq
```

## Create and assign "ingest" token to ingest policy
```bash
sudo chef-automate iam token create ingest
curl -sk -H "api-token: $TOKEN" -H "Content-Type: application/json" https://localhost/apis/iam/v2/policies/administrator-access/members:add -d '{"members":["token:ingest"]}' | jq
```

## Replace members
```bash
curl -sk -H "api-token: $TOKEN" -H "Content-Type: application/json" https://localhost/apis/iam/v2/policies/administrator-access/members -d @administrator-access-members-add.json -X PUT | jq
```

## Create projects
```bash
curl -sk -H "api-token: $TOKEN" -H "Content-Type: application/json" https://localhost/apis/iam/v2/projects -d '{"id": "development", "name": "Development"}' | jq
```

## List project rules
```bash
curl -sk -H "api-token: $TOKEN" -H "Content-Type: application/json" https://localhost/apis/iam/v2/projects/development/rules | jq
```

## Create project rules
```bash
curl -sk -H "api-token: $TOKEN" -H "Content-Type: application/json" https://localhost/apis/iam/v2/projects/development/rules -d @project-development-rules.json | jq
```

## Apply project rules
```bash
curl -sk -H "api-token: $TOKEN" https://localhost/apis/iam/v2/apply-rules -X POST | jq
```
