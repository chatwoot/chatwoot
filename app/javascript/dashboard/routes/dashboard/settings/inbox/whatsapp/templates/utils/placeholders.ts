/**
 * Utility functions for parsing and validating WhatsApp template placeholders
 */

export interface PlaceholderInfo {
  count: number;
  placeholders: string[];
  isValid: boolean;
  errors: string[];
}

/**
 * Extract all placeholders from text ({{1}}, {{2}}, etc.)
 */
export function extractPlaceholders(text: string): string[] {
  if (!text) return [];
  const regex = /\{\{(\d+)\}\}/g;
  const matches = [];
  let match;
  while ((match = regex.exec(text)) !== null) {
    matches.push(match[1]);
  }
  return matches;
}

/**
 * Validate that placeholders are sequential starting from 1 with no gaps
 */
export function validatePlaceholders(text: string): PlaceholderInfo {
  const placeholders = extractPlaceholders(text);
  const errors: string[] = [];
  
  if (placeholders.length === 0) {
    return {
      count: 0,
      placeholders: [],
      isValid: true,
      errors: [],
    };
  }

  // Convert to numbers and get unique values
  const numbers = [...new Set(placeholders.map(p => parseInt(p, 10)))].sort((a, b) => a - b);
  
  // Check if starts with 1
  if (numbers[0] !== 1) {
    errors.push('Placeholders must start with {{1}}');
  }

  // Check for gaps
  for (let i = 0; i < numbers.length; i++) {
    if (numbers[i] !== i + 1) {
      errors.push(`Missing placeholder {{${i + 1}}}`);
    }
  }

  return {
    count: numbers.length,
    placeholders: numbers.map(n => `{{${n}}}`),
    isValid: errors.length === 0,
    errors,
  };
}

/**
 * Count placeholders in text
 */
export function countPlaceholders(text: string): number {
  return validatePlaceholders(text).count;
}

/**
 * Check if examples array matches placeholder count
 */
export function validateExamples(
  text: string,
  examples: string[]
): { isValid: boolean; errors: string[] } {
  const placeholderInfo = validatePlaceholders(text);
  const errors: string[] = [];

  if (!placeholderInfo.isValid) {
    errors.push(...placeholderInfo.errors);
  }

  if (placeholderInfo.count > 0 && (!examples || examples.length === 0)) {
    errors.push('Examples are required when using placeholders');
  }

  if (examples && examples.length !== placeholderInfo.count) {
    errors.push(
      `Expected ${placeholderInfo.count} example(s), got ${examples.length}`
    );
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

/**
 * Replace placeholders with example values for preview
 */
export function renderWithExamples(text: string, examples: string[]): string {
  if (!text || !examples || examples.length === 0) return text;

  let result = text;
  examples.forEach((example, index) => {
    const placeholder = `{{${index + 1}}}`;
    result = result.replace(new RegExp(placeholder.replace(/[{}]/g, '\\$&'), 'g'), example || '');
  });

  return result;
}
