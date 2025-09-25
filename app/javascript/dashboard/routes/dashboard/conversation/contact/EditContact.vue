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
    onCancel() {
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
    :on-close="onCancel"
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
        :contact="contact"
        :in-progress="uiFlags.isUpdating"
        :on-submit="onSubmit"
        @success="onSuccess"
        @cancel="onCancel"
      />
    </div>
  </woot-modal>
</template>
