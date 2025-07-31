export const processVariable = str => {
  return str.replace(/{{|}}/g, '');
};

export const allKeysRequired = value => {
  const keys = Object.keys(value);
  return keys.every(key => value[key]);
};

export const replaceTemplateVariables = (templateText, processedParams) => {
  return templateText.replace(/{{([^}]+)}}/g, (match, variable) => {
    const variableKey = processVariable(variable);
    return processedParams.body?.[variableKey] || `{{${variable}}}`;
  });
};

export const buildTemplateParameters = (template, hasMediaHeaderValue) => {
  const allVariables = {};

  const bodyComponent = template.components.find(
    component => component.type === 'BODY'
  );
  const headerComponent = template.components.find(
    component => component.type === 'HEADER'
  );

  if (!bodyComponent) return allVariables;

  const templateString = bodyComponent.text;

  // Process body variables
  const matchedVariables = templateString.match(/{{([^}]+)}}/g);
  if (matchedVariables) {
    allVariables.body = {};
    matchedVariables.forEach(variable => {
      const key = processVariable(variable);
      // Special handling for authentication templates
      if (template?.category === 'AUTHENTICATION') {
        if (
          key === '1' ||
          key.toLowerCase().includes('otp') ||
          key.toLowerCase().includes('code')
        ) {
          allVariables.body.otp_code = '';
        } else if (
          key === '2' ||
          key.toLowerCase().includes('expiry') ||
          key.toLowerCase().includes('minute')
        ) {
          allVariables.body.expiry_minutes = '';
        } else {
          allVariables.body[key] = '';
        }
      } else {
        allVariables.body[key] = '';
      }
    });
  }

  if (hasMediaHeaderValue) {
    if (!allVariables.header) allVariables.header = {};
    allVariables.header.media_url = '';
    allVariables.header.media_type = headerComponent.format.toLowerCase();
  }

  // Process button variables
  const buttonComponents = template.components.filter(
    component => component.type === 'BUTTONS'
  );

  buttonComponents.forEach(buttonComponent => {
    if (buttonComponent.buttons) {
      buttonComponent.buttons.forEach((button, index) => {
        // Skip button parameter inputs for authentication templates
        // as they are auto-populated with OTP codes
        if (template?.category !== 'AUTHENTICATION') {
          // Handle URL buttons with variables
          if (
            button.type === 'URL' &&
            button.url &&
            button.url.includes('{{')
          ) {
            const buttonVars = button.url.match(/{{([^}]+)}}/g) || [];
            if (buttonVars.length > 0) {
              if (!allVariables.buttons) allVariables.buttons = [];
              allVariables.buttons[index] = {
                type: 'url',
                parameter: '',
                url: button.url,
                variables: buttonVars.map(v => processVariable(v)),
              };
            }
          }

          // Handle copy code buttons
          if (button.type === 'COPY_CODE') {
            if (!allVariables.buttons) allVariables.buttons = [];
            allVariables.buttons[index] = {
              type: 'copy_code',
              parameter: '',
            };
          }
        }
      });
    }
  });

  return allVariables;
};

export const populateAuthenticationButtonParameters = (
  template,
  processedParams
) => {
  const finalParams = { ...processedParams };

  if (template?.category === 'AUTHENTICATION' && finalParams.buttons) {
    // Deep copy the buttons array to avoid mutating the original
    finalParams.buttons = finalParams.buttons.map(button => ({ ...button }));

    finalParams.buttons.forEach((button, index) => {
      if (button.type === 'url') {
        // For authentication templates, auto-populate URL button parameter with OTP
        if (finalParams.body?.['1']) {
          finalParams.buttons[index].parameter = finalParams.body['1'];
        } else if (finalParams.body?.otp_code) {
          finalParams.buttons[index].parameter = finalParams.body.otp_code;
        }
      }
    });
  }

  return finalParams;
};
