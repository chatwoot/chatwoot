<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useUISettings } from 'dashboard/composables/useUISettings';

const props = defineProps({
  customAttributes: { type: Object, required: true },
});

const { t } = useI18n();
const { uiSettings } = useUISettings();

const contactAttributes = useMapGetter('attributes/getContactAttributes');

const displayAttributes = computed(() => {
  const selectedKeys = uiSettings.value.contact_list_display_properties || [];
  if (!selectedKeys.length) return [];

  return contactAttributes.value
    .filter(
      attr =>
        selectedKeys.includes(attr.attributeKey) &&
        attr.attributeKey in props.customAttributes
    )
    .map(attribute => ({
      attribute,
      value: props.customAttributes[attribute.attributeKey],
    }));
});

const formatValue = (value, displayType) => {
  if (value === null || value === undefined || value === '') return null;

  switch (displayType) {
    case 'checkbox':
      return value
        ? t('CONTACTS_LAYOUT.DISPLAY_PROPERTIES.YES')
        : t('CONTACTS_LAYOUT.DISPLAY_PROPERTIES.NO');
    case 'list':
      return Array.isArray(value) ? value.join(', ') : value;
    case 'date':
      return new Date(value).toLocaleDateString();
    default:
      return String(value);
  }
};
</script>

<template>
  <template
    v-for="(item, index) in displayAttributes"
    :key="item.attribute.attributeKey"
  >
    <div
      v-if="index === 0"
      class="w-px h-3 bg-n-strong rounded-lg flex-shrink-0"
    />
    <div
      v-tooltip.top="{
        content: `${item.attribute.attributeDisplayName}: ${formatValue(item.value, item.attribute.attributeDisplayType)}`,
        delay: { show: 500, hide: 0 },
      }"
      class="flex items-center gap-1 truncate"
    >
      <span class="text-body-main text-n-slate-12 truncate">
        {{ item.attribute.attributeDisplayName }}{{ ':' }}
      </span>
      <span class="text-body-main text-n-slate-11 truncate">
        {{ formatValue(item.value, item.attribute.attributeDisplayType) }}
      </span>
    </div>
    <div
      v-if="index < displayAttributes.length - 1"
      class="w-px h-3 bg-n-strong rounded-lg flex-shrink-0"
    />
  </template>
</template>
