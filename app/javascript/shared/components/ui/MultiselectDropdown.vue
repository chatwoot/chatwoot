<script setup>
import { computed } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useToggle } from '@vueuse/core';

import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import EmojiIcon from 'dashboard/components-next/emoji-icon-picker/EmojiIcon.vue';
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
  compact: {
    type: Boolean,
    default: false,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  borderless: {
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

const hasIcon = computed(() => {
  return props.selectedItem?.icon || false;
});

const chevronIcon = computed(() =>
  showSearchDropdown.value ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'
);
</script>

<template>
  <OnClickOutside @trigger="onCloseDropdown">
    <div
      class="relative"
      :class="{
        'w-8 shrink-0': chevronOnly,
        'w-full': !chevronOnly,
        'mb-2': !compact && !chevronOnly && !borderless,
      }"
      @keyup.esc="onCloseDropdown"
    >
      <!-- Chevron-only trigger (header split) — no default slot so icon-only sizing works -->
      <Button
        v-if="chevronOnly"
        color="slate"
        variant="ghost"
        sm
        :disabled="disabled"
        :icon="chevronIcon"
        class="!w-8 !h-8 !min-w-8 !rounded-none !outline-transparent"
        @click="() => toggleDropdown()"
      />
      <Button
        v-else
        color="slate"
        trailing-icon
        :variant="borderless ? 'ghost' : 'outline'"
        :disabled="disabled"
        :size="compact ? 'sm' : undefined"
        :icon="chevronIcon"
        :class="[
          compact ? 'w-full !h-8 !px-2' : 'w-full !px-2',
          borderless
            ? '!outline-none !shadow-none !bg-transparent hover:!bg-n-alpha-2'
            : '',
        ]"
        @click="() => toggleDropdown()"
      >
        <div class="flex items-center flex-1 min-w-0 gap-1">
          <h4 v-if="!hasValue" class="text-sm truncate text-n-slate-12">
            {{ multiselectorPlaceholder }}
          </h4>
          <h4
            v-else
            class="overflow-hidden text-sm leading-tight whitespace-nowrap text-ellipsis text-n-slate-12"
            :title="selectedItem.name"
          >
            {{ selectedItemName }}
          </h4>
        </div>
        <Avatar
          v-if="hasValue && hasThumbnail && (isAgentBot || !hasIcon)"
          :src="selectedThumbnail"
          :status="selectedItem.availability_status"
          :name="selectedItem.name"
          :size="compact ? 20 : 24"
          hide-offline-status
          rounded-full
        >
          <template v-if="isAgentBot && selectedThumbnail" #badge>
            <div
              class="absolute z-20 flex items-center justify-center rounded-full outline outline-1 outline-n-weak bg-n-solid-1 -bottom-0.5 ltr:-right-0.5 rtl:-left-0.5 size-3.5"
            >
              <Icon icon="i-lucide-bot" class="text-n-slate-11 size-2.5" />
            </div>
          </template>
        </Avatar>
        <div
          v-else-if="hasValue && hasIcon && showEmojiIcon"
          class="flex items-center justify-center flex-shrink-0 text-sm rounded-full size-6 outline outline-1 -outline-offset-1 outline-n-weak"
        >
          <EmojiIcon
            :value="selectedItem.icon"
            :color="selectedItem.icon_color"
            class="size-3.5 !text-sm"
          />
        </div>
        <Icon
          v-else-if="hasValue && hasIcon"
          :icon="selectedItem.icon"
          class="size-5 text-n-slate-11"
        />
      </Button>
      <div
        class="box-border border rounded-lg bg-n-alpha-3 backdrop-blur-[100px] absolute shadow-lg border-n-strong dark:border-n-strong p-2 z-[9999] ltr:right-0 rtl:left-0"
        :class="[
          compact || chevronOnly ? 'top-9' : 'top-[2.625rem]',
          chevronOnly ? 'min-w-[16rem] w-max' : 'w-full',
          showSearchDropdown ? 'block visible' : 'hidden invisible',
        ]"
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
          :show-emoji-icon="showEmojiIcon"
          @select="onClickSelectItem"
        />
      </div>
    </div>
  </OnClickOutside>
</template>
