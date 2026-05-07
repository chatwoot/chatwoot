<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  isOpen: { type: Boolean, default: false },
  enabledOptions: { type: Object, default: () => ({}) },
  anchorRect: { type: Object, default: null },
});

const emit = defineEmits(['close', 'reply', 'copy', 'translate', 'delete']);

const VIEWPORT_PADDING = 12;
const MENU_WIDTH = 240;
const ESTIMATED_ITEM_HEIGHT = 50;
const { t } = useI18n();

const visibleItems = computed(() => {
  const items = [];
  if (props.enabledOptions.copy) {
    items.push({
      key: 'copy',
      label: t('CONVERSATION.CONTEXT_MENU.COPY'),
      icon: 'i-lucide-copy',
      danger: false,
    });
  }
  if (props.enabledOptions.translate) {
    items.push({
      key: 'translate',
      label: t('CONVERSATION.CONTEXT_MENU.TRANSLATE'),
      icon: 'i-lucide-languages',
      danger: false,
    });
  }
  if (props.enabledOptions.replyTo) {
    items.push({
      key: 'reply',
      label: t('CONVERSATION.CONTEXT_MENU.REPLY_TO'),
      icon: 'i-lucide-reply',
      danger: false,
    });
  }
  if (props.enabledOptions.delete) {
    items.push({
      key: 'delete',
      label: t('CONVERSATION.CONTEXT_MENU.DELETE'),
      icon: 'i-lucide-trash-2',
      danger: true,
    });
  }
  return items;
});

const menuStyle = ref({});

const computeMenuPosition = () => {
  const rect = props.anchorRect;
  if (!rect) return {};

  const viewportWidth = window.innerWidth;
  const viewportHeight = window.innerHeight;
  const menuHeight =
    ESTIMATED_ITEM_HEIGHT * Math.max(visibleItems.value.length, 1);

  let top = rect.bottom + 8;
  if (top + menuHeight > viewportHeight - VIEWPORT_PADDING) {
    top = Math.max(VIEWPORT_PADDING, rect.top - menuHeight - 8);
  }

  let left;
  if (rect.right >= viewportWidth / 2) {
    left = Math.max(VIEWPORT_PADDING, rect.right - MENU_WIDTH);
  } else {
    left = Math.min(viewportWidth - MENU_WIDTH - VIEWPORT_PADDING, rect.left);
  }
  left = Math.max(VIEWPORT_PADDING, left);

  return {
    top: `${top}px`,
    left: `${left}px`,
    width: `${MENU_WIDTH}px`,
  };
};

watch(
  () => [props.isOpen, props.anchorRect, visibleItems.value.length],
  () => {
    if (props.isOpen) {
      menuStyle.value = computeMenuPosition();
    }
  },
  { immediate: true }
);

const onResize = () => {
  if (props.isOpen) menuStyle.value = computeMenuPosition();
};

onMounted(() => {
  window.addEventListener('resize', onResize);
  window.addEventListener('orientationchange', onResize);
});

onBeforeUnmount(() => {
  window.removeEventListener('resize', onResize);
  window.removeEventListener('orientationchange', onResize);
});

const onOverlayPointerDown = event => {
  event.preventDefault();
  event.stopPropagation();
  emit('close');
};

const handleAction = key => {
  if (key === 'reply') emit('reply');
  else if (key === 'copy') emit('copy');
  else if (key === 'translate') emit('translate');
  else if (key === 'delete') emit('delete');
  emit('close');
};
</script>

<template>
  <Teleport to="body">
    <Transition
      enter-active-class="transition-opacity duration-200 ease-out"
      enter-from-class="opacity-0"
      leave-active-class="transition-opacity duration-150 ease-in"
      leave-to-class="opacity-0"
    >
      <div v-if="isOpen" class="fixed inset-0 z-[100]" @contextmenu.prevent>
        <div
          class="absolute inset-0 bg-white/20 backdrop-blur-md backdrop-saturate-150 dark:bg-black/30"
          @pointerdown="onOverlayPointerDown"
          @touchstart.prevent="onOverlayPointerDown"
        />
        <div
          class="absolute select-none overflow-hidden rounded-[14px] bg-[#f8f8f8]/80 shadow-[0_12px_36px_rgba(0,0,0,0.18),0_1px_2px_rgba(0,0,0,0.08)] backdrop-blur-3xl backdrop-saturate-150 dark:bg-[#282828]/80 dark:shadow-[0_12px_36px_rgba(0,0,0,0.5),0_1px_2px_rgba(0,0,0,0.4)]"
          :style="menuStyle"
          @pointerdown.stop
          @touchstart.stop
        >
          <button
            v-for="item in visibleItems"
            :key="item.key"
            type="button"
            class="flex h-[50px] w-full items-center justify-between border-b border-[rgba(60,60,67,0.18)] px-4 text-left text-[17px] leading-tight transition-colors last:border-b-0 active:bg-black/5 dark:border-white/10 dark:active:bg-white/5"
            :class="[
              item.danger
                ? 'text-red-500 dark:text-red-400'
                : 'text-black dark:text-white',
            ]"
            @click="handleAction(item.key)"
          >
            <span>{{ item.label }}</span>
            <span :class="item.icon" class="size-4.5 flex-shrink-0" />
          </button>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>
