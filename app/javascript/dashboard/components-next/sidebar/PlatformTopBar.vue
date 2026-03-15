<script setup>
import { computed } from 'vue';

const config = computed(() => window.chatwootConfig || {});

const CURRENT_PLATFORM = 'nexus';

const platforms = computed(() => {
  const hubUrl = config.value.hubUrl || '';
  const amplexUrl = config.value.amplexUrl || '';
  const entityUrl = config.value.entityUrl || '';

  return [
    { key: 'hub', name: 'Hub', url: hubUrl, icon: '🏠' },
    { key: 'entity', name: 'Entity', url: entityUrl, icon: '🔍' },
    { key: 'amplex', name: 'Amplex', url: amplexUrl, icon: '📊' },
    { key: 'nexus', name: 'Nexus', url: '', icon: '💬' },
  ].filter(p => p.key === CURRENT_PLATFORM || p.url);
});
</script>

<template>
  <div
    class="fixed top-0 left-0 right-0 h-10 flex items-center px-4 gap-1 z-[60]"
    style="
      background: rgba(14, 17, 28, 0.95);
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
      border-bottom: 1px solid rgba(45, 56, 71, 0.3);
    "
  >
    <a
      v-for="p in platforms"
      :key="p.key"
      :href="p.key === CURRENT_PLATFORM ? undefined : p.url"
      class="flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs no-underline transition-all duration-200"
      :class="
        p.key === CURRENT_PLATFORM
          ? 'bg-[rgba(0,112,255,0.12)] border border-[rgba(0,112,255,0.25)] text-white font-semibold cursor-default'
          : 'border border-transparent text-white/55 hover:bg-white/[0.06] hover:text-white cursor-pointer'
      "
      @click.prevent="
        () => {
          if (p.key !== CURRENT_PLATFORM && p.url) {
            window.location.href = p.url;
          }
        }
      "
    >
      <span class="text-sm">{{ p.icon }}</span>
      <span>{{ p.name }}</span>
    </a>
  </div>
</template>
