import { TemplateTypeDetector } from './TemplateTypeDetector';

/**
 * TemplateNormalizer - Convert platform-specific formats to unified structure
 */
export class TemplateNormalizer {
  /**
   * Normalize WhatsApp template to unified format
   * @param {Object} template - WhatsApp template object
   * @returns {Object} - Normalized template
   */
  static normalizeWhatsApp(template) {
    const components = template.components || [];

    return {
      id: template.id,
      name: template.name,
      platform: 'whatsapp',
      type: TemplateTypeDetector.detectWhatsAppType(template),
      parameterFormat: template.parameter_format || 'POSITIONAL',
      header: components.find(c => c.type === 'HEADER'),
      body: components.find(c => c.type === 'BODY'),
      footer: components.find(c => c.type === 'FOOTER'),
      buttons: components.find(c => c.type === 'BUTTONS')?.buttons || [],
      variables: this.extractWhatsAppVariables(template),
      category: template.category,
      language: template.language,
      originalTemplate: template,
    };
  }

  /**
   * Normalize Twilio template to unified format
   * @param {Object} template - Twilio template object
   * @returns {Object} - Normalized template
   */
  static normalizeTwilio(template) {
    // Convert template_type to match the keys used in the types object
    const normalizedType = template.template_type.replace('_', '-');
    const lookupKey = `twilio/${normalizedType}`;
    const typeData = template.types?.[lookupKey] || {};

    return {
      contentSid: template.content_sid,
      name: template.friendly_name,
      platform: 'twilio',
      type: TemplateTypeDetector.detectTwilioType(template),
      body: template.body || typeData.body,
      media: typeData.media || [],
      actions: typeData.actions || [],
      variables: template.variables || {},
      category: template.category || 'utility',
      language: template.language || 'en',
      originalTemplate: template,
    };
  }

  /**
   * Extract variables from WhatsApp template
   * @param {Object} template - WhatsApp template object
   * @returns {Object} - Variables object with example values
   */
  static extractWhatsAppVariables(template) {
    const variables = {};
    const components = template.components || [];

    components.forEach(component => {
      // Extract from text content
      if (component.text) {
        const matches = component.text.match(/\{\{([^}]+)\}\}/g) || [];
        matches.forEach(match => {
          const variable = match.replace(/[{}]/g, '');

          if (template.parameter_format === 'NAMED') {
            // Named parameters: {{customer_name}}
            const example =
              component.example?.body_text_named_params?.find(
                p => p.param_name === variable
              )?.example || '';
            variables[variable] = example;
          } else {
            // Positional parameters: {{1}}, {{2}}
            const position = parseInt(variable, 10) - 1;
            const example = component.example?.body_text?.[0]?.[position] || '';
            variables[variable] = example;
          }
        });
      }

      // Extract from button URLs
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

  /**
   * Extract variables from Twilio template
   * @param {Object} template - Twilio template object
   * @returns {Object} - Variables object with example values
   */
  static extractTwilioVariables(template) {
    const variables = {};

    // Extract from body text
    if (template.body) {
      const matches = template.body.match(/\{\{([^}]+)\}\}/g) || [];
      matches.forEach(match => {
        const variable = match.replace(/[{}]/g, '');
        variables[variable] = template.variables?.[variable] || '';
      });
    }

    // Extract from media URLs
    const typeData = template.types?.[`twilio/${template.template_type}`] || {};
    if (typeData.media) {
      typeData.media.forEach(mediaUrl => {
        const matches = mediaUrl.match(/\{\{([^}]+)\}\}/g) || [];
        matches.forEach(match => {
          const variable = match.replace(/[{}]/g, '');
          variables[variable] = template.variables?.[variable] || '';
        });
      });
    }

    return variables;
  }

  /**
   * Normalize template from any platform
   * @param {Object} template - Template object
   * @param {string} platform - Platform identifier ('whatsapp' | 'twilio')
   * @returns {Object} - Normalized template
   */
  static normalize(template, platform) {
    switch (platform) {
      case 'whatsapp':
        return this.normalizeWhatsApp(template);
      case 'twilio':
        return this.normalizeTwilio(template);
      default:
        throw new Error(`Unsupported platform: ${platform}`);
    }
  }
}
