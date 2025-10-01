<script setup>
import { computed, ref, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useElementSize } from '@vueuse/core';
import { useMapGetter } from 'dashboard/composables/store';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import { useAI } from 'dashboard/composables/useAI';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownBody from 'next/dropdown-menu/base/DropdownBody.vue';

import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  hasSelection: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['executeAction']);

const { t } = useI18n();

const { draftMessage } = useAI();

const replyMode = useMapGetter('draftMessages/getReplyEditorMode');

// Selection-based menu items (when text is selected)
const menuItems = computed(() => {
  const items = [];
  if (props.hasSelection) {
    items.push({
      label: t(
        'INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.IMPROVE_REPLY_SELECTION'
      ),
      key: 'rephrase_selection',
      icon: 'i-fluent-pen-sparkle-24-regular',
    });
  } else if (
    replyMode.value === REPLY_EDITOR_MODES.REPLY &&
    draftMessage.value
  ) {
    items.push({
      label: t('INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.IMPROVE_REPLY'),
      key: 'rephrase',
      icon: 'i-fluent-pen-sparkle-24-regular',
    });
  }

  if (draftMessage.value) {
    items.push(
      {
        label: t(
          'INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.CHANGE_TONE.TITLE'
        ),
        key: 'change_tone',
        icon: 'i-fluent-sound-wave-circle-sparkle-24-regular',
        subMenuItems: [
          {
            label: t(
              'INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.CHANGE_TONE.OPTIONS.FRIENDLY'
            ),
            key: 'make_friendly',
            icon: 'i-fluent-person-voice-16-regular',
          },
          {
            label: t(
              'INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.CHANGE_TONE.OPTIONS.FORMAL'
            ),
            key: 'make_formal',
            icon: 'i-fluent-person-voice-16-regular',
          },
          {
            label: t(
              'INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.CHANGE_TONE.OPTIONS.SIMPLIFY'
            ),
            key: 'simplify',
            icon: 'i-fluent-person-voice-16-regular',
          },
        ],
      },
      {
        label: t('INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.GRAMMAR'),
        key: 'fix_spelling_grammar',
        icon: 'i-fluent-flow-sparkle-24-regular',
      }
    );
  }
  return items;
});

const generalMenuItems = computed(() => {
  const items = [];
  if (replyMode.value === REPLY_EDITOR_MODES.REPLY) {
    items.push({
      label: t('INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.SUGGESTION'),
      key: 'reply_suggestion',
      icon: 'i-fluent-chat-sparkle-16-regular',
    });
  }

  items.push(
    {
      label: t('INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.SUMMARIZE'),
      key: 'summarize',
      icon: 'i-fluent-text-bullet-list-square-sparkle-32-regular',
    },
    {
      label: t('INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.ASK_COPILOT'),
      key: 'ask_copilot',
      icon: 'i-fluent-circle-sparkle-24-regular',
    }
  );

  return items;
});

const menuRef = useTemplateRef('menuRef');

// Track expanded submenu items
const expandedItems = ref(new Set());

const { height: menuHeight } = useElementSize(menuRef);

// Computed style for selection menu positioning
const selectionMenuStyle = computed(() => {
  // Use the same CSS custom properties as the editor menubar
  // Dynamically calculate offset based on actual menu height + 10px gap
  const dynamicOffset = menuHeight.value > 0 ? menuHeight.value + 10 : 60;

  return {
    left: 'var(--selection-left)',
    top: `calc(var(--selection-top) - ${dynamicOffset}px)`,
    transform: 'translateX(-62%)',
  };
});

const handleMenuItemClick = item => {
  if (item.subMenuItems) {
    // Toggle submenu expansion
    if (expandedItems.value.has(item.key)) {
      expandedItems.value.delete(item.key);
    } else {
      expandedItems.value.add(item.key);
    }
  } else {
    emit('executeAction', item.key);
  }
};

const handleSubMenuItemClick = (parentItem, subItem) => {
  emit('executeAction', subItem.key, {
    parentKey: parentItem.key,
    tone: subItem.label.toLowerCase(),
  });
};
</script>

<template>
  <DropdownBody
    ref="menuRef"
    class="min-w-56 [&>ul]:gap-3 z-50 [&>ul]:px-4 [&>ul]:py-3.5"
    :style="hasSelection ? selectionMenuStyle : {}"
  >
    <div v-if="menuItems.length > 0" class="flex flex-col items-start gap-2.5">
      <div v-for="item in menuItems" :key="item.key" class="w-full">
        <Button
          :label="item.label"
          :icon="item.icon"
          slate
          link
          sm
          class="hover:!no-underline text-n-slate-12 font-normal text-xs w-full !justify-start"
          @click="handleMenuItemClick(item)"
        >
          <template v-if="item.subMenuItems" #default>
            <div class="flex items-center gap-1 justify-between w-full">
              <span class="min-w-0 truncate">{{ item.label }}</span>
              <Icon
                :icon="
                  expandedItems.has(item.key)
                    ? 'i-lucide-chevron-up'
                    : 'i-lucide-chevron-down'
                "
                class="text-n-slate-10 size-3 transition-all duration-300 ease-in-out"
              />
            </div>
          </template>
        </Button>

        <!-- Sliding Submenu -->
        <div
          v-if="item.subMenuItems"
          class="overflow-hidden transition-all duration-300 ease-in-out"
          :class="
            expandedItems.has(item.key)
              ? 'max-h-96 opacity-100'
              : 'max-h-0 opacity-0'
          "
        >
          <div class="ltr:pl-5 rtl:pr-5 pt-2 flex flex-col items-start gap-2">
            <Button
              v-for="subItem in item.subMenuItems"
              :key="subItem.key + subItem.label"
              :label="subItem.label"
              slate
              link
              sm
              class="hover:!no-underline text-n-slate-12 font-normal text-xs"
              @click="handleSubMenuItemClick(item, subItem)"
            />
          </div>
        </div>
      </div>
    </div>

    <div v-if="menuItems.length > 0" class="h-px w-full bg-n-strong" />

    <div class="flex flex-col items-start gap-3">
      <Button
        v-for="(item, index) in generalMenuItems"
        :key="index"
        :label="item.label"
        :icon="item.icon"
        slate
        link
        sm
        class="hover:!no-underline text-n-slate-12 font-normal text-xs"
        @click="handleMenuItemClick(item)"
      />
    </div>
  </DropdownBody>
</template>
