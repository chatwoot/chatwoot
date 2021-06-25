import { CSAT_RATINGS } from '../../../../../shared/constants/messages';

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
  } = contentAttributes;
  const { rating, feedback } = surveyResponse || {};

  let messageContent = '';
  if (rating) {
    const [ratingObject = {}] = CSAT_RATINGS.filter(
      csatRating => csatRating.value === rating
    );
    messageContent += `<div><strong>${ratingTitle}</strong></div>`;
    messageContent += `<p>${ratingObject.emoji}</p>`;
  }
  if (feedback) {
    messageContent += `<div><strong>${feedbackTitle}</strong></div>`;
    messageContent += `<p>${feedback}</p>`;
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
