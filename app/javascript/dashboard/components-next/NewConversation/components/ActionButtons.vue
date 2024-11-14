<script setup>
import { defineAsyncComponent, ref, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';

import Button from 'dashboard/components-next/button/Button.vue';
import WhatsAppOptions from './WhatsAppOptions.vue';

const props = defineProps({
  isWhatsappInbox: {
    type: Boolean,
    required: true,
  },
  isEmailOrWebWidgetInbox: {
    type: Boolean,
    required: true,
  },
  // isTwilioInbox: {
  //   type: Boolean,
  //   required: true,
  // },
  // isApiInbox: {
  //   type: Boolean,
  //   required: true,
  // },
  messageTemplates: {
    type: Object,
    default: () => {},
  },
  channelType: {
    type: String,
    required: true,
  },
});

const emit = defineEmits([
  'discard',
  'sendMessage',
  'sendWhatsappMessage',
  'insertEmoji',
  'addSignature',
  'removeSignature',
]);

const isEmojiPickerOpen = ref(false);

const EmojiInput = defineAsyncComponent(
  () => import('shared/components/emoji/EmojiInput.vue')
);

const messageSignature = useMapGetter('getMessageSignature');
const signatureToApply = computed(() => messageSignature.value);

const { fetchSignatureFlagFromUISettings, setSignatureFlagForInbox } =
  useUISettings();

const sendWithSignature = computed(() => {
  return fetchSignatureFlagFromUISettings(props.channelType);
});

const isSignatureEnabledForInbox = computed(() => {
  return props.isEmailOrWebWidgetInbox && sendWithSignature.value;
});

const setSignature = () => {
  if (signatureToApply.value) {
    if (isSignatureEnabledForInbox.value) {
      emit('addSignature', signatureToApply.value);
    } else {
      emit('removeSignature', signatureToApply.value);
    }
  }
};

const toggleMessageSignature = () => {
  setSignatureFlagForInbox(props.channelType, !sendWithSignature.value);
  setSignature();
};

const onClickInsertEmoji = emoji => {
  emit('insertEmoji', emoji);
};
</script>

<template>
  <div
    class="flex items-center justify-between w-full h-[52px] gap-2 px-4 py-3"
  >
    <div class="flex items-center gap-2">
      <WhatsAppOptions
        v-if="isWhatsappInbox"
        :message-templates="messageTemplates"
        @send-message="emit('sendWhatsappMessage', $event)"
      />
      <div
        v-if="!isWhatsappInbox"
        v-on-clickaway="() => (isEmojiPickerOpen = false)"
        class="relative"
      >
        <Button
          icon="i-lucide-smile-plus"
          color="slate"
          size="sm"
          class="!w-10"
          @click="isEmojiPickerOpen = !isEmojiPickerOpen"
        />
        <EmojiInput
          v-if="isEmojiPickerOpen"
          class="left-0 top-full mt-1.5"
          :on-click="onClickInsertEmoji"
        />
      </div>
      <Button
        v-if="isEmailOrWebWidgetInbox"
        icon="i-lucide-plus"
        color="slate"
        size="sm"
        class="!w-10"
      />
      <Button
        v-if="isEmailOrWebWidgetInbox"
        icon="i-lucide-type"
        color="slate"
        size="sm"
        class="!w-10"
        @click="toggleMessageSignature"
      />
    </div>

    <div class="flex items-center gap-2">
      <Button
        label="Discard"
        variant="faded"
        color="slate"
        size="sm"
        class="!text-xs font-medium"
        @click="emit('discard')"
      />
      <Button
        v-if="!isWhatsappInbox"
        label="Send (↵)"
        size="sm"
        class="!text-xs font-medium"
        @click="emit('sendMessage')"
      />
    </div>
  </div>
</template>

<style scoped lang="scss">
.emoji-dialog::before {
  @apply hidden;
}
</style>
