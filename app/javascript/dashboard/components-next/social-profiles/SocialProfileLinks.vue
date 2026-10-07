<script setup>
import { computed } from 'vue';
import { isSafeHttpLink } from 'shared/helpers/documentHelper';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import { SOCIAL_NETWORKS, socialProfileUrl } from './socialProfiles';

const props = defineProps({
  profiles: { type: Object, default: () => ({}) },
});

const links = computed(() =>
  Object.entries(props.profiles)
    .map(([network, value]) => ({
      network,
      url: socialProfileUrl(network, value),
      icon: SOCIAL_NETWORKS[network]?.icon || 'i-lucide-link',
    }))
    .filter(({ url }) => isSafeHttpLink(url))
);
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div v-if="links.length" class="flex items-center gap-3">
    <a
      v-for="link in links"
      :key="link.network"
      v-tooltip.top="link.url"
      :href="link.url"
      target="_blank"
      rel="noopener noreferrer nofollow"
      class="text-n-slate-10 hover:text-n-slate-12"
    >
      <Icon :icon="link.icon" class="block size-4" />
    </a>
  </div>
</template>
