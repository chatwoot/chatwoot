<script setup>
import { computed } from 'vue';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Label from 'dashboard/components-next/label/Label.vue';
import AttributeBadge from 'dashboard/components-next/CustomAttributes/AttributeBadge.vue';
import SettingsListItem from 'dashboard/routes/dashboard/settings/components/SettingsListItem.vue';

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

const emit = defineEmits(['edit', 'delete', 'duplicate']);

const iconByType = {
  text: 'i-lucide-menu',
  checkbox: 'i-lucide-circle-check-big',
  list: 'i-lucide-list',
  date: 'i-lucide-calendar',
  datetime: 'i-lucide-calendar-clock',
  link: 'i-lucide-link',
  number: 'i-lucide-hash',
  currency: 'i-lucide-coins',
  percent: 'i-lucide-percent',
};

const attributeIcon = computed(() => {
  const typeKey = props.attribute.type?.toLowerCase();
  return iconByType[typeKey] || 'i-lucide-menu';
});

const categoryLabel = computed(() =>
  (props.attribute.category || props.attribute.Category || '').trim()
);

const description = computed(
  () => props.attribute.attribute_description || props.attribute.description
);
</script>

<template>
  <SettingsListItem :title="attribute.label">
    <template #icon>
      <Icon :icon="attributeIcon" class="size-5 text-n-slate-11" />
    </template>
    <template #badges>
      <Label :label="attribute.type" compact />
      <AttributeBadge
        v-for="badge in badges"
        :key="badge.type"
        :type="badge.type"
      />
    </template>
    <template #meta>
      <span class="truncate">{{ attribute.value }}</span>
      <template v-if="categoryLabel">
        <div class="w-px h-3 rounded-lg bg-n-strong shrink-0" />
        <span class="truncate">{{ categoryLabel }}</span>
      </template>
      <template v-if="description">
        <div class="w-px h-3 rounded-lg bg-n-strong shrink-0" />
        <span class="truncate">{{ description }}</span>
      </template>
    </template>
    <template #actions>
      <Button
        v-tooltip.top="$t('ATTRIBUTES_MGMT.DUPLICATE.TOOLTIP')"
        icon="i-woot-clone"
        slate
        sm
        @click="emit('duplicate', attribute)"
      />
      <Button
        v-tooltip.top="$t('ATTRIBUTES_MGMT.LIST.BUTTONS.EDIT')"
        icon="i-woot-edit-pen"
        slate
        sm
        @click="emit('edit', attribute)"
      />
      <Button
        v-tooltip.top="$t('ATTRIBUTES_MGMT.LIST.BUTTONS.DELETE')"
        icon="i-woot-bin"
        slate
        sm
        class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
        @click="emit('delete', attribute)"
      />
    </template>
  </SettingsListItem>
</template>
