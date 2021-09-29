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
              accept="text/csv"
              @change="handleFileUpload"
            />
          </label>
        </div>
        <div class="modal-footer">
          <div class="medium-12 columns">
            <woot-button
              :disabled="uiFlags.isCreating || !file"
              :loading="uiFlags.isCreating"
              @click="uploadFile"
            >
              {{ $t('IMPORT_CONTACTS.FORM.SUBMIT') }}
            </woot-button>
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
import Modal from '../../../../components/Modal';
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
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
      uiFlags: 'contacts/getUIFlags',
    }),
    csvUrl() {
      return '/downloads/import-contacts-sample.csv';
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
        this.showAlert(
          error.message || this.$t('IMPORT_CONTACTS.ERROR_MESSAGE')
        );
      }
    },
    handleFileUpload() {
      this.file = this.$refs.file.files[0];
    },
  },
};
</script>
