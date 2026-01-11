/**
 * Meta WhatsApp Business API template validation rules
 * https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates
 * 
 * Validation findings from API testing (2025-01-11):
 * - MARKETING/UTILITY: Work with simple body text
 * - AUTHENTICATION: Requires special format with add_security_recommendation and OTP buttons
 * - Emojis and formatting (*bold*, _italic_, ~strikethrough~) all work in body
 * - All header types work: TEXT, IMAGE, VIDEO, DOCUMENT, LOCATION
 * - URLs: https://, http://, and even www.example.com (no protocol) all accepted by Meta
 * - Quick Reply + CTA buttons CAN be mixed (Meta allows it)
 * - Max 2 CTA buttons (URL + PHONE combined)
 * - Quick Reply buttons: Meta allows more than 3 (tested with 4)
 * - Header text: max 60 chars (enforced by Meta)
 * - Button text: max 25 chars
 */

import { validatePlaceholders, validateExamples } from '../utils/placeholders';

export interface ValidationResult {
  isValid: boolean;
  errors: string[];
}

// Character limits
// Note: These limits were verified via API testing on 2025-01-11
export const LIMITS = {
  TEMPLATE_NAME: 512,
  HEADER_TEXT: 60,
  BODY_TEXT: 1024,
  FOOTER_TEXT: 60,
  BUTTON_TEXT: 25,
  URL: 2000,
  MAX_QUICK_REPLY_BUTTONS: 10, // Meta allows more than 3 (tested with 4)
  MAX_CTA_BUTTONS: 2, // URL + PHONE combined max is 2
  MAX_BUTTONS: 10,
};

// Valid categories
export const CATEGORIES = ['AUTHENTICATION', 'MARKETING', 'UTILITY'] as const;
export type TemplateCategory = typeof CATEGORIES[number];

// Header formats
export const HEADER_FORMATS = ['TEXT', 'IMAGE', 'VIDEO', 'DOCUMENT', 'LOCATION'] as const;
export type HeaderFormat = typeof HEADER_FORMATS[number];

// Button types
export const BUTTON_TYPES = ['QUICK_REPLY', 'URL', 'PHONE_NUMBER', 'COPY_CODE'] as const;
export type ButtonType = typeof BUTTON_TYPES[number];

/**
 * Validate template name (Meta rules)
 */
