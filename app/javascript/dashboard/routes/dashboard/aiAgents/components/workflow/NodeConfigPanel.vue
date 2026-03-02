<script setup>
import { computed, watch, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { NODE_TYPES_META, NODE_CATEGORIES } from './nodeTypes';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  node: { type: Object, default: null },
});

const emit = defineEmits(['update', 'close', 'delete']);
const { t } = useI18n();

const localData = ref({});

const meta = computed(() => {
  if (!props.node) return null;
  return NODE_TYPES_META[props.node.type] || null;
});

const category = computed(() => {
  if (!meta.value) return null;
  return NODE_CATEGORIES[meta.value.category] || null;
});

const configFields = computed(() => meta.value?.configFields || []);

// Sync local data when node changes
watch(
  () => props.node,
  newNode => {
    if (newNode) {
      localData.value = { ...newNode.data };
    }
  },
  { immediate: true, deep: true }
);

function updateField(key, value) {
  localData.value[key] = value;
  emit('update', props.node.id, { [key]: value });
}

function handleDelete() {
  emit('delete', props.node.id);
}
</script>

<template>
  <div
    v-if="node && meta"
    class="flex h-full w-72 flex-col border-l border-n-weak bg-n-background"
  >
    <!-- Header -->
    <div class="flex items-center gap-2 border-b border-n-weak px-4 py-3">
      <span
        :class="[meta.icon, category?.color]"
        class="flex size-7 items-center justify-center rounded-lg text-sm text-white"
      />
      <div class="min-w-0 flex-1">
        <input
          :value="localData.label"
          class="w-full bg-transparent text-sm font-semibold text-n-slate-12 focus:outline-none"
          @input="updateField('label', $event.target.value)"
        />
        <div class="text-[10px] text-n-slate-8">{{ node.type }}</div>
      </div>
      <button
        class="i-lucide-x text-n-slate-8 hover:text-n-slate-12"
        @click="emit('close')"
      />
    </div>

    <!-- Config Fields -->
    <div class="flex-1 space-y-4 overflow-y-auto p-4">
      <div v-for="field in configFields" :key="field.key">
        <label class="mb-1 block text-xs font-medium text-n-slate-11">
          {{ field.label }}
        </label>

        <!-- Text input -->
        <input
          v-if="field.type === 'text'"
          :value="localData[field.key]"
          :placeholder="field.placeholder || ''"
          class="w-full rounded-lg border border-n-weak bg-n-alpha-2 px-3 py-1.5 text-sm text-n-slate-12 placeholder:text-n-slate-8 focus:border-n-brand focus:outline-none"
          @input="updateField(field.key, $event.target.value)"
        />

        <!-- Number input -->
        <input
          v-else-if="field.type === 'number'"
          type="number"
          :value="localData[field.key]"
          :min="field.min"
          :max="field.max"
          class="w-full rounded-lg border border-n-weak bg-n-alpha-2 px-3 py-1.5 text-sm text-n-slate-12 focus:border-n-brand focus:outline-none"
          @input="updateField(field.key, Number($event.target.value))"
        />

        <!-- Textarea -->
        <textarea
          v-else-if="field.type === 'textarea' || field.type === 'code'"
          :value="localData[field.key]"
          :placeholder="field.placeholder || ''"
          rows="4"
          class="w-full rounded-lg border border-n-weak bg-n-alpha-2 px-3 py-1.5 text-sm text-n-slate-12 placeholder:text-n-slate-8 focus:border-n-brand focus:outline-none"
          :class="{ 'font-mono text-xs': field.type === 'code' }"
          @input="updateField(field.key, $event.target.value)"
        />

        <!-- Select -->
        <select
          v-else-if="field.type === 'select'"
          :value="localData[field.key]"
          class="w-full rounded-lg border border-n-weak bg-n-alpha-2 px-3 py-1.5 text-sm text-n-slate-12 focus:border-n-brand focus:outline-none"
          @change="updateField(field.key, $event.target.value)"
        >
          <option
            v-for="opt in field.options"
            :key="opt.value"
            :value="opt.value"
          >
            {{ opt.label }}
          </option>
        </select>

        <!-- Toggle -->
        <label
          v-else-if="field.type === 'toggle'"
          class="flex cursor-pointer items-center gap-2"
        >
          <input
            type="checkbox"
            :checked="localData[field.key]"
            class="size-4 rounded border-n-weak text-n-brand focus:ring-n-brand"
            @change="updateField(field.key, $event.target.checked)"
          />
          <span class="text-sm text-n-slate-11">
            {{
              localData[field.key]
                ? t('AI_AGENTS.WORKFLOW.CONFIG_PANEL.ENABLED')
                : t('AI_AGENTS.WORKFLOW.CONFIG_PANEL.DISABLED')
            }}
          </span>
        </label>

        <!-- Slider -->
        <div
          v-else-if="field.type === 'slider'"
          class="flex items-center gap-3"
        >
          <input
            type="range"
            :value="localData[field.key]"
            :min="field.min"
            :max="field.max"
            :step="field.step"
            class="flex-1"
            @input="updateField(field.key, Number($event.target.value))"
          />
          <span class="w-10 text-right text-sm text-n-slate-11">
            {{ localData[field.key] }}
          </span>
        </div>
      </div>
    </div>

    <!-- Footer -->
    <div class="border-t border-n-weak p-4">
      <Button
        size="small"
        variant="ghost"
        color-scheme="alert"
        icon="i-lucide-trash-2"
        class="w-full"
        @click="handleDelete"
      >
        {{ t('AI_AGENTS.WORKFLOW.CONFIG_PANEL.DELETE_NODE') }}
      </Button>
    </div>
  </div>
</template>
