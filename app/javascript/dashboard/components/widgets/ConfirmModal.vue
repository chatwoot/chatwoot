<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header header-title="Change Event type"> </woot-modal-header>
      <div class="row modal-content">
        <div class="medium-12 columns">
          <p>
            Changing the event type will reset the condition and actions you
            have added below.
          </p>
        </div>
        <div class="modal-footer">
          <div class="medium-12 columns">
            <woot-button @click="confirm">
              Proceed
            </woot-button>
            <button class="button clear" @click="cancel">
              {{ $t('IMPORT_CONTACTS.FORM.CANCEL') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </modal>
</template>
<script>
import Modal from '../Modal.vue';

export default {
  components: {
    Modal,
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
    onClose() {
      this.show = false;
      this.rejectPromise();
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
