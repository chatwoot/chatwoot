<script setup>
import { reactive, computed, defineEmits, defineProps, ref, nextTick, defineAsyncComponent } from 'vue';
import { useI18n } from 'vue-i18n';

import Input from 'dashboard/components-next/input/Input.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import whatsappLanguages from '../whatsappLanguages.js';

// Lazy load emoji picker
const EmojiInput = defineAsyncComponent(
  () => import('shared/components/emoji/EmojiInput.vue')
);

defineProps({
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['submit', 'cancel']);
const { t } = useI18n();

// Refs for textareas
const bodyTextareaRef = ref(null);
const headerInputRef = ref(null);

// Emoji picker state
const showEmojiPicker = ref(false);

const toggleEmojiPicker = () => {
  showEmojiPicker.value = !showEmojiPicker.value;
};

const hideEmojiPicker = () => {
  showEmojiPicker.value = false;
};

const insertEmoji = async emoji => {
  if (!emoji) return;
  const textarea = bodyTextareaRef.value;
  if (!textarea) {
    state.bodyText += emoji;
    hideEmojiPicker();
    return;
  }

  const start = textarea.selectionStart;
  const end = textarea.selectionEnd;
  const text = state.bodyText;

  state.bodyText = text.substring(0, start) + emoji + text.substring(end);
  hideEmojiPicker();

  await nextTick();
  const newPos = start + emoji.length;
  textarea.focus();
  textarea.setSelectionRange(newPos, newPos);
};

// Meta WhatsApp Template Limits
const LIMITS = {
  NAME_MAX: 512,
  HEADER_TEXT_MAX: 60,
  HEADER_MAX_VARIABLES: 1,
  BODY_MAX: 1024,
  FOOTER_MAX: 60,
};

// Available variable types
const state = reactive({
  name: '',
  language: 'en_US',
  category: 'UTILITY',
  parameterFormat: 'positional', // 'positional' for {{1}}, {{2}} or 'named' for {{name}}, {{order_number}}
  headerFormat: '',
  headerText: '',
  headerExampleUrl: '',
  bodyText: '',
  footerText: '',
  variableExamples: {}, // Store examples for each variable: { '1': 'John', '2': '12345' } or { 'first_name': 'John' }
});

const categoryOptions = [
  {
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.CATEGORY_OPTIONS.UTILITY'),
    value: 'UTILITY',
  },
  {
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.CATEGORY_OPTIONS.MARKETING'),
    value: 'MARKETING',
  },
];

const parameterFormatOptions = [
  {
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.BODY.FORMAT_POSITIONAL'),
    value: 'positional',
  },
  {
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.BODY.FORMAT_NAMED'),
    value: 'named',
  },
];

const headerFormatOptions = [
  {
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.HEADER_FORMAT_OPTIONS.NONE'),
    value: '',
  },
  {
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.HEADER_FORMAT_OPTIONS.TEXT'),
    value: 'TEXT',
  },
  {
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.HEADER_FORMAT_OPTIONS.IMAGE'),
    value: 'IMAGE',
  },
  {
    label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.HEADER_FORMAT_OPTIONS.VIDEO'),
    value: 'VIDEO',
  },
  {
    label: t(
      'INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.HEADER_FORMAT_OPTIONS.DOCUMENT'
    ),
    value: 'DOCUMENT',
  },
];

const languageOptions = computed(() =>
  whatsappLanguages.map(({ name, id }) => ({ label: `${name} (${id})`, value: id }))
);

const isHeaderMediaFormat = computed(() =>
  ['IMAGE', 'VIDEO', 'DOCUMENT'].includes(state.headerFormat)
);

// Helper: Count numeric variables in text
const countVariables = text => {
  if (!text) return [];
  const matches = text.match(/\{\{(\d+)\}\}/g) || [];
  return matches.map(m => parseInt(m.replace(/[{}]/g, '')));
};

// Helper: Get all variables (numeric and named) in text
const getAllVariables = text => {
  if (!text) return [];
  const matches = text.match(/\{\{([^}]+)\}\}/g) || [];
  return matches.map(m => m.replace(/[{}]/g, ''));
};

// Helper: Check if a variable matches the selected format
const isVariableFormatCorrect = varName => {
  const isNumeric = /^\d+$/.test(varName);
  if (state.parameterFormat === 'positional') {
    return isNumeric;
  } else {
    return !isNumeric;
  }
};

// Get variables with incorrect format
const incorrectFormatVariables = computed(() => {
  const vars = getAllVariables(state.bodyText);
  return [...new Set(vars.filter(v => !isVariableFormatCorrect(v)))];
});

// Check if there are format mismatches
const hasFormatMismatch = computed(() => incorrectFormatVariables.value.length > 0);

// Suggested named variables (for quick insert buttons)
const SUGGESTED_VARIABLES = ['name', 'phone'];

