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

// i18n validation keys - these map to INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.VALIDATION.*
export const VALIDATION_KEYS = {
  TEMPLATE_NAME_REQUIRED: 'TEMPLATE_NAME_REQUIRED',
  TEMPLATE_NAME_TOO_LONG: 'TEMPLATE_NAME_TOO_LONG',
  TEMPLATE_NAME_INVALID: 'TEMPLATE_NAME_INVALID',
  INVALID_CATEGORY: 'INVALID_CATEGORY',
  HEADER_TEXT_REQUIRED: 'HEADER_TEXT_REQUIRED',
  HEADER_TEXT_TOO_LONG: 'HEADER_TEXT_TOO_LONG',
  HEADER_TEXT_MAX_ONE_VARIABLE: 'HEADER_TEXT_MAX_ONE_VARIABLE',
  HEADER_TEXT_EXAMPLE_REQUIRED: 'HEADER_TEXT_EXAMPLE_REQUIRED',
  HEADER_MEDIA_REQUIRED: 'HEADER_MEDIA_REQUIRED',
  BODY_TEXT_REQUIRED: 'BODY_TEXT_REQUIRED',
  BODY_TEXT_TOO_LONG: 'BODY_TEXT_TOO_LONG',
  FOOTER_TEXT_TOO_LONG: 'FOOTER_TEXT_TOO_LONG',
  FOOTER_NO_PLACEHOLDERS: 'FOOTER_NO_PLACEHOLDERS',
  BUTTON_TEXT_REQUIRED: 'BUTTON_TEXT_REQUIRED',
  BUTTON_TEXT_TOO_LONG: 'BUTTON_TEXT_TOO_LONG',
  URL_REQUIRED: 'URL_REQUIRED',
  URL_TOO_LONG: 'URL_TOO_LONG',
  URL_EXAMPLE_REQUIRED: 'URL_EXAMPLE_REQUIRED',
  URL_MAX_ONE_VARIABLE: 'URL_MAX_ONE_VARIABLE',
  PHONE_REQUIRED: 'PHONE_REQUIRED',
  PHONE_INVALID_FORMAT: 'PHONE_INVALID_FORMAT',
  MAX_CTA_BUTTONS: 'MAX_CTA_BUTTONS',
  MAX_BUTTONS: 'MAX_BUTTONS',
  MAX_QUICK_REPLY_BUTTONS: 'MAX_QUICK_REPLY_BUTTONS',
  COPY_CODE_AUTH_ONLY: 'COPY_CODE_AUTH_ONLY',
  MAX_COPY_CODE_BUTTONS: 'MAX_COPY_CODE_BUTTONS',
} as const;

/**
 * Validate template name (Meta rules)
 */
