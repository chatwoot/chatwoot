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

<!-- eslint-disable vue/no-mutating-props -->
<template>
  <woot-modal :show.sync="show" :on-close="onCancel" modal-type="right-aligned">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header
        :header-title="$t('CREATE_CONTACT.TITLE')"
        :header-content="$t('CREATE_CONTACT.DESC')"
      />
      <ContactForm
        :in-progress="uiFlags.isCreating"
        :on-submit="onSubmit"
        @success="onSuccess"
        @cancel="onCancel"
      />
    </div>
  </woot-modal>
</template>
