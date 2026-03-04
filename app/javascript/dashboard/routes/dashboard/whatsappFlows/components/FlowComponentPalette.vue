<script setup>
import { useI18n } from 'vue-i18n';
import {
  COMPONENT_CATEGORIES,
  COMPONENT_ICONS,
  COMPONENT_LABELS,
  createDefaultComponent,
} from 'dashboard/helper/whatsappFlowHelper';

const emit = defineEmits(['select', 'close']);
const { t } = useI18n();
function onSelect(type) {
  emit('select', createDefaultComponent(type));
}
</script>

<template>
  <div
    class="absolute inset-0 z-20 bg-black/30 flex items-center justify-center"
    @click.self="emit('close')"
  >
    <div
      class="bg-white rounded-xl shadow-xl w-96 max-h-[80vh] overflow-hidden flex flex-col"
    >
      <div
        class="flex items-center justify-between px-4 py-3 border-b border-n-weak"
      >
        <h3 class="text-sm font-semibold text-n-slate-12">
          {{ t('WHATSAPP_FLOWS.PALETTE.TITLE') }}
        </h3>
        <button
          class="p-1 rounded text-n-slate-9 hover:bg-n-alpha-1"
          @click="emit('close')"
        >
          <span class="i-lucide-x size-4" />
        </button>
      </div>

      <div class="flex-1 overflow-y-auto p-4 space-y-4">
        <div v-for="category in COMPONENT_CATEGORIES" :key="category.key">
          <h4
            class="text-[10px] font-semibold text-n-slate-9 uppercase tracking-wide mb-2"
          >
            {{ t(category.label) }}
          </h4>
          <div class="grid grid-cols-2 gap-2">
            <button
              v-for="type in category.components"
              :key="type"
              class="flex items-center gap-2 px-3 py-2.5 rounded-lg border border-n-weak hover:border-n-brand hover:bg-n-brand-subtle/30 transition-colors text-left"
              @click="onSelect(type)"
            >
              <span
                class="size-4 text-n-slate-9"
                :class="[COMPONENT_ICONS[type]]"
              />
              <span class="text-xs font-medium text-n-slate-11">
                {{ COMPONENT_LABELS[type] }}
              </span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