export function validateTemplateName(name: string): ValidationResult {
  const errors: string[] = [];

  if (!name || name.trim().length === 0) {
    errors.push(VALIDATION_KEYS.TEMPLATE_NAME_REQUIRED);
  } else if (name.length > LIMITS.TEMPLATE_NAME) {
    errors.push(VALIDATION_KEYS.TEMPLATE_NAME_TOO_LONG);
  } else if (!/^[a-z0-9_]+$/.test(name)) {
    errors.push(VALIDATION_KEYS.TEMPLATE_NAME_INVALID);
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
    errors.push(VALIDATION_KEYS.INVALID_CATEGORY);
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
      errors.push(VALIDATION_KEYS.HEADER_TEXT_REQUIRED);
    } else if (text.length > LIMITS.HEADER_TEXT) {
      errors.push(VALIDATION_KEYS.HEADER_TEXT_TOO_LONG);
    }

    // Check for placeholders
    const placeholderInfo = validatePlaceholders(text);
    if (placeholderInfo.count > 1) {
      errors.push(VALIDATION_KEYS.HEADER_TEXT_MAX_ONE_VARIABLE);
    }

    if (placeholderInfo.count === 1 && (!textExample || textExample.trim().length === 0)) {
      errors.push(VALIDATION_KEYS.HEADER_TEXT_EXAMPLE_REQUIRED);
    }
  }

  // For IMAGE/VIDEO/DOCUMENT headers, Meta requires a media handle (h) from the upload API
  if (format === 'IMAGE' || format === 'VIDEO' || format === 'DOCUMENT') {
    if (!mediaHandle || mediaHandle.trim().length === 0) {
      errors.push(VALIDATION_KEYS.HEADER_MEDIA_REQUIRED);
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
    errors.push(VALIDATION_KEYS.BODY_TEXT_REQUIRED);
  } else if (text.length > LIMITS.BODY_TEXT) {
    errors.push(VALIDATION_KEYS.BODY_TEXT_TOO_LONG);
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
    errors.push(VALIDATION_KEYS.FOOTER_TEXT_TOO_LONG);
  }

  // Check for placeholders (not allowed in footer)
  const placeholderInfo = validatePlaceholders(text);
  if (placeholderInfo.count > 0) {
    errors.push(VALIDATION_KEYS.FOOTER_NO_PLACEHOLDERS);
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
    errors.push(VALIDATION_KEYS.MAX_BUTTONS);
  }

  // Count button types
  const quickReplyCount = buttons.filter(b => b.type === 'QUICK_REPLY').length;
  const urlCount = buttons.filter(b => b.type === 'URL').length;
  const phoneCount = buttons.filter(b => b.type === 'PHONE_NUMBER').length;
  const copyCodeCount = buttons.filter(b => b.type === 'COPY_CODE').length;
  const ctaCount = urlCount + phoneCount;

  // Validate button type limits
  if (quickReplyCount > LIMITS.MAX_QUICK_REPLY_BUTTONS) {
    errors.push(VALIDATION_KEYS.MAX_QUICK_REPLY_BUTTONS);
  }

  if (ctaCount > LIMITS.MAX_CTA_BUTTONS) {
    errors.push(VALIDATION_KEYS.MAX_CTA_BUTTONS);
  }

  // Note: Meta DOES allow mixing Quick Reply with CTA buttons (verified via API testing)
  // The previous restriction has been removed

  // COPY_CODE only for AUTHENTICATION
  if (copyCodeCount > 0 && category !== 'AUTHENTICATION') {
    errors.push(VALIDATION_KEYS.COPY_CODE_AUTH_ONLY);
  }

  if (copyCodeCount > 1) {
    errors.push(VALIDATION_KEYS.MAX_COPY_CODE_BUTTONS);
  }

  // Validate individual buttons
  buttons.forEach((button, index) => {
    if (button.type === 'QUICK_REPLY' || button.type === 'URL' || button.type === 'PHONE_NUMBER') {
      if (!button.text || button.text.trim().length === 0) {
        errors.push(VALIDATION_KEYS.BUTTON_TEXT_REQUIRED);
      } else if (button.text.length > LIMITS.BUTTON_TEXT) {
        errors.push(VALIDATION_KEYS.BUTTON_TEXT_TOO_LONG);
      }
    }

    if (button.type === 'URL') {
      if (!button.url || button.url.trim().length === 0) {
        errors.push(VALIDATION_KEYS.URL_REQUIRED);
      } else if (button.url.length > LIMITS.URL) {
        errors.push(VALIDATION_KEYS.URL_TOO_LONG);
      }

      // Check for dynamic URL
      const placeholderInfo = validatePlaceholders(button.url || '');
      if (placeholderInfo.count > 1) {
        errors.push(VALIDATION_KEYS.URL_MAX_ONE_VARIABLE);
      }

      if (placeholderInfo.count === 1 && (!button.urlExample || button.urlExample.trim().length === 0)) {
        errors.push(VALIDATION_KEYS.URL_EXAMPLE_REQUIRED);
      }
    }

    if (button.type === 'PHONE_NUMBER') {
      if (!button.phoneNumber || button.phoneNumber.trim().length === 0) {
        errors.push(VALIDATION_KEYS.PHONE_REQUIRED);
      } else if (!/^\+\d+$/.test(button.phoneNumber)) {
        errors.push(VALIDATION_KEYS.PHONE_INVALID_FORMAT);
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

