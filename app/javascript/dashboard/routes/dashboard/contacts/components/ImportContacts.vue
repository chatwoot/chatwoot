<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header :header-title="$t('IMPORT_CONTACTS.TITLE')">
        <p>
          {{ $t('IMPORT_CONTACTS.DESC') }}
          <a :href="csvUrl" download="import-contacts-sample">{{
            $t('IMPORT_CONTACTS.DOWNLOAD_LABEL')
          }}</a>
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
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    WootSubmitButton,
    Modal,
  },
  mixins: [alertMixin],
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
      return '/assets/import-contacts-sample.csv';
    },
  },
  methods: {
    async uploadFile() {
      try {
        if (!this.file) return;
        await this.$store.dispatch('contacts/import', this.file);
        this.onClose();
        this.showAlert(this.$t('IMPORT_CONTACTS.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('IMPORT_CONTACTS.ERROR_MESSAGE'));
      }
    },
    handleFileUpload() {
      this.file = this.$refs.file.files[0];
    },
  },
};
</script>
