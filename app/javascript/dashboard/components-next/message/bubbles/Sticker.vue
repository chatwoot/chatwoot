<script setup>
import BaseBubble from './Base.vue';
import { useMessageContext } from '../provider.js';
</script>

<script>
export default {
  name: 'StickerBubble',
  components: {
    BaseBubble,
  },
  data() {
    const { contentAttributes } = useMessageContext();
    return {
      contentAttributes: contentAttributes,
    };
  },
  computed: {
    stickerUrl() {
      return this.contentAttributes?.original?.imageUrl;
    },
  },
};
</script>

<template>
  <BaseBubble>
    <div v-if="stickerUrl" class="flex items-center justify-center">
      <img :src="stickerUrl" class="w-35 h-35 rounded-lg" />
    </div>
    <div v-else class="flex items-center justify-center">
      <p class="text-n-slate-11">
        {{ $t('COMPONENTS.MEDIA.STICKER_UNAVAILABLE') }}
      </p>
    </div>
  </BaseBubble>
</template>
