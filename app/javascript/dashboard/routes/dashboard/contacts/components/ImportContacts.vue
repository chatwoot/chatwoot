<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header :header-title="$t('IMPORT_CONTACTS.TITLE')">
        <p>
          Import contacts through a CSV file.
          <a :href="csvUrl" download="sample.csv">Download</a> a sample csv.
        </p>
      </woot-modal-header>
      <div class="row modal-content">
        <div class="medium-12 columns">
          <label>
            <span>{{ $t('IMPORT_CONTACTS.FORM.LABEL') }}</span>
            <input
              id="file"
              ref="file"
              type="file"
              accept=".csv"
              @change="handleFileUpload"
            />
          </label>
        </div>
        <div class="modal-footer">
          <div class="medium-12 columns">
            <woot-submit-button
              :disabled="uiFlags.isCreating || !file"
              :button-text="$t('IMPORT_CONTACTS.FORM.SUBMIT')"
              :loading="uiFlags.isCreating"
              @click="uploadFile"
            />
            <button class="button clear" @click.prevent="onClose">
              {{ $t('IMPORT_CONTACTS.FORM.CANCEL') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </modal>
</template>

<script>
import WootSubmitButton from '../../../../components/buttons/FormSubmitButton';
import Modal from '../../../../components/Modal';
import { mapGetters } from 'vuex';

export default {
  components: {
    WootSubmitButton,
    Modal,
  },
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      show: true,
      file: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'agents/getUIFlags',
    }),
    csvUrl() {
      return 'https://gitcdn.link/repo/chatwoot/chatwoot/develop/spec/assets/contacts.csv';
    },
  },
  methods: {
    async uploadFile() {
      if (!this.file) return;
      await this.$store.dispatch('contacts/import', this.file);
    },
    handleFileUpload() {
      this.file = this.$refs.file.files[0];
    },
  },
};
</script>
