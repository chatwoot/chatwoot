<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from '../icon/Icon.vue';
import Spinner from '../spinner/Spinner.vue';

// isActive means Copilot is still working on the newest step. That step then shows on one line under the earlier ones.
const props = defineProps({
  messages: { type: Array, required: true },
  isActive: { type: Boolean, default: false },
});
const { t } = useI18n();
const isExpanded = ref(false);

// A repeated step shows once, at the place it last ran, so the newest step stays at the end.
const steps = computed(() => {
  const byKey = new Map();
  props.messages.forEach(({ message }) => {
    const key = `${message.status}:${message.content}`;
    byKey.delete(key);
    byKey.set(key, { key, ...message });
  });
  return [...byKey.values()];
});
const listedSteps = computed(() =>
  props.isActive ? steps.value.slice(0, -1) : steps.value
);
</script>

<template>
  <div class="flex flex-col gap-1.5 text-xs text-n-slate-11">
    <button
      class="flex items-center gap-2 p-0 text-xs text-start hover:text-n-slate-12 transition-colors duration-200"
      :class="{ 'order-last': isActive }"
      :aria-expanded="isExpanded"
      @click="isExpanded = !isExpanded"
    >
      <template v-if="isActive">
        <Icon
          v-if="steps.at(-1).status === 'failed'"
          icon="i-lucide-triangle-alert"
          class="size-4 flex-shrink-0 text-n-amber-11"
        />
        <Spinner v-else :size="16" class="flex-shrink-0 text-n-slate-9" />
        <span class="truncate">{{ steps.at(-1).content }}</span>
      </template>
      <template v-else>
        <Icon
          :icon="
            isExpanded ? 'i-lucide-chevron-down' : 'i-lucide-chevron-right'
          "
          class="size-4 flex-shrink-0"
        />
        {{ t('CAPTAIN.COPILOT.SHOW_STEPS') }}
        <span
          class="inline-flex items-center justify-center h-4 min-w-4 px-1 font-medium rounded-full bg-n-solid-3"
        >
          {{ steps.length }}
        </span>
      </template>
    </button>
    <template v-if="isExpanded">
      <div
        v-for="step in listedSteps"
        :key="step.key"
        class="flex items-center gap-2"
      >
        <!-- Only Copilot workflows saves a run ID on its steps, so the old Copilot's steps get no status. -->
        <Icon
          v-if="!step.run_id"
          icon="i-lucide-sparkles"
          class="size-4 flex-shrink-0 text-n-slate-9"
        />
        <Icon
          v-else-if="step.status === 'failed'"
          icon="i-lucide-triangle-alert"
          class="size-4 flex-shrink-0 text-n-amber-11"
        />
        <Icon
          v-else
          icon="i-lucide-check"
          class="size-4 flex-shrink-0 text-n-teal-10"
        />
        <span class="truncate">{{ step.content }}</span>
      </div>
    </template>
  </div>
</template>
