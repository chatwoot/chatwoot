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
  selectedItem: {
    type: Object,
    default: () => ({}),
  },
  hasThumbnail: {
    type: Boolean,
    default: true,
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
  disabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select']);
const [showSearchDropdown, toggleDropdown] = useToggle(false);

const onCloseDropdown = () => toggleDropdown(false);
const onClickSelectItem = value => {
  emit('select', value);
  onCloseDropdown();
};

const hasValue = computed(() => {
  if (props.selectedItem && props.selectedItem.id) {
    return true;
  }
  return false;
});
</script>

<template>
  <OnClickOutside @trigger="onCloseDropdown">
    <div class="relative w-full mb-2" @keyup.esc="onCloseDropdown">
      <Button
        slate
        outline
        trailing-icon
        :icon="
          showSearchDropdown ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'
        "
        class="w-full !px-2"
        type="button"
        :disabled="disabled"
        @click="
          () => toggleDropdown() // ensure that the event is not passed to the button
        "
      >
        <div class="flex items-center justify-between w-full min-w-0">
          <h4 v-if="!hasValue" class="text-sm text-ellipsis text-n-slate-12">
            {{ multiselectorPlaceholder }}
          </h4>
          <h4
            v-else
            class="items-center overflow-hidden text-sm leading-tight whitespace-nowrap text-ellipsis text-n-slate-12"
            :title="selectedItem.name"
          >
            {{ selectedItem.name }}
          </h4>
        </div>
        <Thumbnail
          v-if="hasValue && hasThumbnail"
          :src="selectedItem.thumbnail"
          size="24px"
          :status="selectedItem.availability_status"
          :username="selectedItem.name"
        />
      </Button>
      <!-- NOTE: Without @click.prevent, the dropdown does not behave as expected when used inside a <label> tag. -->
      <div
        :class="{ 'dropdown-pane--open': showSearchDropdown }"
        class="dropdown-pane"
        @click.prevent
      >
        <div class="flex items-center justify-between mb-1">
          <h4
            class="m-0 overflow-hidden text-sm text-n-slate-11 whitespace-nowrap text-ellipsis"
          >
            {{ multiselectorTitle }}
          </h4>
          <Button ghost slate xs icon="i-lucide-x" @click="onCloseDropdown" />
        </div>
        <MultiselectDropdownItems
          v-if="showSearchDropdown"
          :options="options"
          :selected-items="[selectedItem]"
          :has-thumbnail="hasThumbnail"
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
  @apply box-border top-[2.625rem] w-full;
}
</style>
