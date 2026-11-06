#!/bin/bash
set -e

# Validate developer's application.yaml against JSON Schema
APP_FILE="${1:-application.yaml}"
SCHEMA_FILE="platform/schema/application.schema.json"

if command -v ajv &> /dev/null; then
  ajv validate -s "$SCHEMA_FILE" -d "$APP_FILE"
else
  # Fallback: python jsonschema
  python3 -c "
  import json, jsonschema
  with open('$SCHEMA_FILE') as f: schema = json.load(f)
  with open('$APP_FILE') as f: data = json.load(f)
  jsonschema.validate(data, schema)
  print('Schema validation passed')
  "
fi   