export function validateTemplateName(name: string): ValidationResult {
  const errors: string[] = [];

  if (!name || name.trim().length === 0) {
    errors.push('Template name is required');
  } else if (name.length > LIMITS.TEMPLATE_NAME) {
    errors.push(`Template name must be ${LIMITS.TEMPLATE_NAME} characters or less`);
  } else if (!/^[a-z0-9_]+$/.test(name)) {
    errors.push('Template name must contain only lowercase letters, numbers, and underscores');
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

/**
 * Validate category
 */
export function validateCategory(category: string): ValidationResult {
  const errors: string[] = [];

  if (!CATEGORIES.includes(category as TemplateCategory)) {
    errors.push(`Category must be one of: ${CATEGORIES.join(', ')}`);
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

/**
 * Validate header component
 */
export function validateHeader(
  format: HeaderFormat | null,
  text: string,
  textExample: string,
  mediaHandle: string
): ValidationResult {
  const errors: string[] = [];

  if (!format) {
    return { isValid: true, errors: [] };
  }

  if (format === 'TEXT') {
    if (!text || text.trim().length === 0) {
      errors.push('Header text is required');
    } else if (text.length > LIMITS.HEADER_TEXT) {
      errors.push(`Header text must be ${LIMITS.HEADER_TEXT} characters or less`);
    }

    // Check for placeholders
    const placeholderInfo = validatePlaceholders(text);
    if (placeholderInfo.count > 1) {
      errors.push('Header text supports maximum 1 placeholder');
    }

    if (placeholderInfo.count === 1 && (!textExample || textExample.trim().length === 0)) {
      errors.push('Header text example is required when using placeholder');
    }
  }

  // For IMAGE/VIDEO/DOCUMENT headers, Meta requires a media handle (h) from the upload API
  if (format === 'IMAGE' || format === 'VIDEO' || format === 'DOCUMENT') {
    if (!mediaHandle || mediaHandle.trim().length === 0) {
      errors.push(`Media upload is required for ${format.toLowerCase()} headers`);
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

/**
 * Validate body component (always required)
 */
export function validateBody(text: string, examples: string[]): ValidationResult {
  const errors: string[] = [];

  if (!text || text.trim().length === 0) {
    errors.push('Body text is required');
  } else if (text.length > LIMITS.BODY_TEXT) {
    errors.push(`Body text must be ${LIMITS.BODY_TEXT} characters or less`);
  }

  // Validate placeholders
  const placeholderValidation = validatePlaceholders(text);
  if (!placeholderValidation.isValid) {
    errors.push(...placeholderValidation.errors);
  }

  // Validate examples
  if (placeholderValidation.count > 0) {
    const examplesValidation = validateExamples(text, examples);
    if (!examplesValidation.isValid) {
      errors.push(...examplesValidation.errors);
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

/**
 * Validate footer component (no variables allowed)
 */
export function validateFooter(text: string): ValidationResult {
  const errors: string[] = [];

  if (text && text.length > LIMITS.FOOTER_TEXT) {
    errors.push(`Footer text must be ${LIMITS.FOOTER_TEXT} characters or less`);
  }

  // Check for placeholders (not allowed in footer)
  const placeholderInfo = validatePlaceholders(text);
  if (placeholderInfo.count > 0) {
    errors.push('Footer does not support placeholders');
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

/**
 * Validate buttons
 */
export function validateButtons(
  buttons: Array<{
    type: ButtonType;
    text?: string;
    url?: string;
    urlExample?: string;
    phoneNumber?: string;
  }>,
  category: TemplateCategory
): ValidationResult {
  const errors: string[] = [];

  if (!buttons || buttons.length === 0) {
    return { isValid: true, errors: [] };
  }

  if (buttons.length > LIMITS.MAX_BUTTONS) {
    errors.push(`Maximum ${LIMITS.MAX_BUTTONS} buttons allowed`);
  }

  // Count button types
  const quickReplyCount = buttons.filter(b => b.type === 'QUICK_REPLY').length;
  const urlCount = buttons.filter(b => b.type === 'URL').length;
  const phoneCount = buttons.filter(b => b.type === 'PHONE_NUMBER').length;
  const copyCodeCount = buttons.filter(b => b.type === 'COPY_CODE').length;
  const ctaCount = urlCount + phoneCount;

  // Validate button type limits
  if (quickReplyCount > LIMITS.MAX_QUICK_REPLY_BUTTONS) {
    errors.push(`Maximum ${LIMITS.MAX_QUICK_REPLY_BUTTONS} Quick Reply buttons allowed`);
  }

  if (ctaCount > LIMITS.MAX_CTA_BUTTONS) {
    errors.push(`Maximum ${LIMITS.MAX_CTA_BUTTONS} Call-to-Action buttons (URL/Phone) allowed`);
  }

  // Note: Meta DOES allow mixing Quick Reply with CTA buttons (verified via API testing)
  // The previous restriction has been removed

  // COPY_CODE only for AUTHENTICATION
  if (copyCodeCount > 0 && category !== 'AUTHENTICATION') {
    errors.push('COPY_CODE button is only allowed for AUTHENTICATION templates');
  }

  if (copyCodeCount > 1) {
    errors.push('Maximum 1 COPY_CODE button allowed');
  }

  // Validate individual buttons
  buttons.forEach((button, index) => {
    if (button.type === 'QUICK_REPLY' || button.type === 'URL' || button.type === 'PHONE_NUMBER') {
      if (!button.text || button.text.trim().length === 0) {
        errors.push(`Button ${index + 1}: text is required`);
      } else if (button.text.length > LIMITS.BUTTON_TEXT) {
        errors.push(`Button ${index + 1}: text must be ${LIMITS.BUTTON_TEXT} characters or less`);
      }
    }

    if (button.type === 'URL') {
      if (!button.url || button.url.trim().length === 0) {
        errors.push(`Button ${index + 1}: URL is required`);
      } else if (button.url.length > LIMITS.URL) {
        errors.push(`Button ${index + 1}: URL must be ${LIMITS.URL} characters or less`);
      }

      // Check for dynamic URL
      const placeholderInfo = validatePlaceholders(button.url || '');
      if (placeholderInfo.count > 1) {
        errors.push(`Button ${index + 1}: URL supports maximum 1 placeholder`);
      }

      if (placeholderInfo.count === 1 && (!button.urlExample || button.urlExample.trim().length === 0)) {
        errors.push(`Button ${index + 1}: URL example is required when using placeholder`);
      }
    }

    if (button.type === 'PHONE_NUMBER') {
      if (!button.phoneNumber || button.phoneNumber.trim().length === 0) {
        errors.push(`Button ${index + 1}: phone number is required`);
      } else if (!/^\+\d+$/.test(button.phoneNumber)) {
        errors.push(`Button ${index + 1}: phone number must start with + and contain only digits`);
      }
    }
  });

  return {
    isValid: errors.length === 0,
    errors,
  };
}

/**
 * Validate complete template
 */
export function validateTemplate(template: {
  name: string;
  category: TemplateCategory;
  headerFormat: HeaderFormat | null;
  headerText: string;
  headerTextExample: string;
  headerMediaHandle: string;
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
}): ValidationResult {
  const allErrors: string[] = [];

  // Validate each component
  const nameValidation = validateTemplateName(template.name);
  allErrors.push(...nameValidation.errors);

  const categoryValidation = validateCategory(template.category);
  allErrors.push(...categoryValidation.errors);

  const headerValidation = validateHeader(
    template.headerFormat,
    template.headerText,
    template.headerTextExample,
    template.headerMediaHandle
  );
  allErrors.push(...headerValidation.errors);

  const bodyValidation = validateBody(template.bodyText, template.bodyExamples);
  allErrors.push(...bodyValidation.errors);

  const footerValidation = validateFooter(template.footerText);
  allErrors.push(...footerValidation.errors);

  const buttonsValidation = validateButtons(template.buttons, template.category);
  allErrors.push(...buttonsValidation.errors);

  return {
    isValid: allErrors.length === 0,
    errors: allErrors,
  };
}

/**
 * Helper to validate URL format
 */
function isValidUrl(url: string): boolean {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
}
