export const generateBotMessageContent = (
  contentType,
  contentAttributes,
  noResponseText = 'No response'
) => {
  if (contentType === 'input_select') {
    const { submitted_values: submittedValues = [] } = contentAttributes;
    const [selectedOption] = submittedValues;

    if (selectedOption && selectedOption.title) {
      return `<strong>${selectedOption.title}</strong>`;
    }
  } else if (contentType === 'input_email') {
    const { submitted_email: submittedEmail = '' } = contentAttributes;
    if (submittedEmail) {
      return `<strong>${submittedEmail}</strong>`;
    }
  } else if (contentType === 'form') {
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
  }
  return '';
};
