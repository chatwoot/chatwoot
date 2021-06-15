export default {
  computed: {
    getLabelTitleErrorMessage() {
      if (!this.title) {
        return this.$t('LABEL_MGMT.FORM.NAME.REQUIRED_ERROR');
      }
      if (!this.$v.title.minLength) {
        return this.$t('LABEL_MGMT.FORM.NAME.MINIMUM_LENGTH_ERROR');
      }
      if (!this.$v.title.validLabelCharacters) {
        return this.$t('LABEL_MGMT.FORM.NAME.VALID_ERROR');
      }
      return '';
    },
  },
};
