<script>
import { mapGetters } from 'vuex';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  name: 'StickerButton',
  components: {
    NextButton,
  },
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  emits: ['openStickerPicker'],
  computed: {
    ...mapGetters('conversations', {
      currentConversation: 'getSelectedChat',
    }),
    shouldShowStickerButton() {
      // Only show for WhatsApp conversations
      return this.isWhatsAppChannel;
    },
    isWhatsAppChannel() {
      return (
        this.inbox?.channel_type === 'Channel::Whatsapp' ||
        this.currentConversation?.inbox?.channel_type === 'Channel::Whatsapp'
      );
    },
  },
  methods: {
    openStickerPicker() {
      this.$emit('openStickerPicker');
    },
  },
};
</script>

<template>
  <NextButton
    v-if="shouldShowStickerButton"
    v-tooltip.top-end="$t('CONVERSATION.STICKER_PICKER.BUTTON_TOOLTIP')"
    icon="i-ph-sticker"
    slate
    faded
    sm
    @click="openStickerPicker"
  />
  <div v-else />
</template>