// Helper: Validate variable format - check for malformed variables
const validateVariableFormat = (text, checkPosition = false) => {
  if (!text) return { valid: true, errors: [], invalidVars: [] };

  const errors = [];

  // Check for unclosed {{ or }}
  const openBraces = (text.match(/\{\{/g) || []).length;
  const closeBraces = (text.match(/\}\}/g) || []).length;

  if (openBraces !== closeBraces) {
    errors.push('unclosed_braces');
  }

  // Check for empty variables {{}}
  if (/\{\{\s*\}\}/.test(text)) {
    errors.push('empty_variable');
  }

  // Check if variable is at the beginning or end (only for body)
  if (checkPosition) {
    const trimmedText = text.trim();
    // Check if starts with a variable
    if (/^\{\{[^}]+\}\}/.test(trimmedText)) {
      errors.push('variable_at_start');
    }
    // Check if ends with a variable
    if (/\{\{[^}]+\}\}$/.test(trimmedText)) {
      errors.push('variable_at_end');
    }
  }

  // Check for variables with only spaces or invalid characters
  const allVars = getAllVariables(text);
  const invalidVars = [];
  allVars.forEach(varContent => {
    const trimmed = varContent.trim();
    // Variable content should not be empty and should only contain alphanumeric, underscore
    if (!trimmed || !/^[a-zA-Z0-9_]+$/.test(trimmed)) {
      invalidVars.push(varContent);
      errors.push('invalid_variable');
    }
  });

  return { valid: errors.length === 0, errors, invalidVars: [...new Set(invalidVars)] };
};

// Helper: Check if variables are sequential starting from 1
const areVariablesSequential = text => {
  const vars = countVariables(text);
  if (vars.length === 0) return true;

  const sorted = [...new Set(vars)].sort((a, b) => a - b);
  for (let i = 0; i < sorted.length; i++) {
    if (sorted[i] !== i + 1) return false;
  }
  return true;
};

// Get the next sequential variable number for body
const getNextVariableNumber = computed(() => {
  const vars = countVariables(state.bodyText);
  if (vars.length === 0) return 1;
  return Math.max(...vars) + 1;
});

// Get next named variable placeholder (variable_1, variable_2, etc.)
const getNextNamedVariable = computed(() => {
  const existingVars = getAllVariables(state.bodyText).filter(v => !/^\d+$/.test(v));

  // Find the next available variable_N number
  let nextNum = 1;
  while (existingVars.includes(`variable_${nextNum}`)) {
    nextNum++;
  }
  return `variable_${nextNum}`;
});

// Insert positional variable ({{1}}, {{2}}, etc.)
const insertPositionalVariable = async () => {
  state.parameterFormat = 'positional';
  const textarea = bodyTextareaRef.value;
  if (!textarea) return;

  const variableText = `{{${getNextVariableNumber.value}}}`;
  const start = textarea.selectionStart;
  const end = textarea.selectionEnd;
  const text = state.bodyText;

  state.bodyText = text.substring(0, start) + variableText + text.substring(end);

  await nextTick();
  const newPos = start + variableText.length;
  textarea.focus();
  textarea.setSelectionRange(newPos, newPos);
};

// Insert named variable ({{name}}, {{order_number}}, etc.)
const insertNamedVariable = async () => {
  state.parameterFormat = 'named';
  const textarea = bodyTextareaRef.value;
  if (!textarea) return;

  const variableText = `{{${getNextNamedVariable.value}}}`;
  const start = textarea.selectionStart;
  const end = textarea.selectionEnd;
  const text = state.bodyText;

  state.bodyText = text.substring(0, start) + variableText + text.substring(end);

  await nextTick();
  const newPos = start + variableText.length;
  textarea.focus();
  textarea.setSelectionRange(newPos, newPos);
};

// Insert formatting (bold, italic, strikethrough, monospace)
const insertFormat = async (formatType) => {
  const textarea = bodyTextareaRef.value;
  if (!textarea) return;

  const start = textarea.selectionStart;
  const end = textarea.selectionEnd;
  const text = state.bodyText;
  const selectedText = text.substring(start, end) || 'text';

  let formattedText = '';
  let cursorOffset = 0;

  switch (formatType) {
    case 'bold':
      formattedText = `*${selectedText}*`;
      cursorOffset = 1;
      break;
    case 'italic':
      formattedText = `_${selectedText}_`;
      cursorOffset = 1;
      break;
    case 'strikethrough':
      formattedText = `~${selectedText}~`;
      cursorOffset = 1;
      break;
    case 'monospace':
      formattedText = '```' + selectedText + '```';
      cursorOffset = 3;
      break;
    default:
      return;
  }

  state.bodyText = text.substring(0, start) + formattedText + text.substring(end);

  await nextTick();
  textarea.focus();
  if (start === end) {
    // No selection, place cursor inside the format markers and select "text"
    const selStart = start + cursorOffset;
    textarea.setSelectionRange(selStart, selStart + 4);
  } else {
    // Keep the formatted text selected (including the format markers)
    const selStart = start + cursorOffset;
    const selEnd = start + formattedText.length - cursorOffset;
    textarea.setSelectionRange(selStart, selEnd);
  }
};

// Handle input for auto-completion of {{ with }}
const handleBodyInput = async (event) => {
  const textarea = event.target;
  const text = textarea.value;
  const cursorPos = textarea.selectionStart;

  // Check if user just typed {{
  if (cursorPos >= 2 && text.substring(cursorPos - 2, cursorPos) === '{{') {
    // Check if there's already a }} after
    const afterCursor = text.substring(cursorPos);
    if (!afterCursor.startsWith('}}')) {
      // Only auto-complete for positional format
      if (state.parameterFormat === 'positional') {
        const nextNum = getNextVariableNumber.value;
        const insertText = `${nextNum}}}`;

        state.bodyText = text.substring(0, cursorPos) + insertText + text.substring(cursorPos);

        await nextTick();
        // Position cursor after the number (before }})
        const newPos = cursorPos + String(nextNum).length;
        textarea.focus();
        textarea.setSelectionRange(newPos, newPos);
      }
    }
  }
};

// Handle keydown for variable shortcuts
const handleBodyKeydown = (event) => {
  // Ctrl/Cmd + 1 to insert next variable
  if ((event.ctrlKey || event.metaKey) && event.key === '1') {
    event.preventDefault();
    insertVariable('number');
  }
};

