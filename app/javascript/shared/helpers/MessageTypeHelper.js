export const isAFormMessage = message => message.content_type === 'form';
export const isASubmittedFormMessage = (message = {}) =>
  isAFormMessage(message) && !!message.content_attributes?.submitted_values;

export const MESSAGE_MAX_LENGTH = {
  GENERAL: 10000,
  FACEBOOK: 1000,
  TWILIO_SMS: 320,
  TWILIO_WHATSAPP: 1600,
  EMAIL: 25000,
};
