/**
 * Shared utility to map WhatsApp templates to preview component props.
 * Used by both Template Builder and Campaign Create dialogs.
 */

import type { HeaderFormat, ButtonType } from '../Templates/TemplateBuilder/validators/metaTemplateRules';

export interface TemplatePreviewProps {
  headerFormat: HeaderFormat | null;
  headerText: string;
  headerTextExample: string;
  headerMediaUrl: string;
  headerMediaName: string;
  bodyText: string;
  bodyExamples: string[];
  footerText: string;
  buttons: Array<{
    type: ButtonType;
    text?: string;
    url?: string;
    urlExample?: string;
    phoneNumber?: string;
  }>;
}

export interface WhatsAppTemplateComponent {
  type: 'HEADER' | 'BODY' | 'FOOTER' | 'BUTTONS';
  format?: string;
  text?: string;
  buttons?: Array<{
    type: string;
    text?: string;
    url?: string;
    phone_number?: string;
  }>;
}

export interface WhatsAppTemplate {
  id?: string | number;
  name: string;
  language?: string;
  category?: string;
  namespace?: string;
  components: WhatsAppTemplateComponent[];
}

export interface VariableValues {
  header?: {
    media_url?: string;
    media_name?: string;
    text?: string;
  };
  body?: Record<string, string>;
  buttons?: Array<{
    type?: string;
    parameter?: string;
  }>;
}

/**
 * Find a component by type in a template
 */
export function findComponentByType(
  template: WhatsAppTemplate,
  type: string
): WhatsAppTemplateComponent | undefined {
  return template.components?.find(component => component.type === type);
}

/**
 * Extract placeholder keys from template text (e.g., "1", "2" from "{{1}}" "{{2}}")
 */
export function extractPlaceholderKeys(text: string): string[] {
  if (!text) return [];
  const regex = /\{\{(\d+)\}\}/g;
  const keys: string[] = [];
  let match;
  while ((match = regex.exec(text)) !== null) {
    keys.push(match[1]);
  }
  return [...new Set(keys)].sort((a, b) => parseInt(a, 10) - parseInt(b, 10));
}

/**
 * Map a WhatsApp template + user-provided variable values to preview props
 */
export function mapTemplateToPreviewProps(
  template: WhatsAppTemplate | null,
  variableValues: VariableValues = {}
): TemplatePreviewProps {
  const defaultProps: TemplatePreviewProps = {
    headerFormat: null,
    headerText: '',
    headerTextExample: '',
    headerMediaUrl: '',
    headerMediaName: '',
    bodyText: '',
    bodyExamples: [],
    footerText: '',
    buttons: [],
  };

  if (!template || !template.components) {
    return defaultProps;
  }

  const headerComponent = findComponentByType(template, 'HEADER');
  const bodyComponent = findComponentByType(template, 'BODY');
  const footerComponent = findComponentByType(template, 'FOOTER');
  const buttonsComponent = findComponentByType(template, 'BUTTONS');

  // Header
  let headerFormat: HeaderFormat | null = null;
  let headerText = '';
  let headerTextExample = '';
  let headerMediaUrl = '';
  let headerMediaName = '';

  if (headerComponent) {
    const format = headerComponent.format?.toUpperCase();
    if (format === 'TEXT') {
      headerFormat = 'TEXT';
      headerText = headerComponent.text || '';
      headerTextExample = variableValues.header?.text || '';
    } else if (format === 'IMAGE') {
      headerFormat = 'IMAGE';
      headerMediaUrl = variableValues.header?.media_url || '';
    } else if (format === 'VIDEO') {
      headerFormat = 'VIDEO';
      headerMediaUrl = variableValues.header?.media_url || '';
    } else if (format === 'DOCUMENT') {
      headerFormat = 'DOCUMENT';
      headerMediaUrl = variableValues.header?.media_url || '';
      headerMediaName = variableValues.header?.media_name || '';
    } else if (format === 'LOCATION') {
      headerFormat = 'LOCATION';
    }
  }

  // Body
  const bodyText = bodyComponent?.text || '';
  const bodyPlaceholderKeys = extractPlaceholderKeys(bodyText);
  const bodyExamples = bodyPlaceholderKeys.map(
    key => variableValues.body?.[key] || ''
  );

  // Footer
  const footerText = footerComponent?.text || '';

  // Buttons
  const buttons: TemplatePreviewProps['buttons'] = [];
  if (buttonsComponent?.buttons) {
    buttonsComponent.buttons.forEach((btn, index) => {
      const buttonType = btn.type?.toUpperCase() as ButtonType;
      const buttonValue = variableValues.buttons?.[index];

      buttons.push({
        type: buttonType || 'QUICK_REPLY',
        text: btn.text || '',
        url: btn.url || '',
        urlExample: buttonValue?.parameter || '',
        phoneNumber: btn.phone_number || '',
      });
    });
  }

  return {
    headerFormat,
    headerText,
    headerTextExample,
    headerMediaUrl,
    headerMediaName,
    bodyText,
    bodyExamples,
    footerText,
    buttons,
  };
}

