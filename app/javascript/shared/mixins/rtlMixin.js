import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import { getLanguageDirection } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';

export default {
  mixins: [uiSettingsMixin],
  computed: {
    isRTLView() {
      const { rtl_view: isRTLView } = this.uiSettings;
      return isRTLView;
    },
  },
  methods: {
    updateRTLDirectionView(locale) {
      const isRTLSupported = getLanguageDirection(locale);
      this.updateUISettings({
        rtl_view: isRTLSupported,
      });
    },
  },
};
