export const isAFormMessage = message => message.content_type === 'form';
export const isASubmittedFormMessage = (message = {}) =>
  isAFormMessage(message) && !!message.content_attributes?.submitted_values;

export const MESSAGE_MAX_LENGTH = {
  GENERAL: 10000,
  // https://developers.facebook.com/docs/messenger-platform/reference/send-api#request
  FACEBOOK: 2000,
  // https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/messaging-api#send-a-text-message
  INSTAGRAM: 1000,
  // https://www.twilio.com/docs/glossary/what-sms-character-limit
  TWILIO_SMS: 320,
  // https://help.twilio.com/articles/360033806753-Maximum-Message-Length-with-Twilio-Programmable-Messaging
  TWILIO_WHATSAPP: 1600,
  // https://developers.facebook.com/docs/whatsapp/cloud-api/reference/messages#text-object
  WHATSAPP_CLOUD: 4096,
  // https://support.bandwidth.com/hc/en-us/articles/360010235373-What-are-Bandwidth-s-SMS-character-limits-and-concatenation-practices
  BANDWIDTH_SMS: 160,
  // https://core.telegram.org/bots/api#sendmessage
  TELEGRAM: 4096,
  LINE: 2000,
  EMAIL: 25000,
};
