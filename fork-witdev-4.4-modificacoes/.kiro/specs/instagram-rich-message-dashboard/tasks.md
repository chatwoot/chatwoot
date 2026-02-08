# Implementation Plan

## Timeline & DRI

- **Total Estimated Duration:** 3-4 sprints (6-8 weeks)
- **DRI:** Backend Developer + Frontend Developer
- **QA:** Parallel testing during development

## Rollback Checklist

- [ ] Disable SOCIALWISE_RICH_DASHBOARD feature flag

- [ ] Clear mapper cache: `Rails.cache.delete_matched("instagram_mapper:*")`
- [ ] Monitor error metrics for 24h post-rollback
- [ ] Revert feature branch if needed
- [ ] Verify text fallback rendering works correctly

## Implementation Tasks

- [x] 1. Create Instagram Renderer Mapper service

  - Implement Messages::InstagramRendererMapper class with payload conversion logic
  - Add support for Generic Template to cards conversion with title/description truncation

  - Add support for Button Template to single card conversion
  - Add support for Quick Replies to input_select conversion
  - Implement URL sanitization and validation for security
  - Add payload size validation (25KB limit) and element count limit (50 max)
  - Add cache mechanism with MD5 hash keys and 1-hour TTL
  - Include test fixtures for invalid URLs and oversized payloads
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 6.1, 6.3_

- [x] 2. Modify Instagram Rich Message Service for dashboard mirroring

  - Add mirror_rich_payload_to_dashboard method to Instagram::RichMessageService
  - Implement payload mirroring before Instagram API call using update_columns
  - Store content_type as enum integer in DB, ensure serializer converts to string
  - Add test to verify serializer converts :cards → "cards" for API responses
  - Add error handling and logging for mirror failures with unique message.id tracking
  - Verify skip_send_reply flag is applied during message creation
  - Implement backend feature flag checking for SOCIALWISE_RICH_DASHBOARD
  - _Requirements: 1.1, 1.2, 1.3, 5.1, 5.2, 5.3_

- [x] 3. Implement feature flag configuration and frontend exposure

  - Add SOCIALWISE_RICH_DASHBOARD to backend feature configuration
  - Support account-scoped flags using Feature.get(:flag, account_id) pattern for gradual rollout
  - Document flag reading pattern: Feature.get(:SOCIALWISE_RICH_DASHBOARD, account_id) in backend
  - Ensure feature flag is accessible in frontend via global config endpoint
  - Add flag checking capability in frontend components
  - Add rollback capability through flag toggle without redeploy
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 4. Create RichCards Vue component

  - Implement RichCards.vue component for rendering card carousels
  - Add support for images with lazy loading (loading="lazy") and async decoding (decoding="async") for better LCP
  - Implement link buttons with proper security attributes (target="\_blank", rel="noopener noreferrer")
  - Add postback buttons with BUS_EVENTS.RICH_POSTBACK or REST endpoint integration
  - Implement accessibility features (role, aria-label)
  - Add metrics tracking with unique message.id + renderer_error=true/false keys
  - Include HTML escaping for alt attributes and content
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 6.2_

- [x] 5. Handle QuickReplies rendering

  - Investigate existing InputSelectBubble component for items without submitted_values
  - If compatible, create alias/wrapper for QuickReplies instead of new component
  - If incompatible, implement QuickRepliesWrapper.vue for displaying quick reply options
  - Register wrapper in same namespace as existing bubbles to inherit styles automatically
  - Design component to show title and value pairs visually
  - Add proper styling and accessibility features
  - _Requirements: 3.1_

- [x] 6. Integrate rich components with message bubble system

  - Identify and modify existing message bubble component
  - Add conditional rendering based on content_type (cards, input_select)
  - Implement feature flag checking for SOCIALWISE_RICH_DASHBOARD with account scope
  - Add fallback to text rendering when flag is disabled or errors occur
  - Implement postback event handling via BUS_EVENTS.RICH_POSTBACK or REST endpoint
  - Emit postback events to conversation level for metrics and automation
  - _Requirements: 4.1, 4.2, 4.3, 5.4_


