<template>
  <woot-modal
    :show="show"
    :on-close="onCancel"
    size="medium"
    :full-height="false"
  >
    <div class="h-auto overflow-auto flex flex-col">
      <woot-modal-header :header-title="'Compose Whatsapp'" />
    </div>
    <one-click-contact-conversation-form
      :is-an-email-inbox="true"
      channel-to-compare="Channel::Api"
      @success="onSuccess"
      @cancel="onCancel"
    />
  </woot-modal>
</template>

<script>
import OneClickContactConversationForm from './OneClickContactConversationForm.vue';

export default {
  components: {
    OneClickContactConversationForm,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
  },
  methods: {
    onCancel() {
      this.$emit('close-whatsapp-broadcast-modal');
    },
    onSuccess() {
      this.$emit('close-whatsapp-broadcast-modal');
    },
  },
};
</script>
