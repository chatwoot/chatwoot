# Template Preview System

A comprehensive template preview system for WhatsApp and Twilio templates that provides real-time visual previews during template selection, campaign creation, and displays accurate rendered templates in message threads.

## Features

- **Multi-Platform Support**: WhatsApp and Twilio templates
- **Real-Time Preview**: Interactive variable editing with live preview updates
- **Template Type Detection**: Automatic detection and routing to appropriate preview components
- **Variable Validation**: Real-time validation with error states
- **Responsive Design**: Works across mobile and desktop
- **Storybook Integration**: Complete component documentation and examples

## Supported Template Types

### WhatsApp Templates
- **Text Templates**: Simple text with variables
- **Media Templates**: Image/Video/Document headers with text
- **Interactive Templates**: URL, Phone, Quick Reply buttons
- **Copy Code Templates**: Discount/promo code functionality
- **Combined Templates**: Media + Text + Buttons

### Twilio Templates  
- **Text Templates**: Simple text with variables
- **Media Templates**: Text + Image/Video
- **Quick Reply Templates**: Interactive action buttons

## Usage

### Basic Usage

```vue
<template>
  <TemplatePreview
    :template="whatsAppTemplate"
    :variables="templateVariables"
    :mode="'interactive'"
    :platform="'whatsapp'"
    @variable-change="handleVariableChange"
    @validation-change="handleValidationChange"
  />
</template>

<script setup>
import { TemplatePreview } from '@/components-next/template-preview';

const handleVariableChange = ({ key, value, variables }) => {
  console.log(`Variable ${key} changed to ${value}`);
};

const handleValidationChange = ({ isValid, errors }) => {
  console.log('Template is valid:', isValid);
};
</script>
```

### Preview Modes

- **`display`**: Static preview with populated variables (for sent messages)
- **`interactive`**: Live editing with input fields (for campaign creation)
- **`placeholder`**: Show example values from template definition

### Integration Examples

See the stories in `stories/TemplatePreview.stories.js` for comprehensive examples covering all template types and use cases.

## Component Architecture

```
template-preview/
├── TemplatePreview.vue          # Main container component
├── components/                  # Shared UI components
│   ├── MessageBubble.vue       # Platform-specific message bubble
│   └── VariableInput.vue       # Variable input field
├── whatsapp/                   # WhatsApp-specific previews
│   ├── WhatsAppTextPreview.vue
│   ├── WhatsAppMediaPreview.vue
│   ├── WhatsAppButtonPreview.vue
│   └── WhatsAppCopyCodePreview.vue
├── twilio/                     # Twilio-specific previews
│   ├── TwilioTextPreview.vue
│   ├── TwilioMediaPreview.vue
│   └── TwilioQuickReplyPreview.vue
└── stories/                    # Storybook documentation
    └── TemplatePreview.stories.js
```

## Services & Composables

- **`TemplateTypeDetector`**: Identifies template types across platforms
- **`TemplateNormalizer`**: Converts platform-specific formats to unified structure  
- **`useTemplateVariables`**: Composable for variable management and validation

## Development

### Running Storybook

```bash
npm run storybook
```

### Adding New Template Types

1. Add type detection logic in `TemplateTypeDetector.js`
2. Add normalization logic in `TemplateNormalizer.js`
3. Create preview component in appropriate platform folder
4. Add component mapping in `TemplatePreview.vue`
5. Add story examples in `TemplatePreview.stories.js`

## Design System

The system uses Chatwoot's existing design tokens and follows the established component patterns:

- **Colors**: Uses `n-alpha-2`, `n-slate-12`, etc. from the design system
- **Spacing**: Consistent with existing message bubble components
- **Typography**: Matches WhatsApp/platform styling
- **Buttons**: Uses existing `Button.vue` component

## Testing

The system includes comprehensive Storybook stories that serve as both documentation and visual regression testing. Each template type and mode combination is covered.