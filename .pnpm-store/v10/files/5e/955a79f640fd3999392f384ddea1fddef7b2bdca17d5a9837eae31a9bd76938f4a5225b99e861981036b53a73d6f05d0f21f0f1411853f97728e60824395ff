export type EmailAttributes = {
  bcc: string[] | null;
  cc: string[] | null;
  content_type: string;
  date: string;
  from: string[] | null;
  html_content: {
    full: string;
    reply: string;
    quoted: string;
  };
  in_reply_to: null;
  message_id: string;
  multipart: boolean;
  number_of_attachments: number;
  subject: string;
  text_content: {
    full: string;
    reply: string;
    quoted: string;
  };
  to: string[] | null;
};

export type IncomingContentAttribute = {
  email: EmailAttributes | null;
};

export type OutgoingContentAttribute = {
  cc_emails: string[] | null;
  bcc_emails: string[] | null;
  to_emails: string[] | null;
  external_error: string;
};

export type MessageContentAttributes =
  | IncomingContentAttribute
  | OutgoingContentAttribute;

export type MessageConversation = {
  id: number;
  assignee_id: number;
  custom_attributes: Record<string, any>;
  first_reply_created_at: number;
  waiting_since: number;
  status: string;
  unread_count: number;
  last_activity_at: number;
  contact_inbox: { source_id: string };
};

export type MessageAttachment = {
  id: number;
  message_id: number;
  file_type: string;
  account_id: number;
  extension: null;
  data_url: string;
  thumb_url: string;
  file_size: number;
  width: null;
  height: null;
};

export type MessageSender = {
  custom_attributes: {};
  email: null;
  id: number;
  identifier: null;
  name: string;
  phone_number: null;
  thumbnail: string;
  type: string;
};

export enum MessageType {
  INCOMING = 0,
  OUTGOING = 1,
  ACTIVITY = 2,
  TEMPLATE = 3,
}

export type BaseEmailMessage = {
  id: number;
  content: null;
  account_id: number;
  inbox_id: number;
  conversation_id: number;
  message_type: MessageType;
  created_at: number;
  updated_at: string;
  private: boolean;
  status: string;
  source_id: null;
  content_type: string;
  content_attributes: MessageContentAttributes;
  sender_type: string;
  sender_id: number;
  external_source_ids: {};
  additional_attributes: {};
  processed_message_content: null;
  sentiment: {};
  conversation: MessageConversation;
  attachments: MessageAttachment[];
  sender: MessageSender;
};

export type IncomingEmailMessage = BaseEmailMessage & {
  message_type: MessageType.INCOMING;
  content_attributes: IncomingContentAttribute;
};

export type OutgoingEmailMessage = BaseEmailMessage & {
  message_type: MessageType.OUTGOING;
  content_attributes: OutgoingContentAttribute;
};

export type EmailMessage = IncomingEmailMessage | OutgoingEmailMessage;
