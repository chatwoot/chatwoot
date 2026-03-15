<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';

const props = defineProps({
  isCollapsed: { type: Boolean, default: false },
});

const isOpen = ref(false);
const containerRef = ref(null);

const config = computed(() => window.chatwootConfig || {});

const products = computed(() => {
  const hubUrl = config.value.hubUrl || '';
  const amplexUrl = config.value.amplexUrl || '';
  const entityUrl = config.value.entityUrl || '';

  return [
    { key: 'hub', name: 'Hub', desc: 'Painel Central', url: hubUrl, icon: '🏠' },
    { key: 'amplex', name: 'Amplex', desc: 'CRM', url: amplexUrl, icon: '📊' },
    { key: 'nexus', name: 'Nexus', desc: 'Atendimento', url: '', icon: '💬' },
    { key: 'entity', name: 'Entity', desc: 'Dados CNPJ', url: entityUrl, icon: '🔍' },
  ].filter(p => p.key === 'nexus' || p.key === 'hub' || p.url);
});

function handleClickOutside(e) {
  if (containerRef.value && !containerRef.value.contains(e.target)) {
    isOpen.value = false;
  }
}

onMounted(() => document.addEventListener('mousedown', handleClickOutside));
onBeforeUnmount(() =>
  document.removeEventListener('mousedown', handleClickOutside)
);
</script>

<template>
  <div ref="containerRef" class="relative">
    <button
      class="grid place-content-center size-8 rounded-lg transition-colors"
      :class="
        isOpen
          ? 'bg-n-brand/10 outline outline-1 outline-n-brand/30'
          : 'hover:bg-n-alpha-1'
      "
      :title="isCollapsed ? 'Plataformas' : undefined"
      @click="isOpen = !isOpen"
    >
      <svg
        width="16"
        height="16"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linecap="round"
        stroke-linejoin="round"
        class="text-n-slate-11"
      >
        <rect x="3" y="3" width="7" height="7" rx="1.5" />
        <rect x="14" y="3" width="7" height="7" rx="1.5" />
        <rect x="3" y="14" width="7" height="7" rx="1.5" />
        <rect x="14" y="14" width="7" height="7" rx="1.5" />
      </svg>
    </button>

    <Teleport to="body">
      <div
        v-if="isOpen"
        class="fixed z-[999] w-60 p-1.5 bg-n-solid-2 border border-n-weak rounded-xl shadow-lg"
        :style="{
          bottom: '3.5rem',
          left: isCollapsed ? '0.5rem' : '0.5rem',
        }"
      >
        <p class="px-2.5 pt-1.5 pb-1 text-[0.625rem] font-semibold uppercase tracking-wider text-n-slate-9">
          Plataformas
        </p>
        <a
          v-for="p in products"
          :key="p.key"
          :href="p.key === 'nexus' ? undefined : p.url"
          class="flex items-center gap-2.5 px-2.5 py-2 rounded-lg no-underline transition-colors"
          :class="
            p.key === 'nexus'
              ? 'bg-n-brand/8 outline outline-1 outline-n-brand/15 cursor-default'
              : 'hover:bg-n-alpha-1 cursor-pointer'
          "
          @click.prevent="
            () => {
              if (p.key !== 'nexus' && p.url) {
                isOpen = false;
                window.location.href = p.url;
              }
            }
          "
        >
          <span class="flex items-center justify-center w-8 h-8 rounded-lg text-lg bg-n-alpha-1 flex-shrink-0">
            {{ p.icon }}
          </span>
          <div class="min-w-0">
            <p class="m-0 text-sm font-semibold text-n-slate-12">
              {{ p.name }}
            </p>
            <p class="m-0 text-xs text-n-slate-10">{{ p.desc }}</p>
          </div>
          <span
            v-if="p.key === 'nexus'"
            class="ml-auto text-[0.6rem] font-semibold text-n-brand bg-n-brand/10 px-1.5 py-0.5 rounded"
          >
            ATUAL
          </span>
        </a>
      </div>
    </Teleport>
  </div>
</template>
