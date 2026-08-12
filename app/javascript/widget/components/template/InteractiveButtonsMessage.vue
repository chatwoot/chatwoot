<script setup>
import { computed } from 'vue';
import { IFrameHelper } from 'widget/helpers/utils';

const props = defineProps({
  message: {
    type: String,
    default: '',
  },
  messageContentAttributes: {
    type: Object,
    default: () => ({}),
  },
});

const bodyText = computed(
  () => props.messageContentAttributes.body_text || props.message
);
const footerText = computed(
  () => props.messageContentAttributes.footer_text || ''
);
const headerMediaUrl = computed(
  () => props.messageContentAttributes.header?.media_url || ''
);
const buttons = computed(() => props.messageContentAttributes.buttons || []);
const buttonHref = button =>
  (button.type === 'url' ? button.uri : null) || button.uri || '';
const onButtonClick = button => {
  if (buttonHref(button)) return;
  if (!IFrameHelper.isIFrame()) return;

  IFrameHelper.sendMessage({
    event: 'postback',
    data: { payload: button.id },
  });
};
</script>

<template>
  <div
    class="chat-bubble agent bg-n-background dark:bg-n-solid-3 text-n-slate-12 max-w-80 rounded-lg overflow-hidden"
  >
    <img
      v-if="headerMediaUrl"
      :src="headerMediaUrl"
      :alt="bodyText"
      class="w-full h-40 object-cover"
    />

    <div class="px-4 pt-4 pb-3">
      <p class="text-base font-medium text-n-slate-12">
        {{ bodyText }}
      </p>
      <p v-if="footerText" class="mt-2 text-sm text-n-slate-11">
        {{ footerText }}
      </p>
    </div>

    <div class="border-t border-n-strong">
      <component
        :is="buttonHref(button) ? 'a' : 'button'"
        v-for="(button, buttonIndex) in buttons"
        :key="button.id || button.text || buttonIndex"
        :href="buttonHref(button) || undefined"
        :target="buttonHref(button) ? '_blank' : undefined"
        :rel="buttonHref(button) ? 'noopener noreferrer' : undefined"
        class="w-full px-4 py-3 text-center text-n-brand font-medium"
        :class="{
          'border-t border-n-strong': buttonIndex !== 0,
        }"
        @click="onButtonClick(button)"
      >
        {{ button.text }}
      </component>
    </div>
  </div>
</template>
