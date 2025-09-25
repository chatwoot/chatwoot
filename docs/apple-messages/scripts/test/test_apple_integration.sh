#!/bin/bash

# Apple Messages for Business Integration Verification Script
echo "🔍 Apple Messages for Business Integration Verification"
echo "======================================================"
echo

# Test 1: Check InboxesController allowed_channel_types
echo "1. Testing InboxesController Integration..."
if grep -q "apple_messages_for_business" app/controllers/api/v1/accounts/inboxes_controller.rb; then
    echo "   ✅ apple_messages_for_business is in allowed_channel_types"
else
    echo "   ❌ apple_messages_for_business missing from allowed_channel_types"
fi

# Test 2: Check InboxesController channel_type_from_params
if grep -q "Channel::AppleMessagesForBusiness" app/controllers/api/v1/accounts/inboxes_controller.rb; then
    echo "   ✅ Channel::AppleMessagesForBusiness is in channel_type_from_params"
else
    echo "   ❌ Channel::AppleMessagesForBusiness missing from channel_type_from_params"
fi

echo

# Test 3: Check SendReplyJob service registration
echo "2. Testing SendReplyJob Integration..."
if grep -q "Channel::AppleMessagesForBusiness.*AppleMessagesForBusiness::SendOnAppleMessagesForBusinessService" app/jobs/send_reply_job.rb; then
    echo "   ✅ Apple Messages service is registered in SendReplyJob"
else
    echo "   ❌ Apple Messages service missing from SendReplyJob"
fi

echo

# Test 4: Check webhook routes
echo "3. Testing Webhook Routes Configuration..."
if grep -q "webhooks/apple_messages_for_business" config/routes.rb; then
    echo "   ✅ Apple Messages webhook routes are configured"
    
    # Count webhook routes
    route_count=$(grep -c "apple_messages_for_business" config/routes.rb)
    echo "   📊 Found $route_count Apple Messages routes"
else
    echo "   ❌ Apple Messages webhook routes missing"
fi

echo

# Test 5: Check frontend inbox types
echo "4. Testing Frontend Inbox Integration..."
if grep -q "APPLE_MESSAGES_FOR_BUSINESS.*Channel::AppleMessagesForBusiness" app/javascript/dashboard/helper/inbox.js; then
    echo "   ✅ Apple Messages inbox type is registered"
else
    echo "   ❌ Apple Messages inbox type missing"
fi

if grep -q "i-ri-apple" app/javascript/dashboard/helper/inbox.js; then
    echo "   ✅ Apple Messages icons are configured"
else
    echo "   ❌ Apple Messages icons missing"
fi

echo

# Test 6: Check useInbox composable
echo "5. Testing Frontend Composable Integration..."
if grep -q "INTERACTIVE_MESSAGES.*interactiveMessages" app/javascript/dashboard/composables/useInbox.js; then
    echo "   ✅ Interactive messages feature is defined"
else
    echo "   ❌ Interactive messages feature missing"
fi

if grep -q "APPLE_MESSAGES_FOR_BUSINESS.*REPLY_TO" app/javascript/dashboard/composables/useInbox.js; then
    echo "   ✅ Apple Messages is in REPLY_TO feature map"
else
    echo "   ❌ Apple Messages missing from REPLY_TO feature map"
fi

if grep -q "INTERACTIVE_MESSAGES.*APPLE_MESSAGES_FOR_BUSINESS" app/javascript/dashboard/composables/useInbox.js; then
    echo "   ✅ Apple Messages supports interactive messages"
else
    echo "   ❌ Apple Messages interactive messages support missing"
fi

if grep -q "isAnAppleMessagesForBusinessChannel" app/javascript/dashboard/composables/useInbox.js; then
    echo "   ✅ Apple Messages channel composable function exists"
else
    echo "   ❌ Apple Messages channel composable function missing"
fi

echo

# Test 7: Check for Apple Messages model files
echo "6. Testing Core Model Files..."
if [ -f "app/models/channel/apple_messages_for_business.rb" ]; then
    echo "   ✅ Apple Messages channel model exists"
