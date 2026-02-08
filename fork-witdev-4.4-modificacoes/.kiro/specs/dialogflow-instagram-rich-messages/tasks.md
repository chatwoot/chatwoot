# Implementation Plan

- [x] 1. Create SocialWise Instagram Response Processor service

  - Create new service class at `lib/integrations/socialwise/instagram_response_processor.rb`
  - Implement `process` class method that receives socialwiseResponse data and message
  - Implement `route_message` private method to route based on message_format
  - Implement `validate_payload` method to validate payload structure for each format
  - Add comprehensive error handling with fallback to text messages
  - Add logging with [SOCIALWISE-INSTAGRAM-DIALOGFLOW] prefix for all operations
  - _Requirements: 1.1, 1.2, 1.3, 5.1, 5.2, 6.1, 6.2_

- [x] 2. Implement payload validation methods

  - Create `validate_generic_template` method to validate Generic Template payload structure
  - Create `validate_button_template` method to validate Button Template payload structure
  - Create `validate_quick_replies` method to validate Quick Replies payload structure
  - Implement validation for required fields, data types, and Instagram API constraints
  - Add validation for button limits (max 3 for templates, max 13 for quick replies)
  - Add validation for text length limits and URL format validation
  - _Requirements: 1.1, 2.1, 3.1, 4.1_

- [x] 3. Create Instagram Rich Message Service

  - Create new service class at `app/services/instagram/rich_message_service.rb` extending `Instagram::BaseSendService`
  - Implement constructor that accepts message and rich_payload parameters
  - Override `send_message` method to handle rich message content
  - Implement `rich_message_params` method to build Instagram API compatible message structure
  - Implement `template_format?` helper method to distinguish template vs quick reply formats
  - Reuse existing authentication, rate limiting, and error handling from parent class
  - _Requirements: 2.1, 3.1, 4.1, 7.1, 7.2, 7.3, 7.4_

- [x] 4. Implement Generic Template message sending

  - Create `send_generic_template` method in SocialWise Instagram Response Processor
  - Build Instagram API compatible Generic Template message structure
  - Handle multiple elements (carousel) with proper title, subtitle, image_url, and buttons
  - Support both postback and web_url button types with proper payload/URL handling
  - Integrate with Instagram Rich Message Service for actual API call
  - Add specific error handling and logging for Generic Template operations
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 6.3_

- [x] 5. Implement Button Template message sending

  - Create `send_button_template` method in SocialWise Instagram Response Processor
  - Build Instagram API compatible Button Template message structure
  - Handle text message with up to 3 buttons (postback and web_url types)
  - Ensure proper payload and URL handling for different button types
  - Integrate with Instagram Rich Message Service for actual API call
  - Add specific error handling and logging for Button Template operations
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 6.3_

- [x] 6. Implement Quick Replies message sending

  - Create `send_quick_replies` method in SocialWise Instagram Response Processor
  - Build Instagram API compatible Quick Replies message structure
  - Handle text message with quick reply options (up to 13 quick replies)
  - Ensure proper payload handling for quick reply selections
  - Integrate with Instagram Rich Message Service for actual API call
  - Add specific error handling and logging for Quick Replies operations
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 6.3_

- [x] 7. Enhance Dialogflow Processor Service with socialwiseResponse detection

  - Modify `process_response` method in `lib/integrations/dialogflow/processor_service.rb`
  - Add detection logic for socialwiseResponse in content_params
  - Implement priority rule: when socialwiseResponse is present, skip other messages in the same response
  - Add Instagram channel validation before processing rich messages
  - Integrate call to SocialWise Instagram Response Processor when socialwiseResponse is detected
  - Ensure existing Dialogflow functionality remains completely unaffected
  - _Requirements: 1.1, 1.2, 1.4, 5.1, 5.3, 5.4_

- [x] 8. Implement fallback mechanisms

  - Create `fallback_to_text_message` method in SocialWise Instagram Response Processor
  - Implement `extract_fallback_text` method to extract meaningful text from failed rich message payloads
  - Add fallback logic for unknown message formats with proper logging
  - Ensure fallback creates standard Chatwoot outgoing message when rich message processing fails
  - Add fallback for non-Instagram channels that receive socialwiseResponse
  - Test that fallback maintains conversation flow and doesn't break user experience
  - _Requirements: 1.4, 5.2, 6.2, 6.4_

