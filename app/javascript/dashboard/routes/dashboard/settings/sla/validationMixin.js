export default {
  computed: {
    getSlaNameErrorMessage() {
      let errorMessage = '';
      if (this.$v.name.$error) {
        if (!this.$v.name.required) {
          errorMessage = this.$t('SLA.FORM.NAME.REQUIRED_ERROR');
        } else if (!this.$v.name.minLength) {
          errorMessage = this.$t('SLA.FORM.NAME.MINIMUM_LENGTH_ERROR');
        }
      }
      return errorMessage;
    },
  },
};