// Validation errors
const errors = computed(() => {
  const errs = {};

  // Name validation
  if (state.name) {
    if (!/^[a-z][a-z0-9_]*$/.test(state.name)) {
      errs.name = t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.NAME_FORMAT');
    } else if (state.name.length < 3) {
      errs.name = t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.NAME_MIN');
    } else if (state.name.length > LIMITS.NAME_MAX) {
      errs.name = t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.NAME_MAX', {
        max: LIMITS.NAME_MAX,
      });
    }
  }

  // Header text validation
  if (state.headerFormat === 'TEXT' && state.headerText) {
    if (state.headerText.length > LIMITS.HEADER_TEXT_MAX) {
      errs.headerText = t(
        'INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.HEADER_MAX',
        { max: LIMITS.HEADER_TEXT_MAX }
      );
    }
    const headerVars = countVariables(state.headerText);
    if (headerVars.length > LIMITS.HEADER_MAX_VARIABLES) {
      errs.headerText = t(
        'INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.HEADER_VARS'
      );
    }
    // Validate header variable format
    const headerVarValidation = validateVariableFormat(state.headerText);
    if (!headerVarValidation.valid) {
      if (headerVarValidation.invalidVars.length > 0) {
        errs.headerText = t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.INVALID_VAR_FORMAT', {
          vars: headerVarValidation.invalidVars.join(', ')
        });
      } else if (headerVarValidation.errors.includes('unclosed_braces')) {
        errs.headerText = t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.UNCLOSED_BRACES');
      } else if (headerVarValidation.errors.includes('empty_variable')) {
        errs.headerText = t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.EMPTY_VARIABLE');
      }
    }
  }

  // Body validation
  if (state.bodyText) {
    if (state.bodyText.length > LIMITS.BODY_MAX) {
      errs.body = t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.BODY_MAX', {
        max: LIMITS.BODY_MAX,
      });
    } else {
      // Validate body variable format (with position check)
      const bodyVarValidation = validateVariableFormat(state.bodyText, true);
      if (!bodyVarValidation.valid) {
        if (bodyVarValidation.errors.includes('variable_at_start') || bodyVarValidation.errors.includes('variable_at_end')) {
          errs.body = t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.VAR_POSITION');
        } else if (bodyVarValidation.invalidVars.length > 0) {
          errs.body = t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.INVALID_VAR_FORMAT', {
            vars: bodyVarValidation.invalidVars.join(', ')
          });
        } else if (bodyVarValidation.errors.includes('unclosed_braces')) {
          errs.body = t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.UNCLOSED_BRACES');
        } else if (bodyVarValidation.errors.includes('empty_variable')) {
          errs.body = t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.EMPTY_VARIABLE');
        }
      } else if (!areVariablesSequential(state.bodyText)) {
        // Only check sequential if format is valid
        errs.body = t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.BODY_VARS');
      }
    }
  }

  // Footer validation
  if (state.footerText) {
    if (state.footerText.length > LIMITS.FOOTER_MAX) {
      errs.footer = t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.FOOTER_MAX', {
        max: LIMITS.FOOTER_MAX,
      });
    }
    const footerVars = getAllVariables(state.footerText);
    if (footerVars.length > 0) {
      errs.footer = t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.FOOTER_VARS');
    }
  }

  // Variable examples validation
  const bodyVars = getAllVariables(state.bodyText);
  const uniqueVars = [...new Set(bodyVars)];
  const missingExamples = uniqueVars.filter(
    varName => !state.variableExamples[varName] || !state.variableExamples[varName].trim()
  );
  if (missingExamples.length > 0) {
    errs.variableExamples = t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.MISSING_VAR_EXAMPLES', {
      vars: missingExamples.map(v => `{{${v}}}`).join(', ')
    });
  }

  // Self-reference validation - example value cannot contain reference to itself
  const selfReferenceVars = uniqueVars.filter(varName => {
    const exampleValue = state.variableExamples[varName] || '';
    const selfRefPattern = new RegExp(`\\{\\{${varName}\\}\\}`);
    return selfRefPattern.test(exampleValue);
  });
  if (selfReferenceVars.length > 0 && !errs.variableExamples) {
    errs.variableExamples = t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.ERRORS.SELF_REFERENCE', {
      vars: selfReferenceVars.map(v => `{{${v}}}`).join(', ')
    });
  }

  return errs;
});

const hasErrors = computed(() => Object.keys(errors.value).length > 0);

const isValid = computed(() => {
  // Required fields
  const nameValid =
    /^[a-z][a-z0-9_]*$/.test(state.name) && state.name.length >= 3;
  const bodyValid = state.bodyText.trim().length >= 1;

  // Header validation if format is selected
  if (state.headerFormat === 'TEXT' && !state.headerText.trim()) {
    return false;
  }
  if (isHeaderMediaFormat.value && !state.headerExampleUrl.trim()) {
    return false;
  }

  // Check for format mismatch
  if (hasFormatMismatch.value) {
    return false;
  }

  return nameValid && bodyValid && !hasErrors.value;
});

// Character counters
const nameCharCount = computed(() => state.name.length);
const headerCharCount = computed(() => state.headerText.length);
const bodyCharCount = computed(() => state.bodyText.length);
const footerCharCount = computed(() => state.footerText.length);

// Variable counts for display (counts all unique variables)
const bodyVariableCount = computed(
  () => new Set(getAllVariables(state.bodyText)).size
);

// Get list of unique variables detected in body text
const detectedVariables = computed(() => {
  const vars = getAllVariables(state.bodyText);
  return [...new Set(vars)];
});

