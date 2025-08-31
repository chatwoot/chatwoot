// WhatsApp Template Validation Rules
// Based on Meta's WhatsApp Business API requirements

export const validateTemplateName = name => {
  const errors = [];

  if (!name || name.trim().length === 0) {
    errors.push('Template name is required');
  } else {
    if (name.length < 2) {
      errors.push('Template name must be at least 2 characters');
    }
    if (name.length > 512) {
      errors.push('Template name cannot exceed 512 characters');
    }
    if (!/^[a-z0-9_]+$/.test(name)) {
      errors.push(
        'Template name can only contain lowercase letters, numbers, and underscores'
      );
    }
    if (name.startsWith('_') || name.endsWith('_')) {
      errors.push('Template name cannot start or end with underscore');
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};
