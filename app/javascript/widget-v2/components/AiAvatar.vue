<script setup>
import { computed } from 'vue';
import { useConfigStore } from 'widget-v2/stores/config';
import { isWebUrl } from 'widget-v2/helpers/urlHelpers';
import BaseAvatar from 'widget-v2/components/base/BaseAvatar.vue';

defineProps({
  size: { type: Number, default: 40 },
});

const configStore = useConfigStore();

// Precedence: the brand's own AI image, then an avatar uploaded to the
// assistant, then a themed glyph — never Chatwoot's Captain mark.
const imageUrl = computed(() => {
  const brandAvatar = configStore.hostBrand?.aiAvatar;
  if (isWebUrl(brandAvatar)) return brandAvatar;
  return configStore.aiAgent?.avatar_url || null;
});

const name = computed(() => configStore.aiAgent?.name || 'AI');
</script>

<template>
  <BaseAvatar v-if="imageUrl" :src="imageUrl" :name="name" :size="size" />
  <span
    v-else
    class="avatar-shape ai-accent-well inline-flex items-center justify-center shrink-0"
    :style="{ width: `${size}px`, height: `${size}px` }"
  >
    <span
      class="i-ph-sparkle-fill"
      :style="{ fontSize: `${Math.round(size * 0.45)}px` }"
    />
  </span>
</template>
