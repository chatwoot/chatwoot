# Implementation Plan

- [x] 1. Create SocialWise webhook enhancer service

  - Create new service class at `lib/integrations/socialwise/webhook_enhancer_service.rb`
  - Implement `enhance_payload` class method that adds socialwise-chatwit data to webhook payloads
  - Implement `socialwise_active?` class method to check if SocialWise integration is enabled for an account
  - Implement private `build_socialwise_data` method to construct the socialwise-chatwit data structure
  - Add comprehensive error handling with fallback data for all methods
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 3.5, 6.1, 6.2, 6.4_

- [x] 2. Implement SocialWise data structure generation

  - Create method to extract WhatsApp identifiers (wamid, whatsapp_id, contact_source)
  - Create method to extract contact data (id, name, phone, email, custom_attributes)
  - Create method to extract conversation data (id, status, assignee_id, timestamps)
  - Create method to extract message data (id, content, content_type, message_type, timestamps)
  - Create method to extract inbox data (id, name, channel_type)
  - Create method to extract the WhatsApp api_key from the inbox's provider_config or any other methods.
  - Create method to extract account data (id, name)
  - Create method to build metadata section with socialwise_active, is_whatsapp_channel, payload_version, timestamp
  - _Requirements: 3.2, 3.3, 3.4,3.5, 3.6_

- [x] 3. Add error handling and fallback mechanisms AND WhatsApp api_key in socialwise

- Implement try-catch blocks around all data extraction methods, including the retrieval of the api_key
  -Create method to extract the WhatsApp api_key from the inbox's provider_config.

  - Implement try-catch blocks around all data extraction methods
  - Create fallback data structure for when full data collection fails
  - Ensure that if the api_key cannot be retrieved (e.g., provider_config is missing or nil), the process continues gracefully and logs the specific issue.
  - Add logging for all error scenarios
  - Ensure webhook delivery is never blocked by SocialWise failures
  - _Requirements: 2.1, 3.2, 6.1, 6.2, 6.3, 6.4_

- [x] 4. Enhance webhook listener with SocialWise support

  - Modify `deliver_account_webhooks` method in `app/listeners/webhook_listener.rb`
  - Add SocialWise enhancement before ACCESS_TOKEN processing
  - Integrate SocialWise webhook enhancer service
  - Ensure both ACCESS_TOKEN and socialwise-chatwit can coexist in payloads
  - _Requirements: 2.1, 2.2, 5.1, 5.2_

- [x] 5. Update Dialogflow processor service

  - Nota: Adicionados requisitos 2.1 e 3.2 para garantir que a integração com o Dialogflow considere a api_key como parte dos "dados do SocialWise".
  - Modify `lib/integrations/dialogflow/processor_service.rb` to use shared SocialWise service
  - Replace current `build_whatsapp_payload_data` method with call to new service
  - Maintain backward compatibility for existing Dialogflow payload structure
  - Remove Dialogflow dependency from SocialWise activation check
  - _Requirements: 2.1, 3.2, 4.1, 4.2, 4.3_

- [x] 6. Remove Dialogflow dependency from SocialWise setup

  - Update `lib/tasks/setup_socialwise.rake` to remove Dialogflow requirement checks
  - Remove warning messages about needing Dialogflow configuration
  - Update setup process to work independently of Dialogflow
  - _Requirements: 1.1, 1.3_

- [x] 7. Create comprehensive unit tests for SocialWise service

  - Write tests for build_socialwise_data method, including scenarios with and without api_key.
  - Write tests for `enhance_payload` method with various payload types
  - Write tests for `socialwise_active?` method with different hook configurations
  - Write tests for `build_socialwise_data` method with complete data scenarios
  - Write tests for error handling and fallback data generation
  - Write tests for edge cases (missing data, invalid configurations)
  - _Requirements: 1.1, 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 3.5, 6.1, 6.2, 6.4_

- [x] 8. Create integration tests for webhook enhancement

  - Write tests for webhook listener with SocialWise enhancement enabled
  - Write tests for coexistence of ACCESS_TOKEN and socialwise-chatwit data
  - Write tests for webhook delivery when SocialWise data collection fails
  - Write tests for different webhook event types (message_created, conversation_updated, etc.)
  - _Requirements: 2.1, 2.2, 5.1, 5.2, 6.1, 6.3_

- [x] 9. Create backward compatibility tests for Dialogflow

  - Write tests to ensure existing Dialogflow payload structure is maintained
  - Write tests for originalDetectIntentRequest.payload data inclusion
  - Write tests to verify Dialogflow functionality remains unaffected
  - Write tests for Dialogflow webhook processing with SocialWise active
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 10. Update SocialWise setup task tests

  - Write tests for setup task without Dialogflow dependency
  - Write tests for independent SocialWise activation
  - Write tests for hook creation and configuration
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 11. Create end-to-end webhook tests

  - Write tests for complete webhook flow from event trigger to delivery
  - Write tests for webhook payload structure validation
  - Write tests for multiple webhook types with SocialWise enhancement
  - Write tests for webhook delivery performance with enhanced payloads
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 12. Implement webhook payload validation


  - Create validation methods for socialwise-chatwit data structure
  - Add validation for required fields in SocialWise data
  - Create validation for data types and formats
  - Add validation tests for all data structure components
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_