// Category description based on selection
const categoryDescription = computed(() => {
  if (state.category === 'UTILITY') {
    return t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.CATEGORY_OPTIONS.UTILITY_DESC');
  }
  if (state.category === 'MARKETING') {
    return t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.CATEGORY_OPTIONS.MARKETING_DESC');
  }
  return '';
});

// Display text for variable buttons (to avoid Vue template parsing issues with {{ }})
const nextVarButtonText = computed(() => `{{${getNextVariableNumber.value}}}`);
const namedVarButtonText = computed(() => `{{${getNextNamedVariable.value}}}`);

// Format variable name for display (avoids Vue template parsing issues)
const formatVarDisplay = varName => {
  return '{{' + varName + '}}';
};

// Dynamic placeholder based on selected format
const bodyPlaceholder = computed(() => {
  return state.parameterFormat === 'positional'
    ? t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.BODY.PLACEHOLDER_POSITIONAL')
    : t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.BODY.PLACEHOLDER_NAMED');
});

// Preview computed properties
const previewHeaderText = computed(() => {
  if (state.headerFormat === 'TEXT') {
    return replaceVariablesWithExamples(state.headerText) || 'Header text';
  }
  return '';
});

const previewBodyText = computed(() => {
  return (
    replaceVariablesWithExamples(state.bodyText) ||
    'Your message body will appear here...'
  );
});

const previewFooterText = computed(() => {
  return state.footerText || '';
});

