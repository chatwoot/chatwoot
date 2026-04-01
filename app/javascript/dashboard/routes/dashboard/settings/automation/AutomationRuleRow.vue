<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { messageStamp } from 'shared/helpers/timeHelper';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';

const props = defineProps({
  automation: {
    type: Object,
    required: true,
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['toggle', 'edit', 'delete', 'clone']);
const { t } = useI18n();

const readableDate = date => messageStamp(new Date(date), 'LLL d, yyyy');
const readableDateWithTime = date =>
  messageStamp(new Date(date), 'LLL d, yyyy hh:mm a');

const automationActive = computed({
  get: () => props.automation.active,
  set: active => {
    const { id, name } = props.automation;
    emit('toggle', {
      id,
      name,
      status: !active,
    });
  },
});
</script>

<template>
  <div
    class="grid grid-cols-12 items-center gap-y-3 px-6 py-4 transition-all duration-200 hover:bg-surface-container-high/40"
  >
    <div class="col-span-3 min-w-0">
      <span class="block text-sm font-bold break-words text-on-surface">
        {{ automation.name }}
      </span>
    </div>
    <div class="col-span-4 min-w-0 text-sm text-on-primary-container">
      <span class="line-clamp-2">{{
        automation.description || t('AUTOMATION.LIST.EMPTY_PLACEHOLDER')
      }}</span>
    </div>
    <div
      class="col-span-2"
      :class="{ 'pointer-events-none opacity-50': loading }"
    >
      <ToggleSwitch v-model="automationActive" />
    </div>
    <div
      class="col-span-2 text-sm text-on-primary-container"
      :title="readableDateWithTime(automation.created_on)"
    >
      {{ readableDate(automation.created_on) }}
    </div>
    <div class="col-span-1 flex min-h-[2.5rem] items-center justify-end gap-1">
      <Spinner v-if="loading" class="size-5 text-secondary" />
      <template v-else>
        <button
          v-tooltip.top="t('AUTOMATION.FORM.EDIT')"
          type="button"
          class="rounded-lg p-2 text-tertiary opacity-70 outline-none transition-all hover:bg-surface-container-high hover:text-secondary hover:opacity-100 focus-visible:ring-2 focus-visible:ring-secondary/40"
          @click="emit('edit', automation)"
        >
          <Icon icon="i-lucide-pen" class="size-5" />
        </button>
        <button
          v-tooltip.top="t('AUTOMATION.CLONE.TOOLTIP')"
          type="button"
          class="rounded-lg p-2 text-tertiary opacity-70 outline-none transition-all hover:bg-surface-container-high hover:text-secondary hover:opacity-100 focus-visible:ring-2 focus-visible:ring-secondary/40"
          @click="emit('clone', automation)"
        >
          <Icon icon="i-lucide-copy-plus" class="size-5" />
        </button>
        <button
          v-tooltip.top="t('AUTOMATION.FORM.DELETE')"
          type="button"
          class="rounded-lg p-2 text-tertiary opacity-70 outline-none transition-all hover:bg-surface-container-high hover:text-error hover:opacity-100 focus-visible:ring-2 focus-visible:ring-error/40"
          @click="emit('delete', automation)"
        >
          <Icon icon="i-lucide-trash-2" class="size-5" />
        </button>
      </template>
    </div>
  </div>
</template>
