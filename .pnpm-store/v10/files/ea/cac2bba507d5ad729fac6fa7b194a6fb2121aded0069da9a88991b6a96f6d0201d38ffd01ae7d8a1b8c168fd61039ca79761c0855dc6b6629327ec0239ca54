import {
  EmailMessage,
  MessageType,
  IncomingEmailMessage,
  OutgoingEmailMessage,
} from './types/message';

export function getRecipients(
  lastEmail: EmailMessage,
  conversationContact: string,
  inboxEmail: string,
  forwardToEmail: string
) {
  let to = [] as string[];
  let cc = [] as string[];
  let bcc = [] as string[];

  // Reset emails if there's no lastEmail
  if (!lastEmail) {
    return { to, cc, bcc };
  }

  // Extract values from lastEmail and current conversation context
  const { message_type: messageType } = lastEmail;

  const isIncoming = messageType === MessageType.INCOMING;

  let emailAttributes = {} as {
    cc: string[] | null;
    bcc: string[] | null;
    from: string[] | null;
    to: string[] | null;
  };

  if (isIncoming) {
    const {
      content_attributes: contentAttributes,
    } = lastEmail as IncomingEmailMessage;
    const email = contentAttributes.email;
    emailAttributes = {
      cc: email?.cc || [],
      bcc: email?.bcc || [],
      from: email?.from || [],
      to: [],
    };
  } else {
    const {
      content_attributes: contentAttributes,
    } = lastEmail as OutgoingEmailMessage;

    const {
      cc_emails: ccEmails = [],
      bcc_emails: bccEmails = [],
      to_emails: toEmails = [],
    } = contentAttributes ?? {};

    emailAttributes = {
      cc: ccEmails,
      bcc: bccEmails,
      to: toEmails,
      from: [],
    };
  }

  let isLastEmailFromContact = false;
  // this will be false anyway if the last email was outgoing
  isLastEmailFromContact =
    isIncoming && (emailAttributes.from ?? []).includes(conversationContact);

  if (isIncoming) {
    // Reply to sender if incoming
    to.push(...(emailAttributes.from ?? []));
  } else {
    // Otherwise, reply to the last recipient (for outgoing message)
    // If there is no to_emails, reply to the conversation contact
    to.push(...(emailAttributes.to ?? [conversationContact]));
  }

  // Start building the cc list, including additional recipients
  // If the email had multiple recipients, include them in the cc list
  cc = emailAttributes.cc ? [...emailAttributes.cc] : [];
  // Only include 'to' recipients in cc for incoming emails, not for outgoing
  if (Array.isArray(emailAttributes.to) && isIncoming) {
    cc.push(...emailAttributes.to);
  }

  // Add the conversation contact to cc if the last email wasn't sent by them
  // Ensure the message is an incoming one
  if (!isLastEmailFromContact && isIncoming) {
    cc.push(conversationContact);
  }

  // Process BCC: Remove conversation contact from bcc as it is already in cc
  bcc = (emailAttributes.bcc || []).filter(
    emailAddress => emailAddress !== conversationContact
  );

  // Filter out undesired emails from cc:
  // - Remove conversation contact from cc if they sent the last email
  // - Remove inbox and forward-to email to prevent loops
  // - Remove emails matching the reply UUID pattern
  const replyUUIDPattern = /^reply\+([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/i;
  cc = cc.filter(email => {
    if (email === conversationContact && isLastEmailFromContact) {
      return false;
    }
    if (email === inboxEmail || email === forwardToEmail) {
      return false;
    }
    if (replyUUIDPattern.test(email)) {
      return false;
    }
    return true;
  });

  bcc = bcc.filter(email => {
    if (
      email === inboxEmail ||
      email === forwardToEmail ||
      replyUUIDPattern.test(email)
    ) {
      return false;
    }

    return true;
  });

  // Deduplicate each recipient list by converting to a Set then back to an array
  to = Array.from(new Set(to));
  cc = Array.from(new Set(cc));
  bcc = Array.from(new Set(bcc));

  return {
    to,
    cc,
    bcc,
  };
}
