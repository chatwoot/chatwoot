# Implementation Plan

## Phase 1: Core Fixes (1-2 days)

- [x] 1. Test WhatsApp response processing with real payloads

  - Deploy existing code and test with actual WhatsApp interactive payload
  - Verify SendOnWhatsappService processes content_attributes correctly
  - Fix only what actually breaks in testing
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. Test and fix Instagram response processing

  - Verify `InstagramResponseProcessor.process` works correctly with SocialWise Flow payloads
  - Test with all three Instagram formats (GENERIC_TEMPLATE, BUTTON_TEMPLATE, QUICK_REPLIES)
  - Fix any issues with payload format compatibility
  - Ensure fallback message creation works properly
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [x] 3. Implement Facebook response processing

  - Create simple `process_facebook_response` method following existing pattern
  - Handle text messages and rich content appropriately
  - Add recipient ID handling if missing from payload
  - Test with basic Facebook message formats (docker exec chatwit-dev-rails-1 bundle exec)
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 4. Enhance button reaction processing

  - Verify existing `process_button_reaction` method works correctly
  - Add proper emoji handling for different channels
  - Ensure handoff processing works after reactions
  - Test button reaction flow end-to-end (docker exec chatwit-dev-rails-1 bundle exec)
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4_

## Phase 2: Testing & Validation (1 day)

- [x] 5. Create integration tests with real payloads

  - Test WhatsApp interactive messages with actual SocialWise Flow responses
  - Test Instagram rich messages with real payload formats
  - Test Facebook message processing (docker exec chatwit-dev-rails-1 bundle exec)
  - Test button reactions and handoff scenarios (docker exec chatwit-dev-rails-1 bundle exec)
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4_

- [x] 6. Add comprehensive error handling and logging

  - Wrap all processing methods in proper try-catch blocks
  - Add detailed logging for debugging and monitoring
  - Ensure fallback messages are created when processing fails
  - Test error scenarios and recovery mechanisms (docker exec chatwit-dev-rails-1 bundle exec)
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 7.1, 7.2, 7.3, 7.4_

- [x] 7. Implementar exibição de mensagens ricas do WhatsApp no dashboard

  - Criar `Messages::WhatsappRendererMapper` seguindo padrão do `Messages::InstagramRendererMapper`
  - Melhorar mapeamento no `Whatsapp::RichMessageService` para usar o novo mapper
  - Implementar conversão de payloads interativos WhatsApp (button, list) para formato Chatwoot (cards, input_select)
  - Adicionar cache e validação de payload similar ao mapper do Instagram
  - Integrar com componentes de dashboard existentes (RichCards.vue, QuickReplies.vue)
  - Testar com payloads reais do SocialWise Flow para WhatsApp interativo
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 8. Fix WhatsApp duplicate message issue in SendReplyJob
  - **Problem**: Interactive messages are being sent twice - once by `Whatsapp::RichMessageService` and once by `SendReplyJob`
  - **Root Cause**: Messages created by `SocialwiseFlowProcessorService` don't have `skip_send_reply: true` flag, so `after_create_commit` callback enqueues `SendReplyJob`
  - **Evidence**: Same internal message ID (38867) gets two different WhatsApp source_ids (wamid), proving two separate API calls
  - **Flow Analysis**:
    1. `SocialwiseFlowProcessorService` creates message without `skip_send_reply` flag
    2. `after_create_commit` callback enqueues `SendReplyJob`
    3. `SocialwiseFlowProcessorService` calls `Whatsapp::RichMessageService` (first send)
    4. `SendReplyJob` processes and calls `Whatsapp::SendOnWhatsappService` (second send)
  - **Solution**:
    - Add `skip_send_reply: true` to `additional_attributes` when creating interactive messages in `SocialwiseFlowProcessorService`
    - Ensure only `Whatsapp::RichMessageService` sends interactive messages
    - Add validation to prevent double sending
  - **Testing**:
    - Test with SocialWise Flow interactive messages
    - Verify only one message appears in WhatsApp chat
    - Confirm single `wamid` in logs per message
    - Verify `skip_send_reply` flag prevents `SendReplyJob` enqueueing
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

## Phase 3: Final Validation (1 day)

- [ ] 9. End-to-end testing and deployment validation
  - Test complete flow from SocialWise Flow webhook to message delivery
  - Verify handoff functionality works correctly
  - Test with multiple channels simultaneously (docker exec chatwit-dev-rails-1 bundle exec rspec)
  - Validate logging and error reporting
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3, 6.4, 7.1, 7.2, 7.3, 7.4_
