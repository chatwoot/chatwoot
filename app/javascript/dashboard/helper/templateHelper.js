import { url } from '@vuelidate/validators';
import { processVariable, buildWhatsAppProcessedParams } from '@chatwoot/utils';

// Constants and pure template helpers are shared with the mobile app via
// @chatwoot/utils so the logic lives in one place.
export {
  MEDIA_FORMATS,
  COMPONENT_TYPES,
  findComponentByType,
  processVariable,
  renderTemplatePreview,
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

// The media-header flag is derived from the template inside the shared helper;
// the second argument is kept for backwards-compatible call sites.
export const buildTemplateParameters = template =>
  buildWhatsAppProcessedParams(template);

// 360dialog templates may not have a provider ID.
export const getTemplateKey = template =>
  template.id ?? `${template.name}:${template.language}`;

export const isValidTemplateMediaUrl = value =>
  !value || (/^https?:\/\//i.test(value) && url.$validator(value));

// Match the legacy body-only formats still supported by TemplateParameterConverterService.
export const normalizeTemplateParameters = (params = {}) => {
  const componentKeys = ['body', 'header', 'footer', 'buttons'];
  const isParameterMap = value =>
    value == null || (typeof value === 'object' && !Array.isArray(value));
  const validButtons =
    params.buttons == null ||
    (Array.isArray(params.buttons) &&
      params.buttons.every(
        button => button == null || (isParameterMap(button) && button.type)
      ));
  if (
    componentKeys.some(key => key in params) &&
    isParameterMap(params.body) &&
    isParameterMap(params.header) &&
    validButtons
  ) {
    return params;
  }
  const entries = Array.isArray(params)
    ? params.map((value, index) => [String(index + 1), String(value ?? '')])
    : Object.entries(params).map(([key, value]) => [key, String(value ?? '')]);
  return entries.length ? { body: Object.fromEntries(entries) } : {};
};
