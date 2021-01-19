---
path: "/docs/contributing/translating-chatwoot-to-your-language"
title: "Translate Chatwoot to your language"
---

Chatwoot uses American English by default. Each and every string available in Chatwoot can be translated to the language of your choice. Chatwoot uses Crowdin to manage the translation process. The updates from Crowdin is also included along with every release.

### How do I see the strings that needs to be translated?

In the codebase the string are placed in the following locations.

- `app/javascript/dashboard/i18n` - The strings related to the agent dashboard
- `app/javascript/widget/i18n` - The strings related to the web widget
- `config/locales` - The strings used in backend messages or API response.

Alternatively, you can login to the **Crowdin** ([https://translate.chatwoot.com](https://translate.chatwoot.com)) and create an account to view the strings that needs to be translated.

### How to contribute?

If you don't find your language on Crowdin, please create an issue on [Github](https://github.com/chatwoot/chatwoot/issues) to add the language.

#### Translate Strings

The translation process for Chatwoot web and mobile app is managed at [https://translate.chatwoot.com](https://translate.chatwoot.com) using Crowdin. You will have to create an account at Crowdin before you can select a language and contribute.

#### Proofreading

Proofreading helps ensure the accuracy and consistency of translations. Right now, the translations are being accepted without a proof reading step. This would be changed in the future as an when there are more contributors on each language.

*Note:* If you are the only person contributing to a language, make sure that you inform any of the Chatwoot members to gain access to manage the language.

#### Releasing a new language

All the translated strings would be included in the next release. If a language has *60% or more translated strings* in Crowdin, we would enable the language in Chatwoot app during the next release.