- [x] 7. Add comprehensive backend unit tests




  - Write unit tests for Messages::InstagramRendererMapper covering all payload types
  - Test URL sanitization, payload size limits (25KB), and element limits (50 max)
  - Test cache functionality with MD5 hash keys and TTL
  - Test title/description truncation and fallback scenarios
  - Include fixtures for invalid URLs and oversized payloads
  - Test unknown template_type scenarios → expect text fallback for future schema resilience
  - Write tests for Instagram::RichMessageService mirror functionality
  - Test content_type enum storage and string serialization
  - Verify skip_send_reply flag behavior and timing
  - Test unique message.id tracking for metrics correlation
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 5.1, 5.2, 5.3, 6.1, 6.3_

- [ ] 8. Add comprehensive frontend component tests

  - Write unit tests for RichCards.vue covering all rendering scenarios
  - Test image loading, error handling, and accessibility features
  - Test postback and link button functionality with event emission
  - Write tests for QuickReplies handling (wrapper or existing component)
  - Test metrics tracking with message.id correlation and error capture
  - Verify feature flag integration with account scoping and fallback behavior
  - Test HTML escaping and security attributes
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 6.2_

- [ ] 9. Create Storybook stories for visual testing

  - Create RichCards stories for Generic Template (multiple cards)
  - Create RichCards stories for Button Template (single card)
  - Create stories for error states and edge cases
  - Create "flag off" story showing text fallback for rollback validation
  - Create QuickReplies stories for different option counts
  - Add interactive controls for testing different data scenarios
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 10. Add integration and E2E tests (QA + Dev)

  - Write integration tests for complete message flow from service to frontend
  - Create Cypress E2E tests for feature flag on/off scenarios with account scoping
  - Test postback click events and BUS_EVENTS.RICH_POSTBACK emission
  - Test link opening behavior in new tabs
  - Verify message serialization includes correct content_type string format
  - Test conversation-level postback event handling and metrics
  - Validate rollback scenarios work correctly
  - _Requirements: 1.1, 1.2, 1.3, 3.4, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3_

- [ ] 11. Implement performance monitoring and metrics (Backend + Frontend - 1-2 days)

  - Add backend logging for mirror operations with performance tracking
  - Implement frontend metrics tracking with message.id correlation
  - Track component renders, errors, and postback events with unique keys
  - Add payload size monitoring and cache hit rate tracking
  - Create dashboard alerts for error rates and performance degradation
  - Optimize log output to avoid sensitive data exposure (use template_type instead of full payload)
  - _Requirements: 5.2, 5.3, 6.1, 6.3_

- [ ] 12. Security hardening and final validation
  - Conduct security review of URL sanitization and content escaping
  - Validate HTML escaping in Vue components (no v-html usage)
  - Test payload size limits (25KB) and element count limits (50 max) for DoS protection
  - Test zip-bomb scenarios with high element counts in small payloads
  - Verify external link security attributes are properly applied
  - Conduct final integration testing with feature flag scenarios
  - Perform Go/No-Go decision based on metrics and error rates
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

## ⚠️ IMP

ORTANT: NON-BREAKING IMPLEMENTATION

**CRITICAL PRINCIPLE: DO NOT MODIFY EXISTING WORKING FUNCTIONALITY**

This implementation is purely **additive** - we are only adding rich message visualization capabilities to the dashboard. The existing Chatwoot message system must remain completely untouched and functional.

### What We DON'T Touch:

- ❌ Existing message rendering logic
- ❌ Current message bubble components (unless adding conditional rich rendering)
- ❌ Message storage schema or database structure
- ❌ Existing Instagram API integration flow
- ❌ Current message serialization (except ensuring content_type string format)
- ❌ Any existing Vue components that work correctly

### What We DO Add:

- ✅ New Messages::InstagramRendererMapper service (completely new)
- ✅ New RichCards.vue component (completely new)
- ✅ New QuickRepliesWrapper.vue or alias (completely new)
- ✅ Mirror functionality in Instagram::RichMessageService (additive only)
- ✅ Feature flag for gradual rollout and easy rollback
- ✅ Conditional rendering in message bubbles (with fallback to existing behavior)

### Safety Measures:

1. **Feature Flag Control**: Everything behind SOCIALWISE_RICH_DASHBOARD flag
2. **Fallback Always Available**: Text content always preserved and displayed when rich rendering fails
3. **Additive Only**: No modifications to existing working code paths
4. **Rollback Ready**: Can disable feature instantly via flag toggle
5. **Backward Compatible**: All existing messages continue to work exactly as before

### Testing Strategy:

- Test that existing message rendering still works with flag OFF
- Test that new rich rendering works with flag ON
- Test graceful fallback when rich rendering fails
- Verify no regressions in existing functionality
