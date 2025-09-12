// Constants
export const DEFAULT_LANGUAGE = 'en';
export const DEFAULT_CATEGORY = 'UTILITY';
export const COMPONENT_TYPES = {
  HEADER: 'HEADER',
  BODY: 'BODY',
  BUTTONS: 'BUTTONS',
};
export const MEDIA_FORMATS = ['IMAGE', 'VIDEO', 'DOCUMENT'];
export const UPLOAD_CONFIG = {
  IMAGE: { accept: 'image/jpeg,image/jpg,image/png' },
  VIDEO: { accept: 'video/mp4' },
  DOCUMENT: { accept: 'application/pdf' },
};

// Variable parsing regexes
export const POSITIONAL_VARIABLE_REGEX = /\{\{(\d+)\}\}/g;
export const NAMED_VARIABLE_REGEX = /\{\{([a-zA-Z][a-zA-Z0-9_]*)\}\}/g;
export const GENERIC_VARIABLE_REGEX = /\{\{([^}]+)\}\}/g;

export const findComponentByType = (template, type) =>
  template.components?.find(component => component.type === type);

export const processVariable = str => {
  return str.replace(/{{|}}/g, '');
};

export const extractPositionalVariables = text => {
  const matches = [...text.matchAll(POSITIONAL_VARIABLE_REGEX)];
  return matches.map(match => parseInt(match[1], 10));
};

export const extractNamedVariables = text => {
  const matches = [...text.matchAll(NAMED_VARIABLE_REGEX)];
  return matches.map(match => match[1]);
};

export const hasPositionalVariables = text => {
  return POSITIONAL_VARIABLE_REGEX.test(text);
};

export const hasNamedVariables = text => {
  return NAMED_VARIABLE_REGEX.test(text);
};

export const allKeysRequired = value => {
  const keys = Object.keys(value);
  return keys.every(key => value[key]);
};

export const replaceTemplateVariables = (templateText, processedParams) => {
  return templateText.replace(GENERIC_VARIABLE_REGEX, (match, variable) => {
    const variableKey = processVariable(variable);
    return processedParams.body?.[variableKey] || `{{${variable}}}`;
  });
};

