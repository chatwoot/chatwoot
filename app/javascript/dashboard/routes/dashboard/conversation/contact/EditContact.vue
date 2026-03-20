<script>
import { mapGetters } from 'vuex';
import ContactForm from './ContactForm.vue';

export default {
  components: {
    ContactForm,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    contact: {
      type: Object,
      default: () => ({}),
    },
  },
  emits: ['cancel', 'update:show'],
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
    }),
    localShow: {
      get() {
        return this.show;
      },
      set(value) {
        this.$emit('update:show', value);
      },
    },
  },

  methods: {
    async onClose() {
      const hasChanges = this.$refs.contactForm?.hasUnsavedChanges;
      if (hasChanges) {
        const shouldDiscard =
          await this.$refs.confirmDiscardDialog.showConfirmation();
        if (!shouldDiscard) {
          return;
        }
      }
      this.$emit('cancel');
    },
    onSuccess() {
      this.$emit('cancel');
    },
    async onSubmit(contactItem) {
      await this.$store.dispatch('contacts/update', contactItem);
      await this.$store.dispatch(
        'contacts/fetchContactableInbox',
        this.contact.id
      );
    },
  },
};
</script>

<template>
  <woot-modal
    v-model:show="localShow"
    :on-close="onClose"
    modal-type="right-aligned"
  >
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header
        :header-title="`${$t('EDIT_CONTACT.TITLE')} - ${
          contact.name || contact.email
        }`"
        :header-content="$t('EDIT_CONTACT.DESC')"
      />
      <ContactForm
        ref="contactForm"
        :contact="contact"
        :in-progress="uiFlags.isUpdating"
        :on-submit="onSubmit"
        @success="onSuccess"
        @cancel="onClose"
      />
    </div>
  </woot-modal>
  <woot-confirm-modal
    ref="confirmDiscardDialog"
    :title="$t('EDIT_CONTACT.CONFIRM_DISCARD.TITLE')"
    :description="$t('EDIT_CONTACT.CONFIRM_DISCARD.MESSAGE')"
    :confirm-label="$t('EDIT_CONTACT.CONFIRM_DISCARD.YES')"
    :cancel-label="$t('EDIT_CONTACT.CONFIRM_DISCARD.NO')"
  />
</template>