else
    echo "   ❌ Apple Messages channel model missing"
fi

if [ -f "app/services/apple_messages_for_business/send_on_apple_messages_for_business_service.rb" ]; then
    echo "   ✅ Apple Messages send service exists"
else
    echo "   ❌ Apple Messages send service missing"
fi

if [ -f "app/controllers/webhooks/apple_messages_for_business_controller.rb" ]; then
    echo "   ✅ Apple Messages webhook controller exists"
else
    echo "   ❌ Apple Messages webhook controller missing"
fi

echo

# Test 8: Check frontend components
echo "7. Testing Frontend Components..."
if [ -f "app/javascript/dashboard/routes/dashboard/settings/inbox/channels/AppleMessagesForBusiness.vue" ]; then
    echo "   ✅ Apple Messages channel setup component exists"
else
    echo "   ❌ Apple Messages channel setup component missing"
fi

if [ -f "app/javascript/dashboard/components-next/message/bubbles/AppleListPicker.vue" ]; then
    echo "   ✅ Apple List Picker bubble component exists"
else
    echo "   ❌ Apple List Picker bubble component missing"
fi

if [ -f "app/javascript/dashboard/components/widgets/conversation/ReplyBox/AppleMessagesComposer.vue" ]; then
    echo "   ✅ Apple Messages composer component exists"
else
    echo "   ❌ Apple Messages composer component missing"
fi

echo

# Summary
echo "📊 Integration Status Summary"
echo "============================"

# Count checks
total_checks=0
passed_checks=0

# Backend checks (5)
backend_files=(
    "app/models/channel/apple_messages_for_business.rb"
    "app/services/apple_messages_for_business/send_on_apple_messages_for_business_service.rb" 
    "app/controllers/webhooks/apple_messages_for_business_controller.rb"
    "app/jobs/webhooks/apple_messages_for_business_events_job.rb"
    "db/migrate/20250914105926_create_channel_apple_messages_for_business.rb"
)

echo "Backend Files:"
for file in "${backend_files[@]}"; do
    total_checks=$((total_checks + 1))
    if [ -f "$file" ]; then
        echo "   ✅ $file"
        passed_checks=$((passed_checks + 1))
    else
        echo "   ❌ $file"
    fi
done

# Frontend checks (3)
frontend_files=(
    "app/javascript/dashboard/routes/dashboard/settings/inbox/channels/AppleMessagesForBusiness.vue"
    "app/javascript/dashboard/components-next/message/bubbles/AppleListPicker.vue"
    "app/javascript/dashboard/components/widgets/conversation/ReplyBox/AppleMessagesComposer.vue"
)

echo "Frontend Files:"
for file in "${frontend_files[@]}"; do
    total_checks=$((total_checks + 1))
    if [ -f "$file" ]; then
        echo "   ✅ $file"
        passed_checks=$((passed_checks + 1))
    else
        echo "   ❌ $file"
    fi
done

echo

# Calculate completion percentage
completion_percentage=$(( (passed_checks * 100) / total_checks ))

echo "🎯 Overall Status: $passed_checks/$total_checks checks passed ($completion_percentage%)"

if [ $completion_percentage -eq 100 ]; then
    echo "✅ Apple Messages for Business integration is FULLY CONFIGURED!"
    echo "   The channel should now be available in Chatwoot's inbox creation flow."
elif [ $completion_percentage -ge 80 ]; then
    echo "⚠️  Apple Messages for Business integration is MOSTLY COMPLETE"
    echo "   Minor issues need to be resolved."
else
    echo "❌ Apple Messages for Business integration needs significant work"
    echo "   Multiple components are missing."
fi

echo
echo "🚀 Next Steps:"
echo "   1. Restart the Chatwoot server to load the changes"
echo "   2. Navigate to Settings > Inboxes > Add Inbox"
echo "   3. Look for 'Apple Messages for Business' in the channel options"
echo "   4. Test channel creation with valid MSP credentials"