/**
 * Build initial variable values structure from a template
 */
export function buildInitialVariableValues(
  template: WhatsAppTemplate | null
): VariableValues {
  if (!template || !template.components) {
    return {};
  }

  const values: VariableValues = {};
  const headerComponent = findComponentByType(template, 'HEADER');
  const bodyComponent = findComponentByType(template, 'BODY');
  const buttonsComponent = findComponentByType(template, 'BUTTONS');

  // Header
  if (headerComponent) {
    const format = headerComponent.format?.toUpperCase();
    if (['IMAGE', 'VIDEO', 'DOCUMENT'].includes(format || '')) {
      values.header = { media_url: '' };
      if (format === 'DOCUMENT') {
        values.header.media_name = '';
      }
    } else if (format === 'TEXT' && headerComponent.text?.includes('{{')) {
      values.header = { text: '' };
    }
  }

  // Body
  const bodyText = bodyComponent?.text || '';
  const bodyPlaceholderKeys = extractPlaceholderKeys(bodyText);
  if (bodyPlaceholderKeys.length > 0) {
    values.body = {};
    bodyPlaceholderKeys.forEach(key => {
      values.body![key] = '';
    });
  }

  // Buttons with variables
  if (buttonsComponent?.buttons) {
    buttonsComponent.buttons.forEach((btn, index) => {
      const hasVariable =
        (btn.type === 'URL' && btn.url?.includes('{{')) ||
        btn.type === 'COPY_CODE';

      if (hasVariable) {
        if (!values.buttons) values.buttons = [];
        values.buttons[index] = {
          type: btn.type?.toLowerCase(),
          parameter: '',
        };
      }
    });
  }

  return values;
}

/**
 * Check if a template has any variables that need to be filled
 */
export function templateHasVariables(template: WhatsAppTemplate | null): boolean {
  if (!template || !template.components) return false;

  const headerComponent = findComponentByType(template, 'HEADER');
  const bodyComponent = findComponentByType(template, 'BODY');
  const buttonsComponent = findComponentByType(template, 'BUTTONS');

  // Check header media
  const headerFormat = headerComponent?.format?.toUpperCase();
  if (['IMAGE', 'VIDEO', 'DOCUMENT'].includes(headerFormat || '')) {
    return true;
  }

  // Check header text variables
  if (headerComponent?.text?.includes('{{')) {
    return true;
  }

  // Check body variables
  if (bodyComponent?.text?.includes('{{')) {
    return true;
  }

  // Check button variables
  if (buttonsComponent?.buttons) {
    for (const btn of buttonsComponent.buttons) {
      if (btn.type === 'URL' && btn.url?.includes('{{')) return true;
      if (btn.type === 'COPY_CODE') return true;
    }
  }

  return false;
}

/**
 * Get the header media type for a template (if any)
 */
export function getHeaderMediaType(
  template: WhatsAppTemplate | null
): 'IMAGE' | 'VIDEO' | 'DOCUMENT' | null {
  if (!template) return null;
  const headerComponent = findComponentByType(template, 'HEADER');
  const format = headerComponent?.format?.toUpperCase();
  if (format === 'IMAGE' || format === 'VIDEO' || format === 'DOCUMENT') {
    return format as 'IMAGE' | 'VIDEO' | 'DOCUMENT';
  }
  return null;
}

