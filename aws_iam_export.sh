#!/bin/bash

# AWS IAM Export Script
# Exports account authorization details to JSON file

OUTPUT_FILE="${1:-account_auth.json}"

echo "Exporting AWS IAM account authorization details to $OUTPUT_FILE..."
aws iam get-account-authorization-details > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "Export completed successfully."
    echo "File size: $(wc -c < "$OUTPUT_FILE") bytes"
else
    echo "Export failed."
    exit 1
fi
