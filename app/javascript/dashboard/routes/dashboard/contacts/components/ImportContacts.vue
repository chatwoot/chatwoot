<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="$t('IMPORT_CONTACTS.TITLE')">
        <p>
          {{ $t('IMPORT_CONTACTS.DESC') }}
          <a :href="csvUrl" download="import-contacts-sample">{{
            $t('IMPORT_CONTACTS.DOWNLOAD_LABEL')
          }}</a>
        </p>
      </woot-modal-header>
      <div class="flex flex-col p-8">
        <div class="w-full">
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
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <div class="w-full">
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
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { CONTACTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import Modal from '../../../../components/Modal.vue';

export default {
  components: {
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
      uiFlags: 'contacts/getUIFlags',
    }),
    csvUrl() {
      return '/downloads/import-contacts-sample.csv';
    },
  },
  mounted() {
    this.$track(CONTACTS_EVENTS.IMPORT_MODAL_OPEN);
  },
  methods: {
    async uploadFile() {
      try {
        if (!this.file) return;
        await this.$store.dispatch('contacts/import', this.file);
        this.onClose();
        useAlert(this.$t('IMPORT_CONTACTS.SUCCESS_MESSAGE'));
        this.$track(CONTACTS_EVENTS.IMPORT_SUCCESS);
      } catch (error) {
        useAlert(error.message || this.$t('IMPORT_CONTACTS.ERROR_MESSAGE'));
        this.$track(CONTACTS_EVENTS.IMPORT_FAILURE);
      }
    },
    handleFileUpload() {
      this.file = this.$refs.file.files[0];
    },
  },
};
</script>
