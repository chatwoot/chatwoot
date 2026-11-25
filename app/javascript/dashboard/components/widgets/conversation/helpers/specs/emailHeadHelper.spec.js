import { validEmailsByComma, getDefaultSubject } from '../emailHeadHelper';

describe('#validEmailsByComma', () => {
  it('returns true when empty string is passed', () => {
    expect(validEmailsByComma('')).toEqual(true);
  });
  it('returns true when valid emails separated by comma is passed', () => {
    expect(validEmailsByComma('ni@njan.com,po@va.da')).toEqual(true);
  });
  it('returns false when one of the email passed is invalid', () => {
    expect(validEmailsByComma('ni@njan.com,pova.da')).toEqual(false);
  });
  it('strips spaces between emails before validating', () => {
    expect(validEmailsByComma('1@test.com  , 2@test.com')).toEqual(true);
  });
});

describe('#getDefaultSubject', () => {
  const outgoing = (subject, attributes = {}) => ({
    message_type: 1,
    content_attributes: { email: { subject } },
    ...attributes,
  });

  it('returns the conversation subject as a reply', () => {
    expect(
      getDefaultSubject({
        messages: [],
        additional_attributes: { mail_subject: 'Order status' },
      })
    ).toEqual('Re: Order status');
  });

  it('returns an empty string when the conversation has no subject', () => {
    expect(getDefaultSubject({ additional_attributes: {} })).toEqual('');
    expect(getDefaultSubject({ messages: [] })).toEqual('');
  });

  it('returns the subject of the last outgoing message that has one', () => {
    expect(
      getDefaultSubject({
        messages: [
          outgoing('Refund approved'),
          outgoing('Refund processed'),
          { message_type: 1, content_attributes: {} },
        ],
        additional_attributes: { mail_subject: 'Order status' },
      })
    ).toEqual('Refund processed');
  });

  it('ignores the subject of incoming messages', () => {
    expect(
      getDefaultSubject({
        messages: [
          {
            message_type: 0,
            content_attributes: { email: { subject: 'Changed by customer' } },
          },
        ],
        additional_attributes: { mail_subject: 'Order status' },
      })
    ).toEqual('Re: Order status');
  });
});
