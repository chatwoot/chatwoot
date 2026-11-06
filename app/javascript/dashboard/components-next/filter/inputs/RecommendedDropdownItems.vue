<script setup>
import { useI18n } from 'vue-i18n';
import Icon from 'next/icon/Icon.vue';
import DropdownItem from 'next/dropdown-menu/base/DropdownItem.vue';

// Captain's recommendations at the top of a dropdown, set apart from the regular options below them.
defineProps({
  // [{ key, label }]
  recommendations: { type: Array, required: true },
  // The header of the regular options, such as "All filters".
  optionsLabel: { type: String, required: true },
});

const emit = defineEmits(['select']);
const { t } = useI18n();
</script>

<template>
  <li class="px-2 py-1.5 text-xs font-medium text-n-iris-11 select-none">
    {{ t('FILTER.RECOMMENDED') }}
  </li>
  <DropdownItem
    v-for="recommendation in recommendations"
    :key="recommendation.key"
    :label="recommendation.label"
    @click="emit('select', recommendation.key)"
  >
    <template #icon>
      <Icon icon="i-ph-sparkle-fill" class="size-4 text-n-iris-9" />
    </template>
  </DropdownItem>
  <li class="my-1 border-t border-n-weak" role="separator" />
  <li class="px-2 py-1.5 text-xs font-medium text-n-slate-10 select-none">
    {{ optionsLabel }}
  </li>
</template>
