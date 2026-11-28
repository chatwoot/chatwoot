import { MESSAGE_TYPE } from 'shared/constants/messages';
import { email as emailValidator } from '@vuelidate/validators';
import { splitEmailAddresses } from 'shared/helpers/emailHelper';

export const validEmailsByComma = value => {
  if (!value.length) return true;
  const emails = splitEmailAddresses(value);
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
