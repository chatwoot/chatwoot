import { TemplateTypeDetector } from './TemplateTypeDetector';
import {
  PLATFORMS,
  TWILIO_TYPE_PREFIX,
  WA_COMPONENT_TYPES,
  WA_PARAM_FORMATS,
} from './TemplateConstants';

/**
 * TemplateNormalizer - Convert platform-specific formats to unified structure
 */
export class TemplateNormalizer {
  static normalizeWhatsApp(template) {
    const components = template.components || [];

    return {
      id: template.id,
      name: template.name,
      platform: PLATFORMS.WHATSAPP,
      type: TemplateTypeDetector.detectWhatsAppType(template),
      parameterFormat: template.parameter_format || WA_PARAM_FORMATS.POSITIONAL,
      header: components.find(c => c.type === WA_COMPONENT_TYPES.HEADER),
      body: components.find(c => c.type === WA_COMPONENT_TYPES.BODY),
      footer: components.find(c => c.type === WA_COMPONENT_TYPES.FOOTER),
      buttons:
        components.find(c => c.type === WA_COMPONENT_TYPES.BUTTONS)?.buttons ||
        [],
      variables: this.extractWhatsAppVariables(template),
      category: template.category,
      language: template.language,
      originalTemplate: template,
    };
  }

  static normalizeTwilio(template) {
    const typeKey =
      template.template_type?.replace(TWILIO_TYPE_PREFIX, '') ||
      Object.keys(template.types || {})
        .map(key => key.replace(TWILIO_TYPE_PREFIX, ''))
        .find(key => key);

    const hyphenatedKey = `${TWILIO_TYPE_PREFIX}${(typeKey || '').replace(/_/g, '-')}`;
    const underscoreKey = `${TWILIO_TYPE_PREFIX}${(typeKey || '').replace(/-/g, '_')}`;
    const typeData =
      template.types?.[hyphenatedKey] || template.types?.[underscoreKey] || {};

    return {
      contentSid: template.content_sid,
      name: template.friendly_name,
      platform: PLATFORMS.TWILIO,
      type: TemplateTypeDetector.detectTwilioType(template),
      body: template.body || typeData.body,
      media: typeData.media || [],
      mediaType: template.media_type || null,
      actions: typeData.actions || [],
      variables: template.variables || {},
      category: template.category || 'utility',
      language: template.language || 'en',
      originalTemplate: template,
    };
  }

  static extractWhatsAppVariables(template) {
    const variables = {};
    const components = template.components || [];

    components.forEach(component => {
      if (component.text) {
        const matches = component.text.match(/\{\{([^}]+)\}\}/g) || [];
        matches.forEach(match => {
          const variable = match.replace(/[{}]/g, '');

          if (template.parameter_format === WA_PARAM_FORMATS.NAMED) {
            const example =
              component.example?.body_text_named_params?.find(
                p => p.param_name === variable
              )?.example || '';
            variables[variable] = example;
          } else {
            const position = parseInt(variable, 10) - 1;
            const example = component.example?.body_text?.[0]?.[position] || '';
            variables[variable] = example;
          }
        });
      }

      if (component.buttons) {
        component.buttons.forEach(button => {
          if (button.url) {
            const matches = button.url.match(/\{\{([^}]+)\}\}/g) || [];
            matches.forEach(match => {
              const variable = match.replace(/[{}]/g, '');
              const example = button.example?.[0] || '';
              variables[variable] = example;
            });
          }
        });
      }
    });

    return variables;
  }

  static normalize(template, platform) {
    switch (platform) {
      case PLATFORMS.WHATSAPP:
        return this.normalizeWhatsApp(template);
      case PLATFORMS.TWILIO:
        return this.normalizeTwilio(template);
      default:
        throw new Error(`Unsupported platform: ${platform}`);
    }
  }
}
