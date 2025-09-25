# Apple Messages for Business Integration

This directory contains all documentation, scripts, and data files related to the Apple Messages for Business (AMB) integration in Chatwoot.

## Directory Structure

```
docs/apple-messages/
├── README.md                           # This file
├── APPLE_MESSAGES_I18N_REPORT.md      # Internationalization analysis
├── APPLE_MSP_MISSING_FEATURES_CHECKLIST.md  # Missing features tracking
├── APPLE_MSP_OUTGOING_SERVICES.md     # Outgoing services documentation
├── implementation/                     # Implementation guides
│   ├── APPLE_MESSAGES_FOR_BUSINESS_INTEGRATION_PLAN.md
│   ├── APPLE_MSP_COMPLETE_IMPLEMENTATION_GUIDE.md
│   ├── APPLE_MSP_FRONTEND_INTEGRATION.md
│   ├── APPLE_MSP_PHASE_1_IMPLEMENTATION.md
│   ├── APPLE_MESSAGES_LIST_PICKER_IMPLEMENTATION.md
│   └── APPLE_RICH_LINK_FAVICON_IMPLEMENTATION.md
├── guides/                            # User and configuration guides
│   ├── APPLE_MESSAGES_TROUBLESHOOTING_GUIDE.md
│   ├── APPLE_MESSAGES_OAUTH2_APPLEPAY_CONFIGURATION_GUIDE.md
│   └── CHATWOOT_MESSAGING_CHANNEL_GUIDE.md
├── scripts/                           # Scripts and utilities
│   ├── test/                          # Test scripts
│   │   ├── test_apple_integration.sh
│   │   ├── test_apple_message_delivery.rb
│   │   ├── test_favicon_fallback.rb
│   │   ├── test_url_message_splitting.rb
│   │   ├── test_url_splitting.js
│   │   └── test_webhook_endpoint.rb
│   ├── debug/                         # Debug utilities
│   │   ├── debug_api_response.rb
│   │   ├── debug_attachment.rb
│   │   └── debug_time_picker_payload.rb
│   └── utilities/                     # Utility scripts
│       ├── check_apple_channels.rb
│       ├── check_apple_config.rb
│       ├── check_messages.rb
│       ├── update_apple_webhook_url.rb
│       ├── apple_messages_json_output.rb
│       ├── corrected_apple_messages_payloads.rb
│       └── compare_time_picker_formats.rb
└── data/                             # Sample data and test results
    ├── apple_messages_payloads.json
    ├── corrected_apple_messages_payloads.json
    ├── corrected_msp_test_results.json
    └── final_msp_test_results.json
```

## Quick Start

1. **Configuration**: Start with the configuration guide in `guides/APPLE_MESSAGES_OAUTH2_APPLEPAY_CONFIGURATION_GUIDE.md`
2. **Implementation**: Follow the main implementation plan in `implementation/APPLE_MESSAGES_FOR_BUSINESS_INTEGRATION_PLAN.md`
3. **Testing**: Use the test scripts in `scripts/apple-messages/test/` to validate your implementation
4. **Troubleshooting**: Refer to `guides/APPLE_MESSAGES_TROUBLESHOOTING_GUIDE.md` for common issues

## Key Implementation Files

### Backend Integration
- Channel model: `app/models/channel/apple_messages_for_business.rb`
- Controllers: `app/controllers/webhooks/apple_messages_for_business_controller.rb`
- Services: `app/services/apple_messages_for_business/`
- Jobs: `app/jobs/apple_messages_for_business/`

### Frontend Integration
- Channel setup: `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/AppleMessagesForBusiness.vue`
- Message components: `app/javascript/dashboard/components-next/message/bubbles/Apple*.vue`
- Rich link helper: `app/javascript/dashboard/helper/appleMessagesRichLink.js`

## Testing

Run the main integration test:
```bash
./docs/apple-messages/scripts/test/test_apple_integration.sh
```

Check Apple Messages configuration:
```bash
ruby docs/apple-messages/scripts/utilities/check_apple_config.rb
```

## Data Files

Sample payloads and test results are stored in `data/` for reference and testing purposes.

## Current Status

See `APPLE_MSP_MISSING_FEATURES_CHECKLIST.md` for current implementation status and missing features.