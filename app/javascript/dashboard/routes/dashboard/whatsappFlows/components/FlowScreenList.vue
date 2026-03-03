<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

const props = defineProps({
  screens: { type: Array, required: true },
  activeIndex: { type: Number, required: true },
});

const emit = defineEmits(['select', 'add', 'remove', 'updateTitle', 'updateId']);
</script>

<template>
  <aside class="w-56 border-r border-n-weak bg-white flex flex-col overflow-hidden">
    <div class="flex items-center justify-between px-3 py-3 border-b border-n-weak">
      <span class="text-xs font-semibold text-n-slate-11 uppercase tracking-wide">
        {{ t('WHATSAPP_FLOWS.SCREENS.TITLE') }}
      </span>
      <button
        class="p-1 rounded text-n-slate-9 hover:text-n-brand hover:bg-n-brand-subtle"
        :title="t('WHATSAPP_FLOWS.SCREENS.ADD')"
        @click="emit('add')"
      >
        <span class="i-lucide-plus size-4" />
      </button>
    </div>

    <div class="flex-1 overflow-y-auto p-2 space-y-1">
      <div
        v-for="(screen, index) in props.screens"
        :key="screen.id"
        :class="[
          'group flex items-center justify-between px-3 py-2 rounded-lg cursor-pointer text-sm transition-colors',
          index === props.activeIndex
            ? 'bg-n-brand-subtle text-n-brand-dark font-medium'
            : 'text-n-slate-11 hover:bg-n-alpha-1',
        ]"
        @click="emit('select', index)"
      >
        <div class="flex items-center gap-2 min-w-0 flex-1">
          <span class="i-lucide-layout size-4 shrink-0" />
          <span class="truncate">{{ screen.title }}</span>
          <span
            v-if="screen.terminal"
            class="text-[10px] px-1 py-0.5 rounded bg-n-teal-2 text-n-teal-11 shrink-0"
          >
            {{ t('WHATSAPP_FLOWS.SCREENS.TERMINAL') }}
          </span>
        </div>
        <button
          v-if="props.screens.length > 1"
          class="opacity-0 group-hover:opacity-100 p-1 rounded text-n-slate-9 hover:text-n-ruby-9"
          @click.stop="emit('remove', index)"
        >
          <span class="i-lucide-x size-3" />
        </button>
      </div>
    </div>

    <!-- Variables summary -->
    <div class="border-t border-n-weak px-3 py-2">
      <span class="text-[10px] font-semibold text-n-slate-9 uppercase tracking-wide">
        {{ t('WHATSAPP_FLOWS.SCREENS.SUMMARY') }}
      </span>
      <div class="text-xs text-n-slate-11 mt-1">
        {{ props.screens.length }} {{ t('WHATSAPP_FLOWS.SCREENS.SCREEN_COUNT') }}
      </div>
    </div>
  </aside>
</template>
