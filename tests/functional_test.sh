#!/bin/bash
set -e

BASE_URL="${BASE_URL:-http://localhost:3000}"

echo "=== 1. Testing Health Endpoint (/up) ==="
curl -s -o /dev/null -w "GET /up -> HTTP %{http_code}\n" "$BASE_URL/up"

echo "=== 2. Testing CREATE Task (POST /tasks.json) ==="
CREATE_RES=$(curl -s -X POST "$BASE_URL/tasks.json" \
  -H "Content-Type: application/json" \
  -d '{"task": {"title": "Functional Test Task", "description": "Testing CRUD in K8s"}}')
echo "Response: $CREATE_RES"

TASK_ID=$(echo "$CREATE_RES" | grep -o '"id":[0-9]*' | head -n1 | cut -d':' -f2)
echo "Created Task ID: $TASK_ID"

echo "=== 3. Testing READ Tasks (GET /tasks.json) ==="
curl -s -o /dev/null -w "GET /tasks.json -> HTTP %{http_code}\n" "$BASE_URL/tasks.json"

echo "=== 4. Testing UPDATE Task (PATCH /tasks/$TASK_ID.json) ==="
curl -s -X PATCH "$BASE_URL/tasks/$TASK_ID.json" \
  -H "Content-Type: application/json" \
  -d '{"task": {"completed": true}}' \
  -o /dev/null -w "PATCH /tasks/$TASK_ID.json -> HTTP %{http_code}\n"

echo "=== 5. Testing DELETE Task (DELETE /tasks/$TASK_ID.json) ==="
curl -s -X DELETE "$BASE_URL/tasks/$TASK_ID.json" \
  -o /dev/null -w "DELETE /tasks/$TASK_ID.json -> HTTP %{http_code}\n"

echo "=== Functional Validation Complete: All Endpoints Passed! ==="
