import {
  processVariable,
  buildWhatsAppProcessedParams,
  findComponentByType,
  COMPONENT_TYPES,
  MEDIA_FORMATS,
  renderTemplatePreview,
} from '@chatwoot/utils';

// Re-export shared helpers for dashboard consumers (must also import above —
// `export { X } from` alone does not bind X in this module's scope).
export { MEDIA_FORMATS, COMPONENT_TYPES, findComponentByType, processVariable, renderTemplatePreview };

export const DEFAULT_LANGUAGE = 'en';
export const DEFAULT_CATEGORY = 'UTILITY';

export const allKeysRequired = value => {
  const keys = Object.keys(value);
  return keys.every(key => value[key]);
};

export const replaceTemplateVariables = (templateText, processedParams) => {
  return templateText.replace(/{{([^}]+)}}/g, (match, variable) => {
    const variableKey = variable.trim();
    return processedParams.body?.[variableKey] || `{{${variableKey}}}`;
  });
};

// Media header / buttons are derived inside the shared helper.
export const buildTemplateParameters = template =>
  buildWhatsAppProcessedParams(template);

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
