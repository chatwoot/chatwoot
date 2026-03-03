<script setup>
import { computed } from 'vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import MessageMeta from '../MessageMeta.vue';
import FormattedContent from './Text/FormattedContent.vue';
import AttachmentChips from 'next/message/chips/AttachmentChips.vue';
import { useMessageContext } from '../provider.js';
import { useI18n } from 'vue-i18n';
import { MESSAGE_VARIANTS, ORIENTATION } from '../constants.js';

const { content, contentAttributes, attachments, variant, orientation } =
  useMessageContext();
const { t } = useI18n();

const templateInfo = computed(
  () => contentAttributes.value?.templateInfo || {}
);

const header = computed(() => templateInfo.value.header || null);
const footer = computed(() => templateInfo.value.footer || '');
const buttons = computed(() => templateInfo.value.buttons || []);

const hasMediaHeader = computed(() => {
  if (!header.value) return false;
  return ['IMAGE', 'VIDEO', 'DOCUMENT'].includes(header.value.format);
});

const hasTextHeader = computed(() => {
  return header.value?.format === 'TEXT' && header.value?.text;
});

const mediaUrl = computed(() => header.value?.mediaUrl || '');

// Separate CTA buttons (URL, PHONE, FLOW, COPY_CODE) from Quick Reply buttons
const ctaButtons = computed(() =>
  buttons.value.filter(b =>
    ['URL', 'PHONE_NUMBER', 'FLOW', 'COPY_CODE'].includes(b.type)
  )
);

const quickReplyButtons = computed(() =>
  buttons.value.filter(b => b.type === 'QUICK_REPLY')
);

const ctaButtonIcon = button => {
  const icons = {
    URL: 'i-lucide-external-link',
    PHONE_NUMBER: 'i-lucide-phone',
    COPY_CODE: 'i-lucide-copy',
    FLOW: 'i-lucide-git-branch',
  };
  return icons[button.type] || 'i-lucide-circle';
};

const handleButtonClick = button => {
  if (button.type === 'URL' && button.url) {
    window.open(button.url, '_blank', 'noopener,noreferrer');
  }
};

const metaAlignClass = computed(() =>
  orientation.value === ORIENTATION.RIGHT ? 'justify-end' : 'justify-start'
);

const metaColorClass = computed(() =>
  variant.value === MESSAGE_VARIANTS.PRIVATE
    ? 'text-n-amber-12/50'
    : 'text-n-slate-11'
);
</script>

<template>
  <div class="flex flex-col max-w-80">
    <BaseBubble
      hide-meta
      class="p-0 overflow-hidden"
      data-bubble-name="whatsapp-template"
    >
      <div class="flex flex-col">
        <!-- Header media -->
        <div v-if="hasMediaHeader && mediaUrl">
          <img
            v-if="header.format === 'IMAGE'"
            :src="mediaUrl"
            alt=""
            class="w-full max-h-44 object-cover rounded-t-lg"
          />
          <video
            v-else-if="header.format === 'VIDEO'"
            :src="mediaUrl"
            controls
            class="w-full max-h-44"
          />
          <a
            v-else-if="header.format === 'DOCUMENT'"
            :href="mediaUrl"
            target="_blank"
            rel="noopener noreferrer"
            class="flex items-center gap-2 p-3 bg-n-alpha-1 hover:bg-n-alpha-2"
          >
            <span class="i-lucide-file-text size-5 text-n-slate-11" />
            <span class="text-sm text-n-blue-11 truncate">
              {{ t('CONVERSATION.WHATSAPP_TEMPLATE.VIEW_DOCUMENT') }}
            </span>
          </a>
        </div>

        <!-- Text header -->
        <div v-if="hasTextHeader" class="px-3 pt-3 pb-0">
          <p class="text-sm font-semibold text-n-slate-12">
            {{ header.text }}
          </p>
        </div>

        <!-- Body + meta -->
        <div class="px-3 py-2.5">
          <FormattedContent v-if="content" :content="content" />
          <AttachmentChips :attachments="attachments" class="gap-2 mt-2" />
          <MessageMeta :class="[metaAlignClass, metaColorClass]" class="mt-2" />
        </div>

        <!-- Footer -->
        <div v-if="footer" class="px-3 pb-2.5">
          <p class="text-xs text-n-slate-10">{{ footer }}</p>
        </div>

        <!-- CTA buttons (URL, Phone, Flow, Copy) — inside the bubble -->
        <div v-if="ctaButtons.length" class="border-t border-n-weak">
          <button
            v-for="(button, index) in ctaButtons"
            :key="`cta-${index}`"
            class="flex items-center justify-center gap-1.5 w-full px-3 py-2 text-sm font-medium text-n-blue-11 hover:bg-n-alpha-1 transition-colors"
            :class="{ 'border-t border-n-weak': index > 0 }"
            @click="handleButtonClick(button)"
          >
            <span :class="ctaButtonIcon(button)" class="size-3.5" />
            <span>{{ button.text }}</span>
          </button>
        </div>
      </div>
    </BaseBubble>

    <!-- Quick Reply buttons — separate pills below the bubble -->
    <div v-if="quickReplyButtons.length" class="flex flex-wrap gap-1.5 mt-1.5">
      <button
        v-for="(button, index) in quickReplyButtons"
        :key="`qr-${index}`"
        class="flex-1 min-w-0 px-3 py-2 text-sm font-semibold text-n-blue-11 bg-white dark:bg-n-solid-3 rounded-lg shadow-sm border border-n-strong hover:bg-n-alpha-1 transition-colors text-center truncate"
      >
        {{ button.text }}
      </button>
    </div>
  </div>
</template>
