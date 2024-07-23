import { getLanguageDirection } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import { useUISettings } from 'dashboard/composables/useUISettings';

export default {
  setup() {
    const { uiSettings, updateUISettings } = useUISettings();

    return {
      uiSettings,
      updateUISettings,
    };
  },
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
