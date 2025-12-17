#!/bin/bash

# Example curl request for WhatsApp Template API endpoint
# Replace the values below with your actual values

# Configuration
API_URL="http://localhost:3000/api/v1/ai/whatsapp_template"
API_TOKEN="studio_sYlX6svvhtrisOoSEM9yRRTDAeebrvBs"  # Replace with your ALOOSTUDIO_API_TOKEN
CONVERSATION_ID=203  # Replace with actual conversation ID (database ID, not display_id)
TEMPLATE_NAME="shop_catalog"  # Replace with your template name
TEMPLATE_LANGUAGE="en"  # Replace with template language code

# Example 1: Simple body parameters
curl -X POST "${API_URL}" \
  -H "Content-Type: application/json" \
  -H "X-Api-Token: ${API_TOKEN}" \
  -d '{
    "conversation_id": '${CONVERSATION_ID}',
    "template_name": "'${TEMPLATE_NAME}'",
    "template_language": "'${TEMPLATE_LANGUAGE}'",
    "template_params": {
      "body": {
        "1": "Shopify store"
      }
    }
  }'

echo -e "\n\n---\n\n"

# Example 2: Multiple body parameters
curl -X POST "${API_URL}" \
  -H "Content-Type: application/json" \
  -H "X-Api-Token: ${API_TOKEN}" \
  -d '{
    "conversation_id": '${CONVERSATION_ID}',
    "template_name": "'${TEMPLATE_NAME}'",
    "template_language": "'${TEMPLATE_LANGUAGE}'",
    "template_params": {
      "body": {
        "1": "First parameter",
        "2": "Second parameter",
        "3": "Third parameter"
      }
    }
  }'

echo -e "\n\n---\n\n"

# Example 3: With header (media)
curl -X POST "${API_URL}" \
  -H "Content-Type: application/json" \
  -H "X-Api-Token: ${API_TOKEN}" \
  -d '{
    "conversation_id": '${CONVERSATION_ID}',
    "template_name": "'${TEMPLATE_NAME}'",
    "template_language": "'${TEMPLATE_LANGUAGE}'",
    "template_params": {
      "header": {
        "media_url": "https://example.com/image.jpg",
        "media_type": "image"
      },
      "body": {
        "1": "Shopify store"
      }
    }
  }'

echo -e "\n\n---\n\n"

# Example 4: With buttons
curl -X POST "${API_URL}" \
  -H "Content-Type: application/json" \
  -H "X-Api-Token: ${API_TOKEN}" \
  -d '{
    "conversation_id": '${CONVERSATION_ID}',
    "template_name": "'${TEMPLATE_NAME}'",
    "template_language": "'${TEMPLATE_LANGUAGE}'",
    "template_params": {
      "body": {
        "1": "Shopify store"
      },
      "buttons": [
        {
          "type": "url",
          "parameter": "https://example.com"
        }
      ]
    }
  }'

echo -e "\n\n---\n\n"

# Example 5: With namespace (if required)
curl -X POST "${API_URL}" \
  -H "Content-Type: application/json" \
  -H "X-Api-Token: ${API_TOKEN}" \
  -d '{
    "conversation_id": '${CONVERSATION_ID}',
    "template_name": "'${TEMPLATE_NAME}'",
    "template_language": "'${TEMPLATE_LANGUAGE}'",
    "template_namespace": "your_namespace_here",
    "template_params": {
      "body": {
        "1": "Shopify store"
      }
    }
  }'


