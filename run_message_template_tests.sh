#!/bin/bash

# Message Template Feature - Test Runner Script
# This script runs all tests we created for the Message Template feature

echo "🧪 Running Message Template Feature Tests..."
echo "============================================="

# Run all tests in one command
echo "Running all Message Template tests..."
bundle exec rspec \
  spec/models/message_template_spec.rb \
  spec/controllers/api/v1/accounts/message_templates_controller_spec.rb \
  spec/policies/message_template_policy_spec.rb \
  spec/services/whatsapp/template_creation_service_spec.rb \
  spec/services/whatsapp/template_formatter_service_spec.rb \
  spec/services/whatsapp/template_sync_service_spec.rb \
  spec/services/whatsapp/providers/whatsapp_cloud_service_spec.rb

echo "✅ Message Template tests completed!"

# Alternative: Run tests by category
echo ""
echo "📝 Individual test commands:"
echo "============================================="
echo "Model tests:"
echo "bundle exec rspec spec/models/message_template_spec.rb"
echo ""
echo "Controller tests:"
echo "bundle exec rspec spec/controllers/api/v1/accounts/message_templates_controller_spec.rb"
echo ""
echo "Policy tests:"
echo "bundle exec rspec spec/policies/message_template_policy_spec.rb"
echo ""
echo "Template Creation Service tests:"
echo "bundle exec rspec spec/services/whatsapp/template_creation_service_spec.rb"
echo ""
echo "Template Formatter Service tests:"
echo "bundle exec rspec spec/services/whatsapp/template_formatter_service_spec.rb"
echo ""
echo "Template Sync Service tests:"
echo "bundle exec rspec spec/services/whatsapp/template_sync_service_spec.rb"
echo ""
echo "WhatsApp Provider Service tests:"
echo "bundle exec rspec spec/services/whatsapp/providers/whatsapp_cloud_service_spec.rb"