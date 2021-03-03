<template>
  <woot-modal :show.sync="show" :on-close="onCancel" modal-type="right-aligned">
    <div class="column content-box">
      <woot-modal-header
        :header-title="$t('CREATE_CONTACT.TITLE')"
        :header-content="$t('CREATE_CONTACT.DESC')"
      />
      <contact-form
        :in-progress="uiFlags.isCreating"
        :on-submit="onSubmit"
        @success="onSuccess"
        @cancel="onCancel"
      />
    </div>
  </woot-modal>
</template>

<script>
import { mapGetters } from 'vuex';
import ContactForm from './ContactForm';

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
  },

  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    onSuccess() {
      this.$emit('cancel');
    },
    async onSubmit(contactItem) {
      await this.$store.dispatch('contacts/create', contactItem);
    },
  },
};
</script>
