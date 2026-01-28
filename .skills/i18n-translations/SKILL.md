---
name: i18n-translations
description: Add and manage internationalization (i18n) translations in Chatwoot. Use this skill when adding new user-facing text, modifying translations, or implementing multilingual features.
metadata:
  author: chatwoot
  version: "1.0"
---

# Internationalization (i18n)

## Overview

Chatwoot uses separate translation files for backend and frontend:

- **Backend (Rails)**: `config/locales/en.yml`
- **Frontend (Vue)**: `app/javascript/dashboard/i18n/locale/en/` (multiple JSON files)

**Important**: Only update English (`en.yml` and `en.json`) files. Other languages are handled by the community through Crowdin.

## Backend Translations (Rails)

### File Location

```
config/locales/
├── en.yml              # Main English translations
└── [other_lang].yml    # DO NOT EDIT - community managed
```

### Structure

```yaml
# config/locales/en.yml
en:
  conversations:
    messages:
      created: "Message sent successfully"
      deleted: "Message deleted"
    status:
      open: "Open"
      resolved: "Resolved"
      pending: "Pending"
  errors:
    not_found: "Resource not found"
    unauthorized: "You are not authorized to perform this action"
  mailer:
    conversation_reply:
      subject: "New reply in conversation #%{id}"
      greeting: "Hello %{name},"
```

### Usage in Ruby

```ruby
# Simple translation
I18n.t('conversations.status.open')
# => "Open"

# With interpolation
I18n.t('mailer.conversation_reply.subject', id: 123)
# => "New reply in conversation #123"

# In controllers
flash[:notice] = t('conversations.messages.created')

# In models
errors.add(:base, I18n.t('errors.unauthorized'))

# In mailers
subject I18n.t('mailer.conversation_reply.subject', id: @conversation.id)
```

## Frontend Translations (Vue)

### File Structure

```
app/javascript/dashboard/i18n/locale/en/
├── index.js            # Exports all translations
├── conversation.json   # Conversation-related
├── contact.json        # Contact-related
├── settings.json       # Settings pages
├── integrations.json   # Integrations
└── ...
```

### JSON Structure

```json
// conversation.json
{
  "CONVERSATION": {
    "HEADER": {
      "TITLE": "Conversations",
      "SEARCH_PLACEHOLDER": "Search conversations..."
    },
    "STATUS": {
      "OPEN": "Open",
      "RESOLVED": "Resolved",
      "PENDING": "Pending"
    },
    "ACTIONS": {
      "RESOLVE": "Resolve",
      "REOPEN": "Reopen",
      "ASSIGN": "Assign to {agent}"
    },
    "MESSAGES": {
      "NO_MESSAGES": "No messages yet",
      "TYPING": "{name} is typing..."
    }
  }
}
```

### Usage in Vue Components

```vue
<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

// With interpolation
const assignMessage = computed(() => 
  t('CONVERSATION.ACTIONS.ASSIGN', { agent: agent.name })
);
</script>

<template>
  <!-- Simple translation -->
  <h1>{{ t('CONVERSATION.HEADER.TITLE') }}</h1>
  
  <!-- With interpolation -->
  <span>{{ t('CONVERSATION.MESSAGES.TYPING', { name: userName }) }}</span>
  
  <!-- In attributes -->
  <input :placeholder="t('CONVERSATION.HEADER.SEARCH_PLACEHOLDER')" />
</template>
```

### Using in JavaScript (outside components)

```javascript
import { useI18n } from 'vue-i18n';

export function useConversationLabels() {
  const { t } = useI18n();
  
  return {
    getStatusLabel: (status) => t(`CONVERSATION.STATUS.${status.toUpperCase()}`),
  };
}
```

## Adding New Translations

### Step 1: Add to English Files

**Backend (en.yml)**:
```yaml
en:
  new_feature:
    title: "New Feature"
    description: "This is a new feature"
    actions:
      save: "Save"
      cancel: "Cancel"
```

**Frontend (new_feature.json)**:
```json
{
  "NEW_FEATURE": {
    "TITLE": "New Feature",
    "DESCRIPTION": "This is a new feature",
    "ACTIONS": {
      "SAVE": "Save",
      "CANCEL": "Cancel"
    }
  }
}
```

### Step 2: Register Frontend Translations

```javascript
// app/javascript/dashboard/i18n/locale/en/index.js
import newFeature from './new_feature.json';

export default {
  // ... existing imports
  ...newFeature,
};
```

## Best Practices

### Never Use Bare Strings

```vue
<!-- ❌ Wrong -->
<button>Save Changes</button>
<span>No conversations found</span>

<!-- ✅ Correct -->
<button>{{ t('COMMON.SAVE') }}</button>
<span>{{ t('CONVERSATION.EMPTY_STATE') }}</span>
```

### Use Semantic Keys

```yaml
# ❌ Wrong - too generic
en:
  button1: "Save"
  message1: "Success"

# ✅ Correct - descriptive hierarchy
en:
  conversations:
    actions:
      save: "Save conversation"
    messages:
      save_success: "Conversation saved successfully"
```

### Handle Pluralization

```yaml
# en.yml
en:
  conversations:
    count:
      one: "%{count} conversation"
      other: "%{count} conversations"
```

```ruby
# Usage
I18n.t('conversations.count', count: 5)
# => "5 conversations"
```

```json
// Frontend (en.json)
{
  "CONVERSATION": {
    "COUNT": "{count} conversation | {count} conversations"
  }
}
```

```vue
<span>{{ t('CONVERSATION.COUNT', { count: conversationCount }, conversationCount) }}</span>
```

### Interpolation

```yaml
# Backend
en:
  greeting: "Hello, %{name}!"
  assigned: "Assigned to %{agent} by %{assigner}"
```

```json
// Frontend
{
  "GREETING": "Hello, {name}!",
  "ASSIGNED": "Assigned to {agent} by {assigner}"
}
```

## File Organization

| Content Type | Backend File | Frontend File |
|-------------|--------------|---------------|
| Conversations | `en.yml` → `conversations:` | `conversation.json` |
| Contacts | `en.yml` → `contacts:` | `contact.json` |
| Settings | `en.yml` → `settings:` | `settings.json` |
| Errors | `en.yml` → `errors:` | `settings.json` → `ERRORS` |
| Common/Shared | `en.yml` → `common:` | `settings.json` → `COMMON` |

## Testing Translations

```ruby
# spec/i18n_spec.rb
require 'rails_helper'

RSpec.describe 'I18n' do
  it 'has no missing translations' do
    missing = I18n.backend.send(:translations)[:en].deep_find_missing
    expect(missing).to be_empty
  end
end
```

## Crowdin Integration

- English files are synced to Crowdin
- Community translators provide other languages
- Translations are pulled back automatically
- Never edit non-English files directly
