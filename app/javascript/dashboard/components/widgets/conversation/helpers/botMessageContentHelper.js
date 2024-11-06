import { CSAT_RATINGS } from '../../../../../shared/constants/messages';
import { useI18n } from 'dashboard/composables/useI18n';

const generateInputSelectContent = contentAttributes => {
  const { submitted_values: submittedValues = [] } = contentAttributes;
  const [selectedOption] = submittedValues;

  if (selectedOption && selectedOption.title) {
    return `<strong>${selectedOption.title}</strong>`;
  }
  return '';
};

const generateCalEventContent = (contentAttributes, { calEventResponse }) => {
  return `<strong>${calEventResponse}</strong>`;
};

const generateCalEventConfirmationContent = contentAttributes => {
  const { t } = useI18n();

  const { event_booker, event_organizer, event_scheduled_at } =
    contentAttributes.event_payload;
  const booker = event_booker.charAt(0).toUpperCase() + event_booker.slice(1);
  const organizer =
    event_organizer.charAt(0).toUpperCase() + event_organizer.slice(1);
  return t('CONVERSATION.CAL_EVENT_CONFIRMATION_RESPONSE', {
    booker,
    organizer,
    time: event_scheduled_at.time,
    date: event_scheduled_at.date,
    timezone: event_scheduled_at.timezone,
  });
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
  const { rating, feedback_message } = surveyResponse || {};

  let messageContent = '';
  if (rating) {
    const [ratingObject = {}] = CSAT_RATINGS.filter(
      csatRating => csatRating.value === rating
    );
    messageContent += `<div><strong>${ratingTitle}</strong></div>`;
    messageContent += `<p>${ratingObject.emoji}</p>`;
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
    calEventResponse = 'Calendar event sent',
  } = {}
) => {
  const contentTypeMethods = {
    input_select: generateInputSelectContent,
    input_email: generateInputEmailContent,
    form: generateFormContent,
    input_csat: generateCSATContent,
    cal_event: generateCalEventContent,
    cal_event_confirmation: generateCalEventConfirmationContent,
  };

  const contentTypeMethod = contentTypeMethods[contentType];
  if (contentTypeMethod && typeof contentTypeMethod === 'function') {
    return contentTypeMethod(contentAttributes, {
      noResponseText,
      ratingTitle,
      feedbackTitle,
      calEventResponse,
    });
  }
  return '';
};
