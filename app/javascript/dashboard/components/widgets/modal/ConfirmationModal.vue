<script>
import Modal from '../../Modal.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    Modal,
    NextButton,
  },
  props: {
    title: {
      type: String,
      default: 'This is a title',
    },
    description: {
      type: String,
      default: 'This is your description',
    },
    confirmLabel: {
      type: String,
      default: 'Yes',
    },
    cancelLabel: {
      type: String,
      default: 'No',
    },
    confirmOnEnter: {
      type: Boolean,
      default: false,
    },
    enterHint: {
      type: String,
      default: '',
    },
  },
  data: () => ({
    show: false,
    resolvePromise: undefined,
    rejectPromise: undefined,
    enterKeyGlyph: '↵',
  }),

  watch: {
    show(isOpen) {
      if (!this.confirmOnEnter) return;
      if (isOpen) {
        window.addEventListener('keydown', this.onConfirmKeydown, true);
      } else {
        window.removeEventListener('keydown', this.onConfirmKeydown, true);
      }
    },
  },

  beforeUnmount() {
    window.removeEventListener('keydown', this.onConfirmKeydown, true);
  },

  methods: {
    showConfirmation() {
      this.show = true;
      return new Promise((resolve, reject) => {
        this.resolvePromise = resolve;
        this.rejectPromise = reject;
      });
    },
    onConfirmKeydown(event) {
      if (!this.show || !this.confirmOnEnter) return;
      if (event.key === 'Enter' && !event.shiftKey && !event.isComposing) {
        event.preventDefault();
        event.stopPropagation();
        this.confirm();
      }
    },
    confirm() {
      this.resolvePromise(true);
      this.show = false;
    },

    cancel() {
      this.resolvePromise(false);
      this.show = false;
    },
  },
};
</script>

<template>
  <Modal v-model:show="show" :on-close="cancel">
    <div class="h-auto overflow-auto flex flex-col">
      <woot-modal-header :header-title="title" :header-content="description" />
      <p
        v-if="confirmOnEnter && enterHint"
        class="px-6 -mt-2 mb-1 text-sm text-n-slate-11"
      >
        {{ enterHint }}
      </p>
      <div class="flex flex-row justify-end gap-2 py-4 px-6 w-full">
        <NextButton faded type="reset" :label="cancelLabel" @click="cancel" />
        <NextButton type="submit" @click="confirm">
          <span>{{ confirmLabel }}</span>
          <kbd
            v-if="confirmOnEnter"
            class="ms-1.5 inline-flex items-center justify-center min-w-[1.5rem] h-5 px-1 rounded border border-n-strong bg-n-alpha-2 text-xxs font-medium text-n-slate-11"
          >
            {{ enterKeyGlyph }}
          </kbd>
        </NextButton>
      </div>
    </div>
  </Modal>
</template>
