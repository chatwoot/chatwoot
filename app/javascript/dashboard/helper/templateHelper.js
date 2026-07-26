import { processVariable, buildWhatsAppProcessedParams } from '@chatwoot/utils';

// Constants and pure template helpers are shared with the mobile app via
// @chatwoot/utils so the logic lives in one place.
export {
  MEDIA_FORMATS,
  COMPONENT_TYPES,
  findComponentByType,
  processVariable,
} from '@chatwoot/utils';

export const DEFAULT_LANGUAGE = 'en';
export const DEFAULT_CATEGORY = 'UTILITY';

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

  const bodyComponent = findComponentByType(template, COMPONENT_TYPES.BODY);
  const headerComponent = findComponentByType(template, COMPONENT_TYPES.HEADER);

  if (!bodyComponent) return allVariables;

  const templateString = bodyComponent.text;

  // Process body variables
  const matchedVariables = templateString.match(/{{([^}]+)}}/g);
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

    // For document templates, include media_name field for filename support
    if (headerComponent.format.toLowerCase() === 'document') {
      allVariables.header.media_name = '';
    }
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
      });
    }
  });

  return allVariables;
};

/**
 * Snapshot of template BUTTONS for agent bubble UI after send.
 * Resolves dynamic URL / copy-code params from processedParams.buttons.
 * @returns {{ type: string, text: string, url?: string, phone_number?: string, copy_code?: string }[]}
 */
export const buildTemplateButtonsSnapshot = (
  template,
  processedParams = {}
) => {
  const buttonsComponent = findComponentByType(
    template,
    COMPONENT_TYPES.BUTTONS
  );
  if (!buttonsComponent?.buttons?.length) return [];

  return buttonsComponent.buttons.map((button, index) => {
    const snapshot = {
      type: button.type,
      text: button.text || '',
    };

    if (button.type === 'URL' && button.url) {
      let url = button.url;
      const buttonParam = processedParams.buttons?.[index];
      if (buttonParam?.parameter && url.includes('{{')) {
        url = url.replace(/{{([^}]+)}}/g, buttonParam.parameter);
      }
      snapshot.url = url;
    }

    if (button.type === 'PHONE_NUMBER' && button.phone_number) {
      snapshot.phone_number = button.phone_number;
    }

    if (button.type === 'COPY_CODE') {
      const buttonParam = processedParams.buttons?.[index];
      if (buttonParam?.parameter) {
        snapshot.copy_code = buttonParam.parameter;
      }
    }

    if (button.type === 'FLOW') {
      snapshot.flow = true;
    }

    return snapshot;
  });
};
