<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import AttributeBadge from 'dashboard/components-next/CustomAttributes/AttributeBadge.vue';
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  attribute: {
    type: Object,
    required: true,
  },
  badges: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['edit', 'delete']);

const { t } = useI18n();

const iconByType = {
  text: 'i-lucide-align-justify',
  checkbox: 'i-lucide-circle-check-big',
  list: 'i-lucide-list',
  date: 'i-lucide-calendar',
  link: 'i-lucide-link',
  number: 'i-lucide-hash',
};

const attributeIcon = computed(() => {
  const typeKey = props.attribute.type?.toLowerCase();
  return iconByType[typeKey] || 'i-lucide-align-justify';
});
</script>

<template>
  <div
    class="flex flex-col gap-3 px-4 py-5 transition-colors duration-200 hover:bg-surface-container-high/40 sm:px-6"
  >
    <div class="flex flex-wrap items-start justify-between gap-3">
      <div class="flex min-w-0 flex-1 flex-col gap-2">
        <div class="flex flex-wrap items-center gap-2">
          <h4 class="mb-0 truncate text-sm font-bold text-on-surface">
            {{ attribute.label }}
          </h4>
          <div v-if="badges.length" class="flex flex-wrap items-center gap-2">
            <AttributeBadge
              v-for="badge in badges"
              :key="badge.type"
              :type="badge.type"
            />
          </div>
        </div>
        <div
          class="flex flex-wrap items-center gap-x-3 gap-y-1 text-sm text-on-primary-container"
        >
          <div class="flex items-center gap-1.5">
            <Icon :icon="attributeIcon" class="size-4 shrink-0 text-tertiary" />
            <span>{{ attribute.type }}</span>
          </div>
          <span
            class="hidden h-3 w-px bg-outline-variant/30 sm:inline-block"
            aria-hidden="true"
          />
          <div class="flex min-w-0 items-center gap-1.5">
            <Icon
              icon="i-lucide-key-round"
              class="size-4 shrink-0 text-tertiary"
            />
            <span class="line-clamp-1 font-mono text-xs">{{
              attribute.value
            }}</span>
          </div>
        </div>
      </div>
      <div class="flex shrink-0 items-center gap-1">
        <button
          v-tooltip.top="t('ATTRIBUTES_MGMT.LIST.BUTTONS.EDIT')"
          type="button"
          class="rounded-lg p-2 text-tertiary opacity-70 outline-none transition-all hover:bg-surface-container-high hover:text-secondary hover:opacity-100 focus-visible:ring-2 focus-visible:ring-secondary/40"
          @click="emit('edit', attribute)"
        >
          <Icon icon="i-lucide-pen" class="size-5" />
        </button>
        <button
          v-tooltip.top="t('ATTRIBUTES_MGMT.LIST.BUTTONS.DELETE')"
          type="button"
          class="rounded-lg p-2 text-tertiary opacity-70 outline-none transition-all hover:bg-surface-container-high hover:text-error hover:opacity-100 focus-visible:ring-2 focus-visible:ring-error/40"
          @click="emit('delete', attribute)"
        >
          <Icon icon="i-lucide-trash-2" class="size-5" />
        </button>
      </div>
    </div>
    <p
      v-if="attribute.attribute_description || attribute.description"
      class="mb-0 text-sm leading-relaxed text-on-surface-variant"
    >
      {{ attribute.attribute_description || attribute.description }}
    </p>
  </div>
</template>