- [x] 9. Add comprehensive logging and monitoring

  - Implement detailed logging for all socialwiseResponse processing steps
  - Add logging for payload validation results and failure reasons
  - Log Instagram API call details and response status for rich messages
  - Add performance logging for rich message processing time
  - Implement error logging with full context (message ID, conversation ID, account ID)
  - Add success logging with message format and recipient details
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 10. Create unit tests for SocialWise Instagram Response Processor

  - Write tests for `process` method with valid socialwiseResponse data
  - Write tests for `route_message` method with each supported message format
  - Write tests for payload validation methods with valid and invalid payloads

  - Write tests for error handling scenarios and fallback behavior
  - Write tests for unknown message format handling
  - Write tests for Instagram channel validation logic
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 5.1, 5.2_

- [x] 11. Create unit tests for Instagram Rich Message Service

  - Write tests for service initialization with message and rich_payload
  - Write tests for `rich_message_params` method with different payload formats
  - Write tests for `template_format?` helper method
  - Write tests for Instagram API integration using existing infrastructure
  - Write tests for error handling and integration with parent class error handling
  - Write tests for authentication and rate limiting behavior
    **Referências no Requirements:** Req 7 (AC1–AC4)
  - **Como testar (Docker):**
    ```bash
    docker-compose -f docker-compose.yaml -p chatwit-dev run --rm rails \
      bundle exec rspec spec/services/instagram/rich_message_service_spec.rb
    ```
  - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [x] 12. Create integration tests for rich message formats

  - Write tests for complete Generic Template flow from socialwiseResponse to Instagram API
  - Write tests for complete Button Template flow with different button types

  - Write tests for complete Quick Replies flow with multiple options
  - Write tests for payload validation integration with message sending
  - Write tests for error scenarios and fallback to text messages
  - Write tests for Instagram channel validation and non-Instagram channel handling
  - **Como testar (Docker):**
    docker-compose -f docker-compose.yaml -p chatwit-dev run --rm rails \
     bundle exec rspec spec/integration/instagram/rich_message_flow_spec.rb
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4_

- [x] 13. Create integration tests for Dialogflow processor enhancement

  - Write tests for socialwiseResponse detection in Dialogflow responses
  - Write tests for priority rule implementation (socialwiseResponse over text messages)
  - Write tests for integration with SocialWise Instagram Response Processor
  - Write tests ensuring existing Dialogflow functionality remains unaffected
  - Write tests for mixed scenarios (some messages with socialwiseResponse, others without)
  - Write tests for error handling when rich message processing fails

- **Referências no Requirements:** Req 2/3/4 (AC1), Req 5 (AC4), Req 7 (AC1)

  - **Como testar (Docker):**
    ```bash
    docker-compose -f docker-compose.yaml -p chatwit-dev run --rm rails \
      bundle exec rspec spec/e2e/instagram_rich_templates_spec.rb
    ```
  - _Requirements: 1.1, 1.2, 1.4, 5.1, 5.3, 5.4_

- [x] 14. Create end-to-end tests for complete rich message flow


  - Write tests simulating complete user interaction flow with Generic Templates
  - Write tests simulating complete user interaction flow with Button Templates
  - Write tests simulating complete user interaction flow with Quick Replies
  - Write tests for error scenarios and recovery mechanisms
  - Write tests for performance under load with multiple rich messages
  - Write tests for backward compatibility with existing Instagram messaging
  - **Referências no Requirements:** Req 2/3/4 (AC1), Req 5 (AC4), Req 7 (AC1)
  - **Como testar (Docker):**
    ```bash
    docker-compose -f docker-compose.yaml -p chatwit-dev run --rm rails \
      bundle exec rspec spec/e2e/instagram_rich_templates_spec.rb
    ```
  - _Requirements: 2.1, 3.1, 4.1, 5.4, 7.1_

- [x] 15. Implement Instagram channel validation and compatibility checks




  - Add method to verify message conversation is on Instagram channel before processing rich messages
  - Implement graceful handling for non-Instagram channels that receive socialwiseResponse

  - Add validation for Instagram channel configuration and access token availability
  - Ensure rich message processing only occurs for properly configured Instagram inboxes
  - Add logging for channel validation results and compatibility issues
  - Test compatibility with existing Instagram channel functionality

- **Como testar (Docker):**
  ```bash
  docker-compose -f docker-compose.yaml -p chatwit-dev run --rm rails \
    bundle exec rspec spec/validators/instagram_channel_validator_spec.rb
  ```
  - _Requirements: 5.1, 7.1, 7.2_
