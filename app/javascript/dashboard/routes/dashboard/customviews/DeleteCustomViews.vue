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
  },

  computed: {
    deleteMessage() {
      return `${this.$t(
        'FILTER.CUSTOM_VIEWS.DELETE.MODAL.CONFIRM.MESSAGE'
      )} ${this.activeCustomView && this.activeCustomView.name} ?`;
    },
    deleteConfirmText() {
      return `${this.$t('FILTER.CUSTOM_VIEWS.DELETE.MODAL.CONFIRM.YES')} ${this
        .activeCustomView && this.activeCustomView.name}`;
    },
    deleteRejectText() {
      return `${this.$t('FILTER.CUSTOM_VIEWS.DELETE.MODAL.CONFIRM.NO')} ${this
        .activeCustomView && this.activeCustomView.name}`;
    },
  },

  methods: {
    async deleteSavedCustomViews() {
      try {
        await this.$store.dispatch(
          'customViews/delete',
          Number(this.customViewsId)
        );
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
      if (this.$route.name !== 'home') {
        this.$router.push({ name: 'home' });
      }
    },
    closeDeletePopup() {
      this.$emit('close');
    },
  },
};
</script>
