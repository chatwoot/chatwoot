<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import MessageMeta from '../MessageMeta.vue';
import { useMessageContext } from '../provider.js';

const { attachments, shouldGroupWithNext } = useMessageContext();
const { t } = useI18n();

const gif = computed(() => attachments.value[0].meta.giphy);
</script>

<!-- Rendered without a bubble, like a sticker, so a GIF stays compact in the thread. -->
<template>
  <div
    class="relative overflow-hidden rounded-xl w-[12.5rem] bg-n-alpha-2"
    data-bubble-name="giphy"
  >
    <a
      :href="gif.url"
      target="_blank"
      rel="noopener noreferrer nofollow"
      class="block"
    >
      <img
        :src="gif.previewUrl"
        :alt="gif.title"
        :width="gif.width"
        :height="gif.height"
        class="block w-full h-auto"
      />
    </a>
    <span
      class="absolute top-1.5 ltr:left-1.5 rtl:right-1.5 px-1 rounded text-xs font-semibold leading-4 bg-n-slate-12/60 text-n-slate-1"
    >
      {{ t('CHAT_LIST.ATTACHMENTS.giphy.CONTENT') }}
    </span>
    <MessageMeta
      v-if="!shouldGroupWithNext"
      class="absolute bottom-1.5 ltr:right-1.5 rtl:left-1.5 px-1.5 py-0.5 rounded-md bg-n-slate-12/60 text-n-slate-1 [&_*]:!text-n-slate-1"
    />
  </div>
</template>
