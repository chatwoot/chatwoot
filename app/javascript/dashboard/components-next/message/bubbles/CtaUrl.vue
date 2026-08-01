<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useMessageContext } from '../provider.js';

const { content, contentAttributes } = useMessageContext();

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

const header = computed(() => contentAttributes.value.header || {});
const action = computed(() => contentAttributes.value.action || {});

const headerMediaUrl = computed(
  () => header.value.mediaUrl || header.value.media_url || ''
);

const actionHref = computed(() => action.value.uri || action.value.url || '');
</script>

<template>
  <BaseBubble class="p-0 overflow-hidden" data-bubble-name="cta-url">
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

      <a
        :href="actionHref"
        target="_blank"
        rel="noopener noreferrer"
        class="skip-context-menu flex items-center justify-center gap-2 border-t border-n-container px-4 py-3 text-n-teal-11 font-medium hover:bg-n-alpha-1"
      >
        <Icon icon="i-lucide-arrow-up-right" class="size-4" />
        <span>{{ action.text }}</span>
      </a>
    </div>
  </BaseBubble>
</template>
