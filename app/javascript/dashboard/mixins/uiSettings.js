import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters({
      uiSettings: 'getUISettings',
    }),
  },
  methods: {
    updateUISettings(uiSettings = {}) {
      this.$store.dispatch('updateUISettings', {
        uiSettings: {
          ...this.uiSettings,
          ...uiSettings,
        },
      });
    },
    isContactSidebarItemOpen(key) {
      const { [key]: isOpen } = this.uiSettings;
      return !!isOpen;
    },
    toggleSidebarUIState(key) {
      this.updateUISettings({ [key]: !this.isContactSidebarItemOpen(key) });
    },
  },
};
