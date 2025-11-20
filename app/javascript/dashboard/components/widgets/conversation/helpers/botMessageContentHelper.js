import {
  CSAT_RATINGS,
  CSAT_FORMATS,
} from '../../../../../shared/constants/messages';

const generateInputSelectContent = contentAttributes => {
  const { submitted_values: submittedValues = [] } = contentAttributes;
  const [selectedOption] = submittedValues;

  if (selectedOption && selectedOption.title) {
    return `<strong>${selectedOption.title}</strong>`;
  }
  return '';
};

const generateInputEmailContent = contentAttributes => {
  const { submitted_email: submittedEmail = '' } = contentAttributes;
  if (submittedEmail) {
    return `<strong>${submittedEmail}</strong>`;
  }
  return '';
};

const generateInputPhoneContent = contentAttributes => {
  const { submitted_phone: submittedPhone = '' } = contentAttributes;
  if (submittedPhone) {
    return `<strong>${submittedPhone}</strong>`;
  }
  return '';
};

const generateFormContent = (contentAttributes, { noResponseText }) => {
  const { items, submitted_values: submittedValues = [] } = contentAttributes;
  if (submittedValues.length) {
    const submittedObject = submittedValues.reduce((acc, keyValuePair) => {
      acc[keyValuePair.name] = keyValuePair.value;
      return acc;
    }, {});
    let formMessageContent = '';
    items.forEach(item => {
      formMessageContent += `<div>${item.label}</div>`;
      const response = submittedObject[item.name] || noResponseText;
      formMessageContent += `<strong>${response}</strong><br/><br/>`;
    });
    return formMessageContent;
  }
  return '';
};

const generateCSATContent = (
  contentAttributes,
  { ratingTitle, feedbackTitle }
) => {
  const {
    submitted_values: { csat_survey_response: surveyResponse = {} } = {},
    csat_format: csatFormat = 'emoji_5_scale',
  } = contentAttributes;
  const { rating, feedback_message } = surveyResponse || {};

  let messageContent = '';
  if (rating) {
    const isYesNoFormat = csatFormat === CSAT_FORMATS.YES_NO;
    let ratingDisplay = '';

    if (isYesNoFormat) {
      ratingDisplay = rating === 5 ? 'Yes' : 'No';
    } else {
      // For emoji format, show emoji
      const [ratingObject = {}] = CSAT_RATINGS.filter(
        csatRating => csatRating.value === rating
      );
      ratingDisplay = ratingObject.emoji;
    }

    messageContent += `<div><strong>${ratingTitle}</strong></div>`;
    messageContent += `<p>${ratingDisplay}</p>`;
  }
  if (feedback_message) {
    messageContent += `<div><strong>${feedbackTitle}</strong></div>`;
    messageContent += `<p>${feedback_message}</p>`;
  }
  return messageContent;
};

export const generateBotMessageContent = (
  contentType,
  contentAttributes,
  {
    noResponseText = 'No response',
    csat: { ratingTitle = 'Rating', feedbackTitle = 'Feedback' } = {},
  } = {}
) => {
  const contentTypeMethods = {
    input_select: generateInputSelectContent,
    input_email: generateInputEmailContent,
    input_phone: generateInputPhoneContent,
    form: generateFormContent,
    input_csat: generateCSATContent,
  };

  const contentTypeMethod = contentTypeMethods[contentType];
  if (contentTypeMethod && typeof contentTypeMethod === 'function') {
    return contentTypeMethod(contentAttributes, {
      noResponseText,
      ratingTitle,
      feedbackTitle,
    });
  }
  return '';
};
