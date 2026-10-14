import { MESSAGE_TYPE } from 'shared/constants/messages';
import { email as emailValidator } from '@vuelidate/validators';

// A recipient list reaches the server comma, semicolon or space separated, and its entries may
// carry a display name (`Jane Smith <jane@example.com>`). `EmailHelper#process_email_string`
// accepts all of those, so the composer has to accept the same set or it marks valid input
// invalid. A comma or semicolon separates recipients unless it is inside a quoted display name;
// whitespace separates them only when there is no display name to keep spaces for.
const splitRecipients = value => {
  if (!/[<"]/.test(value)) return value.trim().split(/[\s,;]+/);

  const parts = [];
  let current = '';
  let quoted = false;
  value.split('').forEach((char, i) => {
    const escaped = quoted && value[i - 1] === '\\';
    if (char === '"' && !escaped) quoted = !quoted;
    if ((char === ',' || char === ';') && !quoted) {
      parts.push(current);
      current = '';
    } else {
      current += char;
    }
  });
  parts.push(current);
  return parts;
};

// `Jane Smith <jane@example.com>` is addressed to `jane@example.com`.
const addressOf = recipient => {
  const angled = recipient.match(/<([^<>]*)>/);
  return (angled ? angled[1] : recipient).trim();
};

export const validEmailsByComma = value => {
  if (!value.length) return true;
  const emails = splitRecipients(value).map(addressOf);
  return emails.every(email => emailValidator.$validator(email));
};

export const getDefaultSubject = ({
  messages = [],
  additional_attributes: attributes,
}) => {
  const lastCustomSubject = messages
    .filter(message => message.message_type === MESSAGE_TYPE.OUTGOING)
    .map(message => message.content_attributes?.email?.subject)
    .findLast(Boolean);
  if (lastCustomSubject) return lastCustomSubject;

  return attributes?.mail_subject ? `Re: ${attributes.mail_subject}` : '';
};
