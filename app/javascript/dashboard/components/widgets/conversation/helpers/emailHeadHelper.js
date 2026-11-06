import { MESSAGE_TYPE } from 'shared/constants/messages';
import { email as emailValidator } from '@vuelidate/validators';

// A recipient list reaches the server comma, semicolon or space separated, and its entries may
// carry a display name (`Jane Smith <jane@example.com>`). `EmailHelper#process_email_string`
// accepts all of those and rejects the rest, so the composer has to agree with it or it shows no
// error for input whose send then fails. A comma or semicolon separates recipients unless it is
// inside a quoted display name; whitespace separates them only when there is no display name to
// keep spaces for. Only an odd run of backslashes escapes the quote that follows it, so the
// display name `"Ops \\"` closes.
const splitRecipients = value => {
  if (!/[<"]/.test(value))
    return { parts: value.trim().split(/[\s,;]+/), unterminated: false };

  const parts = [];
  let current = '';
  let quoted = false;
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
  // `Mail::AddressList` rejects an unmatched quote outright, so a scan that ends inside one is
  // not a recipient list at all.
  return { parts, unterminated: quoted };
};

// Where a recipient's `<...>` address opens, and whether an `@` comes before it -- both asked
// of text outside any quoted display name, in one pass. A quoted name may hold either character
// (`"support@example.com" <agent@example.org>`, `"Ops <West>" <ops@example.org>`), and only an
// odd run of backslashes escapes the quote that follows it. `open` is -1 for a bare address.
const scanRecipient = text => {
  let quoted = false;
  let backslashes = 0;
  let at = false;
  let open = -1;
  text.split('').some((char, i) => {
    if (char === '"' && backslashes % 2 === 0) quoted = !quoted;
    if (!quoted && char === '<') {
      open = i;
      return true;
    }
    if (!quoted && char === '@') at = true;
    backslashes = char === '\\' ? backslashes + 1 : 0;
    return false;
  });
  return { open, at };
};

// The address `recipient` is sent to -- `Jane Smith <jane@example.com>` is sent to
// `jane@example.com` -- or `null` for a form the server will not accept. `null` rather than the
// text itself: `emailValidator` accepts some malformed recipients whole, and takes seconds to
// decide on others, so the shapes the server rejects are better not handed to it at all.
const addressOf = recipient => {
  const trimmed = recipient.trim();
  const { open, at } = scanRecipient(trimmed);
  if (open < 0) return trimmed;
  // The address has to close the recipient: `A <a@x> B <b@y>` is two entries with no separator
  // between them, and taking only the first would lose B.
  if (!trimmed.endsWith('>')) return null;
  const inner = trimmed.slice(open + 1, -1);
  if (inner.includes('<') || inner.includes('>')) return null;
  // An `@` before the address, outside any quoted display name, is a swallowed recipient.
  if (at) return null;
  return inner.trim();
};

export const validEmailsByComma = value => {
  if (!value.length) return true;
  const { parts, unterminated } = splitRecipients(value);
  if (unterminated) return false;
  return parts.every(part => {
    const email = addressOf(part);
    return email !== null && emailValidator.$validator(email);
  });
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
