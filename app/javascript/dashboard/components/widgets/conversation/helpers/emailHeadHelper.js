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
  // Only an odd run of backslashes escapes the quote that follows it: the display name
  // `"Ops \\"` ends in a literal backslash, and its closing quote still closes.
  let backslashes = 0;
  value.split('').forEach(char => {
    if (char === '"' && backslashes % 2 === 0) quoted = !quoted;
    if ((char === ',' || char === ';') && !quoted) {
      parts.push(current);
      current = '';
    } else {
      current += char;
    }
    backslashes = char === '\\' ? backslashes + 1 : 0;
  });
  parts.push(current);
  return parts;
};

// `Jane Smith <jane@example.com>` is addressed to `jane@example.com`. An unquoted display name
// carrying an `@` is a recipient swallowed into it (`a@x.com Jane <b@y.com>`), which the server
// rejects in `EmailHelper#swallowed_address?`; that is returned whole so it fails validation
// here too, rather than passing the composer and 422-ing on send.
const addressOf = recipient => {
  const trimmed = recipient.trim();
  const angled = trimmed.match(/<([^<>]*)>/);
  if (!angled) return trimmed;
  const phrase = trimmed.slice(0, trimmed.indexOf('<')).trim();
  if (phrase.includes('@') && !phrase.startsWith('"')) return trimmed;
  return angled[1].trim();
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
