<template>
  <modal :show.sync="show" :on-close="cancel">
    <div class="column content-box">
      <woot-modal-header :header-title="title" />
      <div class="row modal-content">
        <div class="medium-12 columns">
          <p>
            {{ description }}
          </p>
        </div>
        <div class="modal-footer">
          <div class="medium-12 columns">
            <woot-button @click="confirm">
              {{ confirmLabel }}
            </woot-button>
            <button class="button clear" @click="cancel">
              {{ cancelLabel }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </modal>
</template>
<script>
import Modal from '../../Modal';

export default {
  components: {
    Modal,
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
  },
  data: () => ({
    show: false,
    resolvePromise: undefined,
    rejectPromise: undefined,
  }),

  methods: {
    showConfirmation() {
      this.show = true;
      return new Promise((resolve, reject) => {
        this.resolvePromise = resolve;
        this.rejectPromise = reject;
      });
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
