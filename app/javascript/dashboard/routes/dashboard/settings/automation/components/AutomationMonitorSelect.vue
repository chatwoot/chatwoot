<script setup>
import { computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  options: {
    type: Array,
    default: () => [],
  },
  selectedName: {
    type: String,
    default: '',
  },
  loading: {
    type: Boolean,
    default: false,
  },
  error: {
    type: Boolean,
    default: false,
  },
  invalid: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['retry']);

const monitorId = defineModel({ type: Number, default: null });

const { accountScopedRoute } = useAccount();

const isEmpty = computed(
  () => !props.loading && !props.error && !props.options.length
);
const isSelectionMissing = computed(
  () =>
    Boolean(monitorId.value) &&
    !props.options.some(({ id }) => id === monitorId.value)
);
</script>

<template>
  <div>
    <label :class="{ error: invalid }">
      {{ $t('AUTOMATION.ADD.FORM.MONITOR.LABEL') }}
      <select
        v-model.number="monitorId"
        class="m-0"
        :disabled="loading || isEmpty"
      >
        <option :value="null">
          {{ $t('AUTOMATION.ADD.FORM.MONITOR.PLACEHOLDER') }}
        </option>
        <option v-if="isSelectionMissing" :value="monitorId" disabled>
          {{ selectedName || $t('AUTOMATION.ADD.FORM.MONITOR.UNAVAILABLE') }}
        </option>
        <option
          v-for="monitor in options"
          :key="monitor.id"
          :value="monitor.id"
        >
          {{ monitor.name }}
        </option>
      </select>
      <span v-if="invalid" class="message">
        {{ $t('AUTOMATION.ADD.FORM.MONITOR.ERROR') }}
      </span>
    </label>
    <p
      v-if="error"
      role="alert"
      class="mt-2 flex flex-wrap items-center gap-x-2 text-xs text-n-ruby-11"
    >
      {{ $t('AUTOMATION.ADD.FORM.MONITOR.FETCH_FAILED') }}
      <button
        type="button"
        class="p-0 text-xs underline-offset-2 hover:underline"
        @click="emit('retry')"
      >
        {{ $t('AUTOMATION.ADD.FORM.MONITOR.RETRY') }}
      </button>
    </p>
    <p
      v-else-if="isEmpty"
      class="mt-2 flex flex-wrap items-center gap-x-1 text-xs text-n-slate-11"
    >
      {{ $t('AUTOMATION.ADD.FORM.MONITOR.EMPTY') }}
      <RouterLink
        :to="accountScopedRoute('monitor_reports_index')"
        class="inline-flex text-xs items-center gap-1 text-n-blue-11 underline-offset-2 hover:underline"
      >
        {{ $t('AUTOMATION.ADD.FORM.MONITOR.GO_TO_MONITORS') }}
        <Icon
          icon="ltr:i-lucide-arrow-right rtl:i-lucide-arrow-left"
          class="size-3"
        />
      </RouterLink>
    </p>
    <p
      v-else-if="isSelectionMissing && !loading"
      class="mt-2 text-xs text-n-amber-11"
    >
      {{ $t('AUTOMATION.ADD.FORM.MONITOR.UNAVAILABLE_HELP') }}
    </p>
    <p v-else class="mt-2 text-xs text-n-slate-11">
      {{ $t('AUTOMATION.ADD.FORM.MONITOR.HELP') }}
    </p>
  </div>
</template>
