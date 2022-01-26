<template>
  <div>
    <woot-delete-modal
      v-if="showDeletePopup"
      :show.sync="showDeletePopup"
      :on-close="closeDeletePopup"
      :on-confirm="deleteSavedCustomViews"
      :title="$t('FILTER.CUSTOM_VIEWS.DELETE.MODAL.CONFIRM.TITLE')"
      :message="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />
  </div>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
export default {
  mixins: [alertMixin],
  props: {
    showDeletePopup: {
      type: Boolean,
      default: false,
    },
    activeCustomView: {
      type: Object,
      default: () => {},
    },
    customViewsId: {
      type: [String, Number],
      default: 0,
    },
    activeFilterType: {
      type: Number,
      default: 0,
    },
  },

  computed: {
    activeCustomViews() {
      if (this.activeFilterType === 0) {
        return 'conversation';
      }
      if (this.activeFilterType === 1) {
        return 'contact';
      }
      return '';
    },
    deleteMessage() {
      return `${this.$t(
        'FILTER.CUSTOM_VIEWS.DELETE.MODAL.CONFIRM.MESSAGE'
      )} ${this.activeCustomView && this.activeCustomView.name} ?`;
    },
    deleteConfirmText() {
      return `${this.$t('FILTER.CUSTOM_VIEWS.DELETE.MODAL.CONFIRM.YES')}`;
    },
    deleteRejectText() {
      return `${this.$t('FILTER.CUSTOM_VIEWS.DELETE.MODAL.CONFIRM.NO')}`;
    },
    isFolderSection() {
      return this.activeFilterType === 0 && this.$route.name !== 'home';
    },
    isSegmentSection() {
      return (
        this.activeFilterType === 1 && this.$route.name !== 'contacts_dashboard'
      );
    },
  },

  methods: {
    async deleteSavedCustomViews() {
      try {
        const id = Number(this.customViewsId);
        const filterType = this.activeCustomViews;
        await this.$store.dispatch('customViews/delete', { id, filterType });
        this.closeDeletePopup();
        this.showAlert(
          this.$t('FILTER.CUSTOM_VIEWS.DELETE.API.SUCCESS_MESSAGE')
        );
      } catch (error) {
        const errorMessage =
          error?.response?.message ||
          this.$t('FILTER.CUSTOM_VIEWS.DELETE.API.ERROR_MESSAGE');
        this.showAlert(errorMessage);
      }
      if (this.isFolderSection) {
        this.$router.push({ name: 'home' });
      }
      if (this.isSegmentSection) {
        this.$router.push({ name: 'contacts_dashboard' });
      }
    },
    closeDeletePopup() {
      this.$emit('close');
    },
  },
};
</script>
