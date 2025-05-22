# AI Assistant Rebranding for Chatwoot

This document outlines the approach taken to rebrand the "Captain" feature to "AI Assistant" and "Assistant" to "Topic" without modifying any enterprise-licensed files.

## Strategy Overview

We implemented a non-invasive rebranding strategy that respects the proprietary license of enterprise files by:

1. Modifying only user-facing text in localization files
2. Adding custom CSS for visual rebranding
3. Using JavaScript to dynamically replace text in the UI
4. Creating a custom logo

## Files Created/Modified

### Localization Changes
- Modified `app/javascript/dashboard/i18n/locale/en/integrations.json` to update all user-facing "Captain" and "Assistant" references
- Modified `app/javascript/dashboard/i18n/locale/en/settings.json` to update menu items and settings text

### CSS Rebranding
- Created `app/javascript/dashboard/assets/scss/custom/ai-assistant-rebranding.scss` with CSS rules to visually replace branding
- Updated `app/javascript/dashboard/assets/scss/_woot.scss` to import the custom CSS

### JavaScript Runtime Rebranding
- Created `app/javascript/dashboard/custom/ai-assistant-rebranding.js` to replace text dynamically in the DOM
- Created `app/javascript/dashboard/custom/index.js` as an entry point for custom modules
- Updated `app/javascript/dashboard/App.vue` to import our custom rebranding code

### Logo & Assets
- Created directory `public/assets/images/dashboard/ai_assistant/`
- Added custom `logo.svg` for the AI Assistant branding

## How It Works

1. **Static Text**: The localization files handle most user-facing text that's loaded from translation files
2. **Dynamic UI**: The JavaScript watches for DOM changes and replaces any instances of "Captain" with "AI Assistant" and "Assistant" with "Topic"
3. **Visual Elements**: The CSS targets elements with Captain branding and updates them to use AI Assistant styling and images

## Notes for Developers

- No enterprise-licensed files were modified in this implementation
- The original functionality remains unchanged, only the branding is different
- This approach can be easily reverted by removing the custom files

## Technical Implementation Details

- CSS uses content replacement and styling overrides
- JavaScript uses MutationObserver to monitor for DOM changes
- Logo is a simple SVG replacement

## Future Enhancements

- Add support for additional languages beyond English
- Create a configuration file to make rebranding terms easily configurable
- Implement a more comprehensive testing strategy for the rebranding 