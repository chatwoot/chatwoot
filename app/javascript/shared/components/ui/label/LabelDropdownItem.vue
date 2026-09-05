<script>
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    title: {
      type: String,
      default: '',
    },
    color: {
      type: String,
      default: '',
    },
    selected: {
      type: Boolean,
      default: false,
    },
    pinned: {
      type: Boolean,
      default: false,
    },
    labelId: {
      type: Number,
      required: true,
    },
    showContextMenu: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['selectLabel', 'togglePin', 'openContextMenu', 'closeContextMenu'],

  data() {
    return {
      contextMenuX: 0,
      contextMenuY: 0,
    };
  },

  mounted() {
    document.addEventListener('click', this.closeContextMenu);
  },

  beforeUnmount() {
    document.removeEventListener('click', this.closeContextMenu);
  },

  methods: {
    onClick() {
      this.$emit('selectLabel', this.title);
    },

    onContextMenu(event) {
      event.preventDefault();
      this.contextMenuX = event.clientX;
      this.contextMenuY = event.clientY;
      this.$emit('openContextMenu', this.labelId);
    },

    closeContextMenu() {
      this.$emit('closeContextMenu');
    },

    togglePin() {
      this.$emit('togglePin', this.labelId);
      this.closeContextMenu();
    },
  },
};
</script>

<template>
  <woot-dropdown-item @contextmenu="onContextMenu">
    <NextButton
      slate
      ghost
      blue
      trailing-icon
      :icon="selected ? 'i-lucide-circle-check' : ''"
      class="w-full !px-2.5 justify-between"
      :class="{ '!flex-row': !selected }"
      @click="onClick"
    >
      <div class="flex items-center min-w-0 gap-2">
        <i
          v-if="pinned"
          class="i-lucide-pin text-n-slate-11 size-3 flex-shrink-0"
        />
        <div
          v-if="color"
          class="size-3 flex-shrink-0 rounded-full outline outline-1 outline-n-weak"
          :style="{ backgroundColor: color }"
        />
        <span
          class="overflow-hidden text-ellipsis whitespace-nowrap leading-[1.1]"
          :title="title"
        >
          {{ title }}
        </span>
      </div>
    </NextButton>

    <teleport to="body">
      <div
        v-if="showContextMenu"
        class="fixed bg-n-slate-3 rounded-md shadow-2xl border border-n-slate-6 py-1 z-[999999] min-w-[160px]"
        :style="{ top: `${contextMenuY}px`, left: `${contextMenuX}px` }"
        @click.stop
      >
        <button
          class="w-full px-4 py-2 text-left text-sm hover:bg-n-slate-4 flex items-center gap-2 text-n-slate-12 transition-colors"
          @click="togglePin"
        >
          <i
            :class="pinned ? 'i-lucide-pin-off' : 'i-lucide-pin'"
            class="size-4"
          />
          {{
            pinned
              ? $t('CONTACT_PANEL.LABELS.CONTACT.UNPIN')
              : $t('CONTACT_PANEL.LABELS.CONTACT.PIN')
          }}
        </button>
      </div>
    </teleport>
  </woot-dropdown-item>
</template>