export const buildTemplateParameters = (template, hasMediaHeaderValue) => {
  const allVariables = {};

  const bodyComponent = findComponentByType(template, COMPONENT_TYPES.BODY);
  const headerComponent = findComponentByType(template, COMPONENT_TYPES.HEADER);

  if (!bodyComponent) return allVariables;

  const templateString = bodyComponent.text;

  // Process body variables
  const matchedVariables = templateString.match(GENERIC_VARIABLE_REGEX);
  if (matchedVariables) {
    allVariables.body = {};
    matchedVariables.forEach(variable => {
      const key = processVariable(variable);
      allVariables.body[key] = '';
    });
  }

  if (hasMediaHeaderValue) {
    if (!allVariables.header) allVariables.header = {};
    allVariables.header.media_url = '';
    allVariables.header.media_type = headerComponent.format.toLowerCase();
  }

  // Process button variables
  const buttonComponents = template.components.filter(
    component => component.type === COMPONENT_TYPES.BUTTONS
  );

  buttonComponents.forEach(buttonComponent => {
    if (buttonComponent.buttons) {
      buttonComponent.buttons.forEach((button, index) => {
        // Handle URL buttons with variables
        if (button.type === 'URL' && button.url && button.url.includes('{{')) {
          const buttonVars = button.url.match(GENERIC_VARIABLE_REGEX) || [];
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
      });
    }
  });

  return allVariables;
};

export const parsePositionalVariables = (
  text,
  maxVariables = Infinity,
  existingExamples = []
) => {
  const examples = [...existingExamples];
  if (hasNamedVariables(text)) {
    return {
      processedText: text,
      examples: [],
      error: {
        key: 'NAMED_IN_POSITIONAL',
      },
    };
  }

  let count = 0;

  const processedText = text.replace(POSITIONAL_VARIABLE_REGEX, () => {
    count += 1;
    if (count > maxVariables) {
      return '';
    }
    return `{{${count}}}`;
  });

  if (examples.length > count) {
    examples.splice(count);
  }

  for (let i = examples.length; i < count; i += 1) {
    examples.push('');
  }

  return { processedText, examples, error: {} };
};

export const parseNamedVariables = (text, maxVariables, existingExamples) => {
  if (hasPositionalVariables(text)) {
    return {
      processedText: text,
      examples: [],
      error: {
        key: 'POSITIONAL_IN_NAMED',
      },
    };
  }

  const error = {};

  const variableNames = extractNamedVariables(text);
  const uniqueNames = new Set(...variableNames);

  if (variableNames.length !== uniqueNames.size) {
    error.key = 'DUPLICATE_VARIABLES';
  } else if (variableNames.length > maxVariables) {
    error.key = 'MAX_VARIABLES_EXCEEDED';
    error.data = { count: maxVariables };
  }

  // Create examples array based on unique variables
  const examples = Array.from(uniqueNames).map(param_name => ({
    param_name,
    example:
      existingExamples.find(ex => ex && ex.param_name === param_name)
        ?.example || '',
  }));

  return {
    processedText: text,
    examples,
    error,
  };
};

/**
 * @param {string} text
 * @param {string} parameterType
 * @param {number} maxVariables
 * @param {Array} existingExamples
 * @returns {{
 *   processedText: string,
 *   examples: Array<{param_name: string, example: string}>,
 *   error: {key?: string, data?: Record<string, any>}
 * }}
 */
export const parseTemplateVariables = (
  text,
  parameterType,
  maxVariables,
  existingExamples
) => {
  if (parameterType === 'positional') {
    return parsePositionalVariables(text, maxVariables, existingExamples);
  }
  return parseNamedVariables(text, maxVariables, existingExamples);
};

export const buildExamplePropertyByParameterType = (
  exampleData,
  componentType,
  parameterType
) => {
  const positionalKey = `${componentType}_text`;
  const namedKey = `${componentType}_text_named_params`;

  const hasVariables =
    parameterType === 'positional'
      ? exampleData[positionalKey]?.length > 0
      : exampleData[namedKey]?.length > 0;

  if (!hasVariables) return null;

  return parameterType === 'positional'
    ? { [positionalKey]: exampleData[positionalKey] }
    : { [namedKey]: exampleData[namedKey] };
};

export const generateTemplateComponents = (templateData, parameterType) => {
  const components = [];
  const { header, body, footer, buttons } = templateData;

  if (header.enabled) {
    let data = {};
    if (header.format === 'TEXT') {
      data = {
        format: header.format,
        text: header.text,
      };
      const example = buildExamplePropertyByParameterType(
        header.example,
        'header',
        parameterType
      );
      if (example) {
        data.example = example;
      }
    } else if (MEDIA_FORMATS.includes(header.format)) {
      data = {
        format: header.format,
        media: {
          blob_id: header.media.blobId,
        },
      };
    } else {
      // LOCATION
      data = {
        format: header.format,
      };
    }
    components.push({
      type: header.type,
      ...data,
    });
  }

  // Body component
  const bodyComponent = {
    type: body.type,
    text: body.text,
  };

  const example = buildExamplePropertyByParameterType(
    body.example,
    'body',
    parameterType
  );
  if (example) {
    bodyComponent.example = example;
  }

  components.push(bodyComponent);

  if (footer.enabled) {
    components.push({
      type: footer.type,
      text: footer.text,
    });
  }

  if (buttons.length) {
    components.push({
      type: COMPONENT_TYPES.BUTTONS,
      buttons: [...buttons],
    });
  }

  return components;
};

export const validateTemplateData = templateData => {
  const { header, body, footer } = templateData;

  // Body is required and must have text without errors
  if (body.error || !body.text) return false;

  // Header validation (if enabled)
  if (header.enabled) {
    const invalidHeaderText = header.format === 'TEXT' && !header.text?.length;
    const invalidHeaderMedia =
      MEDIA_FORMATS.includes(header.format) && !header.media?.blobId;

    if (header.error || invalidHeaderText || invalidHeaderMedia) {
      return false;
    }
  }

  // Footer validation (if enabled)
  if (footer.enabled && !footer.text) return false;

  return true;
};
