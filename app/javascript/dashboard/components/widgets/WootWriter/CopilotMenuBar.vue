<script setup>
import { computed, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useElementSize, useWindowSize } from '@vueuse/core';
import { useMapGetter } from 'dashboard/composables/store';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import { useCaptain } from 'dashboard/composables/useCaptain';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownBody from 'next/dropdown-menu/base/DropdownBody.vue';

import Icon from 'next/icon/Icon.vue';

defineProps({
  hasSelection: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['executeCopilotAction']);

const { t } = useI18n();

const { draftMessage } = useCaptain();

const replyMode = useMapGetter('draftMessages/getReplyEditorMode');

// Selection-based menu items (when text is selected)
const menuItems = computed(() => {
  const items = [];
  // for now, we don't allow improving just  aprt of the selection
  // we will add this feature later. Once we do, we can revert the change
  const hasSelection = false;
  // const hasSelection = props.hasSelection

  if (hasSelection) {
    items.push({
      label: t(
        'INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.IMPROVE_REPLY_SELECTION'
      ),
      key: 'improve_selection',
      icon: 'i-fluent-pen-sparkle-24-regular',
    });
  } else if (
    replyMode.value === REPLY_EDITOR_MODES.REPLY &&
    draftMessage.value
  ) {
    items.push({
      label: t('INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.IMPROVE_REPLY'),
      key: 'improve',
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
              'INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.CHANGE_TONE.OPTIONS.PROFESSIONAL'
            ),
            key: 'professional',
          },
          {
            label: t(
              'INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.CHANGE_TONE.OPTIONS.CASUAL'
            ),
            key: 'casual',
          },
          {
            label: t(
              'INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.CHANGE_TONE.OPTIONS.STRAIGHTFORWARD'
            ),
            key: 'straightforward',
          },
          {
            label: t(
              'INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.CHANGE_TONE.OPTIONS.CONFIDENT'
            ),
            key: 'confident',
          },
          {
            label: t(
              'INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.CHANGE_TONE.OPTIONS.FRIENDLY'
            ),
            key: 'friendly',
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

  if (replyMode.value === REPLY_EDITOR_MODES.NOTE || true) {
    items.push({
      label: t('INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.SUMMARIZE'),
      key: 'summarize',
      icon: 'i-fluent-text-bullet-list-square-sparkle-32-regular',
    });
  }

  items.push({
    label: t('INTEGRATION_SETTINGS.OPEN_AI.REPLY_OPTIONS.ASK_COPILOT'),
    key: 'ask_copilot',
    icon: 'i-fluent-circle-sparkle-24-regular',
  });

  return items;
});

const menuRef = useTemplateRef('menuRef');
const { height: menuHeight } = useElementSize(menuRef);
const { width: windowWidth } = useWindowSize();

// Smart submenu positioning based on available space
const submenuPosition = computed(() => {
  const el = menuRef.value?.$el;
  if (!el) return 'ltr:right-full rtl:left-full';

  const { left, right } = el.getBoundingClientRect();
  const SUBMENU_WIDTH = 200;
  const spaceRight = (windowWidth.value ?? window.innerWidth) - right;
  const spaceLeft = left;

  // Prefer right, fallback to side with more space
  const showRight = spaceRight >= SUBMENU_WIDTH || spaceRight >= spaceLeft;

  return showRight ? 'left-full' : 'right-full';
});

// Computed style for selection menu positioning (only dynamic top offset)
const selectionMenuStyle = computed(() => {
  // Dynamically calculate offset based on actual menu height + 10px gap
  const dynamicOffset = menuHeight.value > 0 ? menuHeight.value + 10 : 60;

  return {
    top: `calc(var(--selection-top) - ${dynamicOffset}px)`,
  };
});

const handleMenuItemClick = item => {
  // For items with submenus, do nothing on click (hover will show submenu)
  if (!item.subMenuItems) {
    emit('executeCopilotAction', item.key);
  }
};

const handleSubMenuItemClick = (parentItem, subItem) => {
  emit('executeCopilotAction', subItem.key);
};
</script>

<template>
  <DropdownBody
    ref="menuRef"
    class="min-w-56 [&>ul]:gap-3 z-50 [&>ul]:px-4 [&>ul]:py-3.5"
    :class="{ 'selection-menu': hasSelection }"
    :style="hasSelection ? selectionMenuStyle : {}"
  >
    <div v-if="menuItems.length > 0" class="flex flex-col items-start gap-2.5">
      <div
        v-for="item in menuItems"
        :key="item.key"
        class="w-full relative group/submenu"
      >
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
                icon="i-lucide-chevron-right"
                class="text-n-slate-10 size-3"
              />
            </div>
          </template>
        </Button>

        <!-- Hover Submenu -->
        <DropdownBody
          v-if="item.subMenuItems"
          class="group-hover/submenu:block hidden [&>ul]:gap-2 [&>ul]:px-3 [&>ul]:py-2.5 [&>ul]:dark:!border-n-strong max-h-[15rem] min-w-32 z-10 top-0"
          :class="submenuPosition"
        >
          <Button
            v-for="subItem in item.subMenuItems"
            :key="subItem.key + subItem.label"
            :label="subItem.label"
            slate
            link
            sm
            class="hover:!no-underline text-n-slate-12 font-normal text-xs w-full !justify-start mb-1"
            @click="handleSubMenuItemClick(item, subItem)"
          />
        </DropdownBody>
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
        class="hover:!no-underline text-n-slate-12 font-normal text-xs w-full !justify-start"
        @click="handleMenuItemClick(item)"
      />
    </div>
  </DropdownBody>
</template>

<style scoped lang="scss">
.selection-menu {
  position: absolute !important;

  // Default/LTR: position from left
  left: var(--selection-left);

  // RTL: position from right instead
  [dir='rtl'] & {
    left: auto;
    right: var(--selection-right);
  }
}
</style>