// Apply WhatsApp formatting styles to text (bold, italic, strikethrough, monospace)
const applyWhatsAppFormatting = text => {
  if (!text) return '';

  // Order matters: process monospace first (``` ```) to avoid conflicts
  // Monospace: ```text``` -> <code>text</code>
  let formatted = text.replace(/```([^`]+)```/g, '<code class="px-1 py-0.5 rounded bg-n-slate-3 font-mono text-xs">$1</code>');

  // Bold: *text* -> <strong>text</strong> (but not ** or * alone)
  formatted = formatted.replace(/\*([^*\n]+)\*/g, '<strong>$1</strong>');

  // Italic: _text_ -> <em>text</em>
  formatted = formatted.replace(/_([^_\n]+)_/g, '<em>$1</em>');

  // Strikethrough: ~text~ -> <del>text</del>
  formatted = formatted.replace(/~([^~\n]+)~/g, '<del>$1</del>');

  return formatted;
};

// Resolve variable references recursively within example values
// Example: {{1}} = "EDUARDO {{2}}!", {{2}} = "SAN!" -> {{1}} resolves to "EDUARDO SAN!!"
const resolveVariableValue = (varName, visited = new Set()) => {
  // Prevent infinite loops (self-reference protection)
  if (visited.has(varName)) {
    return `{{${varName}}}`;
  }

  const example = state.variableExamples[varName];
  if (!example || !example.trim()) {
    return null; // No example provided
  }

  // Mark as visited
  visited.add(varName);

  // Recursively resolve any variable references within this example value
  let resolved = example.replace(/\{\{([^}]+)\}\}/g, (match, innerVarName) => {
    const innerValue = resolveVariableValue(innerVarName, new Set(visited));
    return innerValue !== null ? innerValue : match;
  });

  return resolved;
};

// Sanitize HTML to prevent XSS attacks
const escapeHtml = (text) => {
  if (!text) return '';
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
};

// Replace variables with example values in preview, or highlight if no example
const replaceVariablesWithExamples = text => {
  if (!text) return '';

  // First replace variables with resolved example values
  let result = text.replace(/\{\{([^}]+)\}\}/g, (match, varName) => {
    // Sanitize varName to prevent XSS
    const safeVarName = escapeHtml(varName);

    // Check if variable format is incorrect
    if (!isVariableFormatCorrect(varName)) {
      // Highlight in red for incorrect format
      return `<span class="px-1 py-0.5 mx-0.5 text-xs font-medium rounded bg-n-ruby-3 text-n-ruby-11">{{${safeVarName}}}</span>`;
    }

    // Get resolved value (with nested variables replaced)
    const resolvedValue = resolveVariableValue(varName);
    if (resolvedValue !== null) {
      // Sanitize resolved value to prevent XSS
      const safeValue = escapeHtml(resolvedValue);
      // Show resolved example value with highlight
      return `<span class="px-1 py-0.5 mx-0.5 text-xs font-medium rounded bg-n-teal-3 text-n-teal-11">${safeValue}</span>`;
    }
    // Show variable placeholder if no example
    return `<span class="px-1 py-0.5 mx-0.5 text-xs font-medium rounded bg-n-amber-3 text-n-amber-11">{{${safeVarName}}}</span>`;
  });

  // Then apply WhatsApp formatting
  result = applyWhatsAppFormatting(result);

  return result;
};

// Highlight all variables like {{1}}, {{name}}, {{custom}} in the preview
const highlightVariables = text => {
  if (!text) return '';
  return text.replace(
    /\{\{([^}]+)\}\}/g,
    '<span class="px-1 py-0.5 mx-0.5 text-xs font-medium rounded bg-n-teal-3 text-n-teal-11">{{$1}}</span>'
  );
};

const handleSubmit = () => {
  if (!isValid.value) return;

  const template = {
    name: state.name,
    language: state.language,
    category: state.category,
    parameter_format: state.parameterFormat,
    body: {
      text: state.bodyText,
      examples: state.variableExamples,
    },
  };

  if (state.headerFormat) {
    template.header = {
      format: state.headerFormat,
    };

    if (state.headerFormat === 'TEXT') {
      template.header.text = state.headerText;
    } else if (isHeaderMediaFormat.value) {
      template.header.example_url = state.headerExampleUrl;
    }
  }

  if (state.footerText.trim()) {
    template.footer = {
      text: state.footerText,
    };
  }

  emit('submit', template);
};

const handleCancel = () => {
  emit('cancel');
};
</script>

<template>
  <div class="template-form-container rounded-xl border bg-n-alpha-1 border-n-weak overflow-hidden flex flex-col lg:max-h-[80vh]">
    <!-- Header -->
    <div class="flex items-center justify-between p-4 border-b border-n-weak flex-shrink-0">
      <h3 class="text-lg font-semibold text-n-slate-12">
        {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.TITLE') }}
      </h3>
      <button
        class="p-1 rounded-md hover:bg-n-slate-3 text-n-slate-11"
        @click="handleCancel"
      >
        <Icon icon="i-lucide-x" class="size-5" />
      </button>
    </div>

    <!-- Content: Two columns -->
    <div class="flex flex-col lg:flex-row lg:flex-1 lg:overflow-hidden">
      <!-- Left: Form (scrollable on large screens) -->
      <div class="flex-1 p-6 border-b lg:border-b-0 lg:border-r border-n-weak lg:overflow-y-auto">
        <div class="space-y-6 max-w-xl">
          <!-- Warning Banner -->
          <div class="flex gap-3 p-3 rounded-lg bg-n-amber-2 border border-n-amber-6">
            <Icon icon="i-lucide-alert-triangle" class="size-5 text-n-amber-11 flex-shrink-0 mt-0.5" />
            <div class="text-sm text-n-amber-11">
              <p class="font-medium">{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.WARNING.TITLE') }}</p>
              <p class="mt-1">{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.WARNING.MESSAGE') }}</p>
            </div>
          </div>

          <!-- Meta Approval Info Banner -->
          <div class="flex gap-3 p-3 rounded-lg bg-n-slate-2 border border-n-slate-6">
            <Icon icon="i-lucide-shield-check" class="size-5 text-n-slate-11 flex-shrink-0 mt-0.5" />
            <div class="text-sm text-n-slate-11">
              <p class="font-medium">{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.META_APPROVAL.TITLE') }}</p>
              <p class="mt-1">{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.META_APPROVAL.MESSAGE') }}</p>
              <p class="mt-2 font-medium">{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.META_APPROVAL.REJECTION_TITLE') }}</p>
              <ul class="mt-1 ml-4 list-disc space-y-0.5">
                <li>{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.META_APPROVAL.REASON_1') }}</li>
                <li>{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.META_APPROVAL.REASON_2') }}</li>
                <li>{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.META_APPROVAL.REASON_3') }}</li>
                <li>{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.META_APPROVAL.REASON_4') }}</li>
              </ul>
            </div>
          </div>

          <!-- Template Name & Language Row -->
          <div class="grid gap-4 sm:grid-cols-2">
            <div class="space-y-2">
              <div class="flex items-center justify-between">
                <label class="block text-sm font-medium text-n-slate-12">
                  {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.NAME.LABEL') }}
                  <span class="text-n-ruby-9">*</span>
                </label>
                <span
                  class="text-xs"
                  :class="
                    nameCharCount > LIMITS.NAME_MAX
                      ? 'text-n-ruby-9'
                      : 'text-n-slate-10'
                  "
                >
                  {{ nameCharCount }}/{{ LIMITS.NAME_MAX }}
                </span>
              </div>
              <div v-tooltip.top="state.name.length > 30 ? state.name : ''">
                <Input
                  v-model="state.name"
                  :placeholder="
                    $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.NAME.PLACEHOLDER')
                  "
                  class="w-full"
                  :class="{ 'border-n-ruby-9': errors.name }"
                />
              </div>
              <p v-if="errors.name" class="text-xs text-n-ruby-9">
                {{ errors.name }}
              </p>
              <p v-else class="text-xs text-n-slate-10">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.NAME.HELP') }}
              </p>
            </div>

            <div class="space-y-2">
              <label class="block text-sm font-medium text-n-slate-12">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.LANGUAGE.LABEL') }}
              </label>
              <ComboBox
                v-model="state.language"
                :options="languageOptions"
                :placeholder="
                  $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.LANGUAGE.PLACEHOLDER')
                "
              />
            </div>
          </div>

          <!-- Category -->
          <div class="space-y-2">
            <label class="block text-sm font-medium text-n-slate-12">
              {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.CATEGORY.LABEL') }}
            </label>
            <div class="flex gap-3">
              <label
                v-for="option in categoryOptions"
                :key="option.value"
                class="flex items-center gap-2 px-4 py-2 border rounded-lg cursor-pointer transition-colors"
                :class="
                  state.category === option.value
                    ? 'border-n-brand bg-n-brand/5 text-n-brand'
                    : 'border-n-weak hover:border-n-slate-6 text-n-slate-12'
                "
              >
                <input
                  v-model="state.category"
                  type="radio"
                  :value="option.value"
                  class="sr-only"
                />
                <span class="text-sm font-medium">{{ option.label }}</span>
              </label>
            </div>
            <!-- Category description -->
            <p class="text-xs text-n-slate-10 mt-1 min-h-[2.5rem]">
              {{ categoryDescription }}
            </p>
          </div>

          <!-- Header Section -->
          <div class="space-y-4">
            <div class="flex items-center gap-2">
              <Icon icon="i-lucide-heading" class="size-4 text-n-slate-11" />
              <span class="text-sm font-medium text-n-slate-12">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.HEADER.TITLE') }}
              </span>
              <span class="text-xs text-n-slate-10">(Optional)</span>
            </div>

            <div class="space-y-3 pl-6">
              <div class="space-y-2">
                <label class="block text-sm text-n-slate-11">
                  {{
                    $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.HEADER.FORMAT_LABEL')
                  }}
                </label>
                <ComboBox
                  v-model="state.headerFormat"
                  :options="headerFormatOptions"
                  :placeholder="
                    $t(
                      'INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.HEADER.FORMAT_PLACEHOLDER'
                    )
                  "
                />
              </div>

              <div v-if="state.headerFormat === 'TEXT'" class="space-y-2">
                <div class="flex items-center justify-between">
                  <label class="block text-sm text-n-slate-11">
                    {{
                      $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.HEADER.TEXT_LABEL')
                    }}
                  </label>
                  <span
                    class="text-xs"
                    :class="
                      headerCharCount > LIMITS.HEADER_TEXT_MAX
                        ? 'text-n-ruby-9'
                        : 'text-n-slate-10'
                    "
                  >
                    {{ headerCharCount }}/{{ LIMITS.HEADER_TEXT_MAX }}
                  </span>
                </div>
                <Input
                  v-model="state.headerText"
                  :placeholder="
                    $t(
                      'INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.HEADER.TEXT_PLACEHOLDER'
                    )
                  "
                  class="w-full"
                  :class="{ 'border-n-ruby-9': errors.headerText }"
                />
                <p v-if="errors.headerText" class="text-xs text-n-ruby-9">
                  {{ errors.headerText }}
                </p>
                <p v-else class="text-xs text-n-slate-10">
                  {{
                    $t(
                      'INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.HEADER.TEXT_HELP'
                    )
                  }}
                </p>
              </div>

              <div v-if="isHeaderMediaFormat" class="space-y-2">
                <label class="block text-sm text-n-slate-11">
                  {{
                    $t(
                      'INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.HEADER.MEDIA_URL_LABEL'
                    )
                  }}
                </label>
                <Input
                  v-model="state.headerExampleUrl"
                  :placeholder="
                    $t(
                      'INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.HEADER.MEDIA_URL_PLACEHOLDER'
                    )
                  "
                  class="w-full"
                />
                <p class="text-xs text-n-slate-10">
                  {{
                    $t(
                      'INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.HEADER.MEDIA_URL_HELP'
                    )
                  }}
                </p>
              </div>
            </div>
          </div>

          <!-- Body Section -->
          <div class="space-y-4">
            <div class="flex items-center gap-2">
              <Icon icon="i-lucide-text" class="size-4 text-n-slate-11" />
              <span class="text-sm font-medium text-n-slate-12">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.BODY.LABEL') }}
              </span>
              <span class="text-n-ruby-9">*</span>
            </div>

            <div class="pl-6 space-y-2">
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-2">
                  <span
                    v-if="bodyVariableCount > 0"
                    class="text-xs px-2 py-0.5 rounded-full bg-n-teal-3 text-n-teal-11"
                  >
                    {{ bodyVariableCount }}
                    {{
                      bodyVariableCount === 1 ? 'variable' : 'variables'
                    }}
                  </span>
                </div>
                <span
                  class="text-xs"
                  :class="
                    bodyCharCount > LIMITS.BODY_MAX
                      ? 'text-n-ruby-9'
                      : 'text-n-slate-10'
                  "
                >
                  {{ bodyCharCount }}/{{ LIMITS.BODY_MAX }}
                </span>
              </div>

              <!-- Parameter format selector -->
              <div class="flex items-center gap-3 pb-2">
                <span class="text-sm text-n-slate-11">
                  {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.BODY.VAR_FORMAT') }}
                </span>
                <ComboBox
                  v-model="state.parameterFormat"
                  :options="parameterFormatOptions"
                  class="w-48"
                />
              </div>

              <!-- Variable insertion button (shows based on selected format) -->
              <div class="flex flex-wrap items-center gap-2 pb-2">
                <span class="text-xs text-n-slate-10">
                  {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.BODY.INSERT_VAR') }}:
                </span>
                <!-- Positional variable button -->
                <button
                  v-if="state.parameterFormat === 'positional'"
                  type="button"
                  class="inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-medium rounded-md border transition-colors bg-n-brand/10 border-n-brand text-n-brand"
                  @click="insertPositionalVariable"
                >
                  <Icon icon="i-lucide-hash" class="size-3.5" />
                  <span>{{ nextVarButtonText }}</span>
                </button>
                <!-- Named variable button -->
                <button
                  v-if="state.parameterFormat === 'named'"
                  type="button"
                  class="inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-medium rounded-md border transition-colors bg-n-brand/10 border-n-brand text-n-brand"
                  @click="insertNamedVariable"
                >
                  <Icon icon="i-lucide-text-cursor-input" class="size-3.5" />
                  <span>{{ namedVarButtonText }}</span>
                </button>
              </div>

              <!-- Formatting buttons -->
              <div class="flex items-center gap-1 pb-2 border-b border-n-weak mb-2">
                <div class="relative">
                  <button
                    type="button"
                    class="p-2 rounded hover:bg-n-slate-3 text-n-slate-11 transition-colors"
                    :class="{ 'bg-n-slate-3': showEmojiPicker }"
                    title="Emoji"
                    @click="toggleEmojiPicker"
                  >
                    <Icon icon="i-lucide-smile" class="size-4" />
                  </button>
                  <EmojiInput
                    v-if="showEmojiPicker"
                    v-on-clickaway="hideEmojiPicker"
                    class="!left-0 !top-10"
                    :on-click="insertEmoji"
                  />
                </div>
                <button
                  type="button"
                  class="p-2 rounded hover:bg-n-slate-3 text-n-slate-11 transition-colors font-bold"
                  title="Bold"
                  @click="insertFormat('bold')"
                >
                  B
                </button>
                <button
                  type="button"
                  class="p-2 rounded hover:bg-n-slate-3 text-n-slate-11 transition-colors italic"
                  title="Italic"
                  @click="insertFormat('italic')"
                >
                  I
                </button>
                <button
                  type="button"
                  class="p-2 rounded hover:bg-n-slate-3 text-n-slate-11 transition-colors line-through"
                  title="Strikethrough"
                  @click="insertFormat('strikethrough')"
                >
                  S
                </button>
                <button
                  type="button"
                  class="p-2 rounded hover:bg-n-slate-3 text-n-slate-11 transition-colors font-mono text-xs"
                  title="Monospace"
                  @click="insertFormat('monospace')"
                >
                  &lt;/&gt;
                </button>
              </div>

              <textarea
                ref="bodyTextareaRef"
                v-model="state.bodyText"
                :placeholder="bodyPlaceholder"
                class="w-full p-3 text-sm rounded-lg border resize-y min-h-[100px] bg-n-alpha-1 focus:ring-1 text-n-slate-12 placeholder:text-n-slate-9"
                :class="
                  errors.body || hasFormatMismatch
                    ? 'border-n-ruby-9 focus:border-n-ruby-9 focus:ring-n-ruby-9'
                    : 'border-n-weak focus:border-n-brand focus:ring-n-brand'
                "
                rows="4"
                @input="handleBodyInput"
                @keydown="handleBodyKeydown"
              />
              <p v-if="errors.body" class="text-xs text-n-ruby-9">
                {{ errors.body }}
              </p>
              <p v-else class="text-xs text-n-slate-10">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.BODY.HELP') }}
              </p>

              <!-- Variable rules info -->
              <div class="flex gap-2 p-2.5 mt-2 rounded-lg bg-n-blue-2 border border-n-blue-6">
                <Icon icon="i-lucide-info" class="size-4 text-n-blue-11 flex-shrink-0 mt-0.5" />
                <div class="text-xs text-n-blue-11">
                  <p>{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.BODY.VAR_RULES') }}</p>
                </div>
              </div>

              <!-- Format mismatch warning -->
              <div v-if="hasFormatMismatch" class="flex gap-2 p-2.5 mt-2 rounded-lg bg-n-ruby-2 border border-n-ruby-6">
                <Icon icon="i-lucide-alert-circle" class="size-4 text-n-ruby-11 flex-shrink-0 mt-0.5" />
                <div class="text-xs text-n-ruby-11">
                  <p v-if="state.parameterFormat === 'positional'">
                    {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.BODY.FORMAT_MISMATCH_POSITIONAL') }}
                  </p>
                  <p v-else>
                    {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.BODY.FORMAT_MISMATCH_NAMED') }}
                  </p>
                </div>
              </div>

              <!-- Variable Examples Section -->
              <div v-if="detectedVariables.length > 0" class="mt-4 p-4 rounded-lg border border-n-weak bg-n-alpha-1">
                <div class="flex items-center gap-2 mb-3">
                  <Icon icon="i-lucide-test-tubes" class="size-4 text-n-slate-11" />
                  <span class="text-sm font-medium text-n-slate-12">
                    {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.BODY.VAR_SAMPLES.TITLE') }}
                  </span>
                </div>
                <p class="text-xs text-n-slate-10 mb-4">
                  {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.BODY.VAR_SAMPLES.DESCRIPTION') }}
                </p>

                <div class="space-y-3">
                  <div
                    v-for="varName in detectedVariables"
                    :key="varName"
                    class="flex items-center gap-3"
                  >
                    <span class="w-24 text-sm font-medium text-n-slate-11 flex-shrink-0 px-2 py-1 rounded bg-n-slate-3">
                      {{ formatVarDisplay(varName) }}
                    </span>
                    <input
                      v-model="state.variableExamples[varName]"
                      type="text"
                      :placeholder="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.BODY.VAR_SAMPLES.PLACEHOLDER', { var: varName })"
                      class="flex-1 px-3 py-2 text-sm rounded-lg border bg-n-alpha-1 border-n-weak focus:border-n-brand focus:ring-1 focus:ring-n-brand text-n-slate-12 placeholder:text-n-slate-9"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Footer Section -->
          <div class="space-y-4">
            <div class="flex items-center gap-2">
              <Icon
                icon="i-lucide-minus"
                class="size-4 text-n-slate-11"
              />
              <span class="text-sm font-medium text-n-slate-12">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.FOOTER.LABEL') }}
              </span>
              <span class="text-xs text-n-slate-10">(Optional)</span>
            </div>

            <div class="pl-6 space-y-2">
              <div class="flex items-center justify-between">
                <label class="block text-sm text-n-slate-11" />
                <span
                  class="text-xs"
                  :class="
                    footerCharCount > LIMITS.FOOTER_MAX
                      ? 'text-n-ruby-9'
                      : 'text-n-slate-10'
                  "
                >
                  {{ footerCharCount }}/{{ LIMITS.FOOTER_MAX }}
                </span>
              </div>
              <Input
                v-model="state.footerText"
                :placeholder="
                  $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.FOOTER.PLACEHOLDER')
                "
                class="w-full"
                :class="{ 'border-n-ruby-9': errors.footer }"
              />
              <p v-if="errors.footer" class="text-xs text-n-ruby-9">
                {{ errors.footer }}
              </p>
              <p v-else class="text-xs text-n-slate-10">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.FOOTER.HELP') }}
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Right: Preview (fixed on large screens) -->
      <div class="w-full lg:w-[430px] p-6 pr-8 bg-n-slate-2 lg:flex-shrink-0 lg:overflow-y-auto">
        <div>
          <p class="mb-4 text-sm font-medium text-center text-n-slate-11">
            {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.PREVIEW.TITLE') }}
          </p>

          <!-- Phone Frame -->
          <div
            class="mx-auto w-[370px] rounded-[2rem] bg-[#E9F6F3] border border-n-slate-6 p-2"
          >
            <!-- Phone Screen -->
            <div class="rounded-[1.5rem] bg-[#efeae2] overflow-hidden">
              <!-- WhatsApp Header -->
              <div
                class="flex items-center gap-3 px-4 py-3 bg-[#075e54] text-white"
              >
                <div
                  class="flex items-center justify-center w-8 h-8 rounded-full bg-white/20"
                >
                  <Icon icon="i-lucide-user" class="size-4" />
                </div>
                <span class="text-sm font-medium">WhatsApp</span>
              </div>

              <!-- Chat Area -->
              <div class="wa-chat-area relative p-3 min-h-[320px]">
                <!-- Message Bubble -->
                <div class="wa-bubble relative w-[330px] max-w-[330px] rounded-lg bg-white shadow-sm">
                  <!-- Header Media Preview -->
                  <div
                    v-if="state.headerFormat === 'IMAGE'"
                    class="flex items-center justify-center h-28 bg-n-slate-3 rounded-t-lg"
                  >
                    <Icon
                      icon="i-lucide-image"
                      class="size-10 text-n-slate-9"
                    />
                  </div>
                  <div
                    v-else-if="state.headerFormat === 'VIDEO'"
                    class="flex items-center justify-center h-28 bg-n-slate-3 rounded-t-lg"
                  >
                    <Icon
                      icon="i-lucide-play-circle"
                      class="size-10 text-n-slate-9"
                    />
                  </div>
                  <div
                    v-else-if="state.headerFormat === 'DOCUMENT'"
                    class="flex items-center gap-2 p-3 bg-n-slate-3 rounded-t-lg"
                  >
                    <Icon
                      icon="i-lucide-file-text"
                      class="size-8 text-n-ruby-9"
                    />
                    <span class="text-xs text-n-slate-11">document.pdf</span>
                  </div>

                  <div class="p-3">
                    <!-- Header Text -->
                    <p
                      v-if="state.headerFormat === 'TEXT' && state.headerText"
                      class="mb-2 whitespace-pre-wrap"
                      style="color: #1C2B33; font-family: 'Optimistic 95', system-ui, sans-serif; font-size: 16px; font-weight: 700; word-wrap: break-word; line-height: 1.25; overflow-wrap: break-word; text-align: initial;"
                      v-html="previewHeaderText"
                    />

                    <!-- Body -->
                    <p
                      class="leading-relaxed whitespace-pre-wrap"
                      style="color: #111827; font-family: 'Segoe UI Historic', 'Segoe UI', Helvetica, Arial, sans-serif; font-size: 13.6px; overflow-wrap: break-word; text-align: initial;"
                      v-html="previewBodyText"
                    />

                    <!-- Footer & Timestamp -->
                    <div class="flex items-end justify-between gap-2" style="padding: 0px 7px 0px 0px;">
                      <span
                        v-if="previewFooterText"
                        style="color: #00000073; font-family: 'Segoe UI Historic', 'Segoe UI', Helvetica, Arial, sans-serif; font-size: 13px; word-break: break-all;"
                      >
                        {{ previewFooterText }}
                      </span>
                      <span v-else />
                      <span style="color: #00000066; font-family: 'Segoe UI Historic', 'Segoe UI', Helvetica, Arial, sans-serif; font-size: 11px; flex-shrink: 0;">12:00 pm</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Preview Note -->
          <p class="mt-4 text-xs text-center text-n-slate-10">
            {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.PREVIEW.NOTE') }}
          </p>
        </div>
      </div>
    </div>

    <!-- Footer Actions -->
    <div
      class="flex items-center justify-end gap-3 px-6 py-4 border-t border-n-weak bg-n-alpha-1 flex-shrink-0"
    >
      <NextButton
        faded
        slate
        :label="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.CANCEL')"
        @click="handleCancel"
      />
      <NextButton
        :label="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.SUBMIT')"
        :is-loading="isLoading"
        :disabled="!isValid"
        @click="handleSubmit"
      />
    </div>
  </div>
</template>

<style scoped>
/* Contain layout to prevent affecting parent scroll */
.template-form-container {
  contain: layout style;
}

/* WhatsApp chat background pattern */
.wa-chat-area::before {
  background: url('@/dashboard/assets/images/whatsapp/wa-background.png');
  background-size: 366.5px 666px;
  content: "";
  height: 100%;
  left: 0;
  opacity: 0.06;
  position: absolute;
  top: 0;
  width: 100%;
  pointer-events: none;
}

/* WhatsApp message bubble tail */
.wa-bubble::before {
  background: url('@/dashboard/assets/images/whatsapp/wa-bubble-tail.png') 50% 50% no-repeat;
  background-size: contain;
  content: "";
  height: 31px;
  left: -12px;
  position: absolute;
  top: -6px;
  width: 12px;
}

/* Remove top-left border radius to connect with tail */
.wa-bubble {
  border-top-left-radius: 0 !important;
  box-shadow: 0 1px .5px #00000026;
}
</style>
