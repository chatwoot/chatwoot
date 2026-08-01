<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import { useMessageContext } from '../provider.js';

const { content, contentAttributes } = useMessageContext();

const header = computed(() => contentAttributes.value.header || {});
const buttons = computed(() => contentAttributes.value.buttons || []);

const bodyText = computed(
  () =>
    contentAttributes.value.bodyText ||
    contentAttributes.value.body_text ||
    content.value ||
    ''
);

const footerText = computed(
  () =>
    contentAttributes.value.footerText ||
    contentAttributes.value.footer_text ||
    ''
);

const headerMediaUrl = computed(
  () => header.value.mediaUrl || header.value.media_url || ''
);

const buttonHref = button =>
  (button.type === 'url' ? button.uri : null) || button.uri || '';
</script>

<template>
  <BaseBubble
    class="p-0 overflow-hidden"
    data-bubble-name="interactive-buttons"
  >
    <div class="w-[20rem] max-w-full">
      <img
        v-if="headerMediaUrl"
        :src="headerMediaUrl"
        :alt="bodyText"
        class="w-full h-44 object-cover"
      />

      <div class="px-4 pt-4 pb-3 flex flex-col gap-2">
        <p
          v-if="bodyText"
          v-dompurify-html="bodyText"
          class="prose prose-bubble text-base font-medium"
        />
        <p v-if="footerText" class="text-sm text-n-slate-11">
          {{ footerText }}
        </p>
      </div>

      <div class="border-t border-n-container">
        <component
          :is="buttonHref(button) ? 'a' : 'div'"
          v-for="(button, buttonIndex) in buttons"
          :key="button.id || button.text || buttonIndex"
          :href="buttonHref(button) || undefined"
          :target="buttonHref(button) ? '_blank' : undefined"
          :rel="buttonHref(button) ? 'noopener noreferrer' : undefined"
          class="px-4 py-3 text-center font-medium text-n-teal-11"
          :class="{
            'border-t border-n-container': buttonIndex !== 0,
          }"
        >
          {{ button.text }}
        </component>
      </div>
    </div>
  </BaseBubble>
</template>
