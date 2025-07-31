<script>
import Modal from '../../Modal.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    Modal,
    NextButton,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
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
  },
  emits: ['update:show', 'confirm', 'cancel'],
  data: () => ({
    localShow: false,
    resolvePromise: undefined,
    rejectPromise: undefined,
  }),
  watch: {
    show(val) {
      this.localShow = val;
    },
  },
  methods: {
    showConfirmation() {
      this.localShow = true;
      this.$emit('update:show', true);
      return new Promise((resolve, reject) => {
        this.resolvePromise = resolve;
        this.rejectPromise = reject;
      });
    },
    confirm() {
      if (this.resolvePromise) {
        this.resolvePromise(true);
      }
      this.$emit('confirm');
      this.localShow = false;
      this.$emit('update:show', false);
    },

    cancel() {
      if (this.resolvePromise) {
        this.resolvePromise(false);
      }
      this.$emit('cancel');
      this.localShow = false;
      this.$emit('update:show', false);
    },
  },
};
</script>

<template>
  <Modal v-model:show="localShow" :on-close="cancel">
    <div class="h-auto overflow-auto flex flex-col">
      <woot-modal-header :header-title="title" :header-content="description" />
      <div class="flex flex-row justify-end gap-2 py-4 px-6 w-full">
        <NextButton faded type="reset" :label="cancelLabel" @click="cancel" />
        <NextButton type="submit" :label="confirmLabel" @click="confirm" />
      </div>
    </div>
  </Modal>
</template>
