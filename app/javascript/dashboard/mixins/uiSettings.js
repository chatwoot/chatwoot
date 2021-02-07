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
  },
};
