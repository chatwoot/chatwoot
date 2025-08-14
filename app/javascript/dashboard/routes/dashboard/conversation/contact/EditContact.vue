<!-- eslint-disable vue/no-mutating-props -->
<template>
  <woot-modal :show.sync="show" :on-close="onCancel" modal-type="right-aligned">
    <div class="h-auto overflow-auto flex flex-col">
      <woot-modal-header
        :header-title="`${$t('EDIT_CONTACT.TITLE')} - ${displayName}`"
        :header-content="$t('EDIT_CONTACT.DESC')"
      />
      <contact-form
        :contact="contact"
        :in-progress="uiFlags.isUpdating"
        :on-submit="onSubmit"
        @success="onSuccess"
        @cancel="onCancel"
      />
    </div>
  </woot-modal>
</template>

<script>
import { mapGetters } from 'vuex';
import ContactForm from './ContactForm.vue';
import { getContactDisplayName } from 'shared/helpers/contactHelper';

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

  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
    }),
    displayName() {
      return getContactDisplayName(this.contact);
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
