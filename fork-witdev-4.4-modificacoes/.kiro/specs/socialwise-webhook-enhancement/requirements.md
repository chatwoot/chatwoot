# Requirements Document

## Introduction

This feature enhances the existing SocialWise integration to include WhatsApp tokens and additional metadata in both Dialogflow webhooks and standard system webhooks. Currently, the SocialWise integration only works when Dialogflow is configured and only adds extra data to Dialogflow payloads. This enhancement will make the integration more flexible by:

1. Removing the dependency on Dialogflow configuration
2. Adding SocialWise data to all webhook types (not just Dialogflow)
3. Organizing the extra data under a dedicated "socialwise-chatwit" field
4. Maintaining backward compatibility with existing functionality

## Requirements

### Requirement 1

**User Story:** As a system administrator, I want to configure SocialWise integration independently of Dialogflow, so that I can use enhanced webhook data even without Dialogflow setup.

#### Acceptance Criteria

1. WHEN SocialWise integration is configured THEN the system SHALL allow activation without requiring Dialogflow integration
2. WHEN SocialWise hook is enabled THEN the system SHALL include extra metadata in all webhook payloads
3. WHEN SocialWise is active THEN the system SHALL NOT require Dialogflow hook to be present

### Requirement 2

**User Story:** As a webhook consumer, I want to receive WhatsApp tokens and metadata in all webhook types, so that I can process messages with full context regardless of the integration type.

#### Acceptance Criteria

1. WHEN SocialWise is active AND a webhook is triggered THEN the system SHALL include WhatsApp token in the payload
2. WHEN SocialWise is active THEN the system SHALL include contact custom attributes in webhook payloads
3. WHEN SocialWise is active THEN the system SHALL include conversation metadata in webhook payloads
4. WHEN SocialWise is active THEN the system SHALL include message metadata in webhook payloads

### Requirement 3

**User Story:** As a webhook consumer, I want SocialWise data organized under a dedicated field, so that I can easily identify and parse the enhanced metadata.

#### Acceptance Criteria

1. WHEN SocialWise data is included THEN the system SHALL place all extra data under a "socialwise-chatwit" field
2. WHEN "socialwise-chatwit" field is present THEN it SHALL contain WhatsApp identifiers (wamid, whatsapp_id)
3. WHEN "socialwise-chatwit" field is present THEN it SHALL contain contact information (name, phone, email, custom_attributes)
4. WHEN "socialwise-chatwit" field is present THEN it SHALL contain conversation metadata (id, status, assignee_id, timestamps)
5. WHEN "socialwise-chatwit" field is present THEN it SHALL contain message metadata (id, content, type, timestamps)

### Requirement 4

**User Story:** As a Dialogflow webhook consumer, I want to continue receiving SocialWise data in the originalDetectIntentRequest payload, so that my existing Dialogflow integrations remain functional.

#### Acceptance Criteria

1. WHEN SocialWise is active AND Dialogflow webhook is triggered THEN the system SHALL include SocialWise data in originalDetectIntentRequest.payload
2. WHEN Dialogflow webhook contains SocialWise data THEN it SHALL maintain the current payload structure for backward compatibility
3. WHEN Dialogflow webhook is processed THEN existing Dialogflow functionality SHALL remain unaffected

### Requirement 5

**User Story:** As a system administrator, I want to maintain existing ACCESS_TOKEN functionality, so that current webhook consumers continue to work without changes.

#### Acceptance Criteria

1. WHEN a webhook has include_access_token enabled THEN the system SHALL continue adding ACCESS_TOKEN to the payload root
2. WHEN both ACCESS_TOKEN and SocialWise are active THEN both SHALL be included in the webhook payload
3. WHEN ACCESS_TOKEN functionality is used THEN it SHALL work independently of SocialWise configuration

### Requirement 6

**User Story:** As a developer, I want comprehensive error handling for SocialWise data collection, so that webhook delivery remains reliable even when metadata collection fails.

#### Acceptance Criteria

1. WHEN SocialWise data collection fails THEN the system SHALL log the error and continue webhook delivery
2. WHEN SocialWise data collection fails THEN the system SHALL include a fallback payload with essential data
3. WHEN errors occur during SocialWise processing THEN the system SHALL NOT block webhook delivery
4. WHEN SocialWise encounters errors THEN the system SHALL include error information in the "socialwise-chatwit" field