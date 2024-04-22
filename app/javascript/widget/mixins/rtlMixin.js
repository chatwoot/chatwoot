import { getLanguageDirection } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';

export default {
  methods: {
    updateDocumentRootView(locale) {
      const html = document.documentElement;

      if (html) {
        html.setAttribute('lang', locale);
        html.setAttribute('dir', getLanguageDirection(locale) ? 'rtl' : 'ltr');
      }
    },
  },
};
