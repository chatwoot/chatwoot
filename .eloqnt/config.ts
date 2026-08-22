import { defineConfig } from '@eloqnt/cli';

export default defineConfig({
  messages: {
    path: [
      './app/javascript/dashboard/i18n/locale/{code}/{namespace}',
      './app/javascript/widget/i18n/locale/{code}',
      './app/javascript/survey/i18n/locale/{code}',
    ],
    // prettier-ignore
    locales: [
      'am', 'ar', 'az', 'bg', 'bn', 'ca', 'cs', 'da', 'de', 'el', 'en', 'es',
      'et', 'fa', 'fi', 'fil', 'fr', 'he', 'hi', 'hr', 'hu', 'hy', 'id', 'is',
      'it', 'ja', 'ka', 'ko', 'lt', 'lv', 'ml', 'ms', 'ne', 'nl', 'no', 'pl',
      'pt', 'pt-BR', 'ro', 'ru', 'sk', 'sl', 'sq', 'sr', 'sr-Latn', 'sv', 'ta',
      'th', 'tr', 'uk', 'ur', 'ur-IN', 'uz', 'vi', 'zh', 'zh-CN', 'zh-TW',
    ],
    sourceLocale: 'en',
    format: {
      codec: '@eloqnt/format-vue-i18n-json',
      extension: '.json',
    },
    codes: {
      fil: 'tl',
      'pt-BR': 'pt_BR',
      'sr-Latn': 'sh',
      'ur-IN': 'ur_IN',
      'zh-CN': 'zh_CN',
      'zh-TW': 'zh_TW',
    },
  },
  lint: {
    overrides: [
      {
        // The widget and survey apps each define this key with the same value
        keys: 'POWERED_BY',
        rules: { 'duplicate-id': 'off' },
      },
    ],
  },
});
