import uiSettingsMixin from 'dashboard/mixins/uiSettings';

export default {
  mixins: [uiSettingsMixin],
  computed: {
    isRTLView() {
      const { rtl_view: isRTLView } = this.uiSettings;
      return isRTLView;
    },
  },
};
