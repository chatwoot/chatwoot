<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue';

const props = defineProps({
  isOpen: { type: Boolean, default: false },
  enabledOptions: { type: Object, default: () => ({}) },
  anchorRect: { type: Object, default: null },
});

const emit = defineEmits(['close', 'reply', 'copy', 'translate', 'delete']);

const VIEWPORT_PADDING = 12;
const MENU_WIDTH = 240;
const ESTIMATED_ITEM_HEIGHT = 50;

const visibleItems = computed(() => {
  const items = [];
  if (props.enabledOptions.copy) {
    items.push({ key: 'copy', label: 'Copiar', danger: false });
  }
  if (props.enabledOptions.translate) {
    items.push({ key: 'translate', label: 'Traduzir', danger: false });
  }
  if (props.enabledOptions.replyTo) {
    items.push({ key: 'reply', label: 'Responder', danger: false });
  }
  if (props.enabledOptions.delete) {
    items.push({
      key: 'delete',
      label: 'Apagar mensagem',
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
  () => [props.isOpen, props.anchorRect],
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
    <Transition name="ios-context-menu">
      <div
        v-if="isOpen"
        class="ios-context-menu-root fixed inset-0 z-[100]"
        @contextmenu.prevent
      >
        <div
          class="absolute inset-0 ios-context-backdrop"
          @pointerdown="onOverlayPointerDown"
          @touchstart.prevent="onOverlayPointerDown"
        />
        <div
          class="absolute ios-context-menu select-none"
          :style="menuStyle"
          @pointerdown.stop
          @touchstart.stop
        >
          <button
            v-for="(item, index) in visibleItems"
            :key="item.key"
            type="button"
            class="ios-context-menu-item w-full flex items-center justify-between text-left text-[17px] leading-tight px-4 py-3.5 transition-colors active:bg-black/5 dark:active:bg-white/5"
            :class="[
              item.danger
                ? 'text-red-500 dark:text-red-400'
                : 'text-black dark:text-white',
              index !== visibleItems.length - 1
                ? 'ios-context-menu-divider'
                : '',
            ]"
            @click="handleAction(item.key)"
          >
            <span>{{ item.label }}</span>
          </button>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style lang="scss" scoped>
.ios-context-backdrop {
  background-color: rgba(255, 255, 255, 0.18);
  backdrop-filter: blur(8px) saturate(160%);
  -webkit-backdrop-filter: blur(8px) saturate(160%);
}

:global(.dark) .ios-context-backdrop,
.dark .ios-context-backdrop {
  background-color: rgba(0, 0, 0, 0.3);
}

.ios-context-menu {
  border-radius: 14px;
  overflow: hidden;
  background-color: rgba(248, 248, 248, 0.78);
  backdrop-filter: blur(28px) saturate(180%);
  -webkit-backdrop-filter: blur(28px) saturate(180%);
  box-shadow:
    0 12px 36px rgba(0, 0, 0, 0.18),
    0 1px 2px rgba(0, 0, 0, 0.08);
  transform-origin: top right;
}

:global(.dark) .ios-context-menu,
.dark .ios-context-menu {
  background-color: rgba(40, 40, 40, 0.78);
  box-shadow:
    0 12px 36px rgba(0, 0, 0, 0.5),
    0 1px 2px rgba(0, 0, 0, 0.4);
}

.ios-context-menu-divider {
  position: relative;
}

.ios-context-menu-divider::after {
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  height: 0.5px;
  background-color: rgba(60, 60, 67, 0.18);
  pointer-events: none;
}

:global(.dark) .ios-context-menu-divider::after,
.dark .ios-context-menu-divider::after {
  background-color: rgba(255, 255, 255, 0.12);
}

.ios-context-menu-enter-active,
.ios-context-menu-leave-active {
  transition: opacity 0.18s ease;
}

.ios-context-menu-enter-active .ios-context-menu,
.ios-context-menu-leave-active .ios-context-menu {
  transition:
    transform 0.22s cubic-bezier(0.32, 0.72, 0.3, 1),
    opacity 0.18s ease;
}

.ios-context-menu-enter-from,
.ios-context-menu-leave-to {
  opacity: 0;
}

.ios-context-menu-enter-from .ios-context-menu,
.ios-context-menu-leave-to .ios-context-menu {
  opacity: 0;
  transform: scale(0.86);
}
</style>
