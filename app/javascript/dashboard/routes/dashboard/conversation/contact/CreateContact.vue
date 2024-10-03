<script>
import { defineModel } from 'vue';
import { mapGetters } from 'vuex';
import ContactForm from './ContactForm.vue';

export default {
  components: {
    ContactForm,
  },
  emits: ['cancel'],
  setup() {
    const show = defineModel('show', { type: Boolean, default: false });

    return { show };
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

<template>
  <woot-modal
    v-model:show="show"
    :on-close="onCancel"
    modal-type="right-aligned"
  >
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
