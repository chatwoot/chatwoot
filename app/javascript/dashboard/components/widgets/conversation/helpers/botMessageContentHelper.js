const generateInputSelectContent = (contentType, contentAttributes) => {
  const { submitted_values: submittedValues = [] } = contentAttributes;
  const [selectedOption] = submittedValues;

  if (selectedOption && selectedOption.title) {
    return `<strong>${selectedOption.title}</strong>`;
  }
  return '';
};

const generateInputEmailContent = (contentType, contentAttributes) => {
  const { submitted_email: submittedEmail = '' } = contentAttributes;
  if (submittedEmail) {
    return `<strong>${submittedEmail}</strong>`;
  }
  return '';
};

const generateFormContent = (
  contentType,
  contentAttributes,
  noResponseText
) => {
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

export const generateBotMessageContent = (
  contentType,
  contentAttributes,
  noResponseText = 'No response'
) => {
  const contentTypeMethods = {
    input_select: generateInputSelectContent,
    input_email: generateInputEmailContent,
    form: generateFormContent,
  };

  const contentTypeMethod = contentTypeMethods[contentType];
  if (contentTypeMethod && typeof contentTypeMethod === 'function') {
    return contentTypeMethod(contentType, contentAttributes, noResponseText);
  }
  return '';
};
