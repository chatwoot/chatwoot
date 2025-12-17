import { mapGetters } from 'vuex';
import configMixin from './configMixin';

export default {
  mixins: [configMixin],
  computed: {
    ...mapGetters({
      shouldShowFilePicker: 'appConfig/getShouldShowFilePicker',
    }),
    canHandleAttachments() {
      // If enableFileUpload was explicitly set via SDK, prioritize that
      if (this.shouldShowFilePicker !== undefined) {
        return this.shouldShowFilePicker;
      }

      // Otherwise, fall back to inbox settings only
      return this.hasAttachmentsEnabled;
    },
  },
};
