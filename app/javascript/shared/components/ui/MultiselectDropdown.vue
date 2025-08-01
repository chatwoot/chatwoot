<script setup>
import { computed, defineEmits } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useToggle } from '@vueuse/core';

import Button from 'dashboard/components-next/button/Button.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import MultiselectDropdownItems from 'shared/components/ui/MultiselectDropdownItems.vue';

const props = defineProps({
  options: {
    type: Array,
    default: () => [],
  },
  modelValue: {
    // Accept array for multi-select, object for single-select (backward compatible)
    type: [Array, Object],
    default: () => [],
  },
  hasThumbnail: {
    type: Boolean,
    default: true,
  },
  hasCheckbox: {
    type: Boolean,
    default: false,
  },
  multiselectorTitle: {
    type: String,
    default: '',
  },
  multiselectorPlaceholder: {
    type: String,
    default: 'None',
  },
  noSearchResult: {
    type: String,
    default: 'No results found',
  },
  inputPlaceholder: {
    type: String,
    default: 'Search',
  },
  label: {
    type: String,
    default: 'name',
  },
  trackBy: {
    type: String,
    default: 'id',
  },
  multiple: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:modelValue', 'select']);
const [showSearchDropdown, toggleDropdown] = useToggle(false);

const onCloseDropdown = () => toggleDropdown(false);

const isMulti = computed(() => props.multiple || Array.isArray(props.modelValue));

const selectedItems = computed(() => {
  if (isMulti.value) {
    return Array.isArray(props.modelValue) ? props.modelValue : [];
  } else {
    return props.modelValue && props.modelValue[props.trackBy] ? [props.modelValue] : [];
  }
});

const hasValue = computed(() => selectedItems.value.length > 0);

const displayNames = computed(() => {
  if (!hasValue.value) return props.multiselectorPlaceholder;
  return selectedItems.value.map(item => item[props.label]).join(', ');
});

const onClickSelectItem = value => {
  let newValue;
  if (isMulti.value) {
    const exists = selectedItems.value.find(item => item[props.trackBy] === value[props.trackBy]);
    if (exists) {
      newValue = selectedItems.value.filter(item => item[props.trackBy] !== value[props.trackBy]);
    } else {
      newValue = [...selectedItems.value, value];
    }
  } else {
    newValue = value;
    onCloseDropdown();
  }
  emit('update:modelValue', newValue);
  emit('select', newValue);
};
</script>

<template>
  <OnClickOutside @trigger="onCloseDropdown">
    <div class="relative w-full mb-2" @keyup.esc="onCloseDropdown">
      <Button
        type="button"
        slate
        outline
        trailing-icon
        :icon="showSearchDropdown ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        class="w-full !px-2"
        @click="() => toggleDropdown()"
      >
        <div class="flex items-center justify-between w-full min-w-0">
          <h4 class="text-sm text-ellipsis text-n-slate-12">
            {{ displayNames }}
          </h4>
        </div>
        <template v-if="!isMulti && hasValue && hasThumbnail">
          <Thumbnail
            :src="selectedItems[0]?.thumbnail"
            size="24px"
            :status="selectedItems[0]?.availability_status"
            :username="selectedItems[0]?.[props.label]"
          />
        </template>
      </Button>
      <div :class="{ 'dropdown-pane--open': showSearchDropdown }" class="dropdown-pane">
        <div class="flex items-center justify-between mb-1">
          <h4 class="m-0 overflow-hidden text-sm text-n-slate-11 whitespace-nowrap text-ellipsis">
            {{ multiselectorTitle }}
          </h4>
          <Button type="button" ghost slate xs icon="i-lucide-x" @click="onCloseDropdown" />
        </div>
        <MultiselectDropdownItems
          v-if="showSearchDropdown"
          :options="options"
          :selected-items="selectedItems"
          :has-thumbnail="hasThumbnail"
          :has-checkbox="hasCheckbox"
          :input-placeholder="inputPlaceholder"
          :no-search-result="noSearchResult"
          @select="onClickSelectItem"
        />
      </div>
    </div>
  </OnClickOutside>
</template>

<style lang="scss" scoped>
.dropdown-pane {
  @apply box-border top-[2.625rem] left-0 min-w-full max-w-[100vw] max-h-[24rem] overflow-y-auto w-auto absolute;
}
</style>
