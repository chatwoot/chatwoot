Requirements Document
Introduction
This feature completes the SocialWise Flow integration by implementing response processing for rich messages and bot handoff functionality. SocialWise Flow is an independent AI-powered bot service that processes messages and returns rich message formats for WhatsApp and Instagram channels, along with handoff capabilities.
The integration already sends webhooks to SocialWise Flow and receives responses, but needs to process the returned payloads to:
1.	Send rich interactive messages (buttons, carousels, quick replies) to WhatsApp and Instagram
2.	Handle button clicks with emoji reactions and contextual responses
3.	Process handoff actions to transfer conversations from bot to human agents
4.	Maintain message delivery tracking and proper conversation flow
Requirements
Requirement 1
User Story: As a customer support system, I want to process SocialWise Flow responses for WhatsApp interactive messages, so that customers can receive rich button and list interfaces.
Acceptance Criteria
1.	WHEN SocialWise Flow returns a WhatsApp interactive payload THEN the system SHALL create an outgoing message with content_type 'integrations'
2.	WHEN WhatsApp interactive payload is received THEN the system SHALL call Whatsapp::RichMessageService to send the interactive content
3.	WHEN WhatsApp interactive message is sent THEN the system SHALL support both button (≤3 options) and list (>3 options) formats
4.	WHEN WhatsApp interactive message fails to send THEN the system SHALL log the error and continue processing
Requirement 2
User Story: As a customer support system, I want to process SocialWise Flow responses for Instagram rich messages, so that customers can receive template-based interactive content.
Acceptance Criteria
1.	WHEN SocialWise Flow returns an Instagram rich payload THEN the system SHALL create an outgoing message with content_type 'integrations'
2.	WHEN Instagram rich payload is received THEN the system SHALL call Instagram::RichMessageService to send the rich content
3.	WHEN Instagram rich message is sent THEN the system SHALL support GENERIC_TEMPLATE, BUTTON_TEMPLATE, and QUICK_REPLIES formats
4.	WHEN Instagram rich message fails to send THEN the system SHALL log the error and continue processing
Requirement 3
User Story: As a customer support system, I want to process button click responses with emoji reactions, so that customers receive immediate feedback when interacting with bot messages.
Acceptance Criteria
1.	WHEN SocialWise Flow returns a button_reaction response THEN the system SHALL extract the emoji and response text
2.	WHEN button_reaction is for WhatsApp THEN the system SHALL send both emoji reaction and contextual response text
3.	WHEN button_reaction is for Instagram THEN the system SHALL send emoji reaction and simple response text
4.	WHEN button_reaction processing fails THEN the system SHALL log the error and continue with handoff if specified
Requirement 4
User Story: As a customer support system, I want to process handoff actions from SocialWise Flow, so that conversations can be transferred from bot to human agents when needed.
Acceptance Criteria
1.	WHEN SocialWise Flow returns action: "handoff" THEN the system SHALL call conversation.bot_handoff! to transfer to human agent
2.	WHEN bot_handoff is executed THEN the conversation status SHALL change from 'pending' to 'open'
3.	WHEN handoff occurs THEN the system SHALL dispatch CONVERSATION_BOT_HANDOFF event
4.	WHEN handoff is processed THEN subsequent messages SHALL NOT be sent to SocialWise Flow
Requirement 5
User Story: As a customer support system, I want to handle Facebook Messenger responses from SocialWise Flow, so that Facebook channel users can receive rich message content.
Acceptance Criteria
1.	WHEN SocialWise Flow returns a Facebook payload THEN the system SHALL create an outgoing message with content_type 'integrations'
2.	WHEN Facebook payload contains simple text THEN the system SHALL create a regular text message
3.	WHEN Facebook payload contains rich content THEN the system SHALL call Facebook::RawDeliverService with the payload
4.	WHEN Facebook payload is missing recipient THEN the system SHALL add the contact's source_id as recipient
Requirement 6
User Story: As a customer support system, I want comprehensive error handling for SocialWise Flow response processing, so that message delivery remains reliable even when processing fails.
Acceptance Criteria
1.	WHEN SocialWise Flow response processing fails THEN the system SHALL log detailed error information
2.	WHEN rich message sending fails THEN the system SHALL continue processing other response elements
3.	WHEN handoff action fails THEN the system SHALL log the error but not block message processing
4.	WHEN response format is invalid THEN the system SHALL create a fallback text message with the raw response
Requirement 7
User Story: As a customer support system, I want proper message tracking and conversation flow, so that all bot responses are recorded and displayed correctly in the dashboard.
Acceptance Criteria
1.	WHEN SocialWise Flow response is processed THEN the system SHALL create outgoing messages with proper message_type
2.	WHEN rich messages are sent THEN they SHALL be recorded with appropriate content_attributes for dashboard display
3.	WHEN messages are created THEN they SHALL include proper account_id and inbox_id for tracking
4.	WHEN conversation state changes THEN the system SHALL maintain proper conversation flow and status