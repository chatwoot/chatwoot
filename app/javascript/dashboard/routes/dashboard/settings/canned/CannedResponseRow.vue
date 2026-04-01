<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  item: {
    type: Object,
    required: true,
  },
  deleting: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['edit', 'delete']);

const { t } = useI18n();
const { getPlainText } = useMessageFormatter();

const plainContent = computed(() => getPlainText(props.item.content || ''));
</script>

<template>
  <div
    class="grid grid-cols-12 items-start gap-y-2 px-6 py-4 transition-all duration-200 hover:bg-surface-container-high/40"
  >
    <div class="col-span-3 min-w-0">
      <span
        class="block truncate font-mono text-sm font-bold text-on-surface"
        :title="item.short_code"
      >
        {{ item.short_code }}
      </span>
    </div>
    <div
      class="col-span-7 min-w-0 whitespace-normal break-words text-sm leading-relaxed text-on-primary-container md:break-all"
    >
      {{ plainContent }}
    </div>
    <div class="col-span-2 flex justify-end gap-1">
      <button
        v-tooltip.top="t('CANNED_MGMT.EDIT.BUTTON_TEXT')"
        type="button"
        :disabled="deleting"
        class="rounded-lg p-2 text-tertiary opacity-70 outline-none transition-all hover:bg-surface-container-high hover:text-secondary hover:opacity-100 focus-visible:ring-2 focus-visible:ring-secondary/40 disabled:pointer-events-none disabled:opacity-40"
        @click="$emit('edit', item)"
      >
        <Icon icon="i-lucide-pen" class="size-5" />
      </button>
      <button
        v-tooltip.top="t('CANNED_MGMT.DELETE.BUTTON_TEXT')"
        type="button"
        :disabled="deleting"
        class="rounded-lg p-2 text-tertiary opacity-70 outline-none transition-all hover:bg-surface-container-high hover:text-error hover:opacity-100 focus-visible:ring-2 focus-visible:ring-error/40 disabled:pointer-events-none disabled:opacity-40"
        @click="$emit('delete', item)"
      >
        <Spinner v-if="deleting" class="size-5" />
        <Icon v-else icon="i-lucide-trash-2" class="size-5" />
      </button>
    </div>
  </div>
</template>
