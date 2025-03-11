<script>
/* eslint no-console: 0 */
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Modal from '../../../../components/Modal.vue';
import { useMapGetter } from 'dashboard/composables/store';
import MultiSelect from 'vue-multiselect';

export default {
  components: {
    NextButton,
    Modal,
    WootMessageEditor,
    MultiSelect,
  },
  props: {
    id: { type: Number, default: null },
    edcontent: { type: String, default: '' },
    edshortCode: { type: String, default: '' },
    edinboxIds: { type: Array, default: () => [] },
    onClose: { type: Function, default: () => {} },
  },
  emits: ['updated'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      editCanned: {
        showAlert: false,
        showLoading: false,
      },
      shortCode: this.edshortCode,
      content: this.edcontent,
      selectedInboxIds: [...this.edinboxIds],
      selectedInboxes: [],
      inboxes: [],
      show: true,
    };
  },
  validations: {
    shortCode: {
      required,
      minLength: minLength(2),
    },
    content: {
      required,
    },
  },
  watch: {
    selectedInboxes: {
      handler(newVal) {
        this.selectedInboxIds = newVal.map(inbox => inbox.id);
      },
      deep: true,
    },
  },
  methods: {
    resetForm() {
      this.shortCode = '';
      this.content = '';
      this.selectedInboxIds = [];
      this.selectedInboxes = [];
      if (this.id) {
        this.$emit('reset');
      }
    },
    editCannedResponse() {
      // Show loading on button
      this.editCanned.showLoading = true;
      // Make API Calls
      this.$store
        .dispatch('updateCannedResponse', {
          id: this.id,
          short_code: this.shortCode,
          content: this.content,
          inbox_ids: this.selectedInboxIds,
        })
        .then(() => {
          // Reset Form, Show success message
          this.editCanned.showLoading = false;
          useAlert(this.$t('CANNED_MGMT.EDIT.API.SUCCESS_MESSAGE'));
          this.$emit('updated', {
            id: this.id,
            short_code: this.shortCode,
            content: this.content,
            inbox_ids: this.selectedInboxIds,
          });
          this.resetForm();
          setTimeout(this.onClose, 10);
        })
        .catch(error => {
          this.editCanned.showLoading = false;
          useAlert(error?.message || this.$t('CANNED_MGMT.EDIT.API.ERROR_MESSAGE'));
        });
    },
  },
  mounted() {
    this.inboxes = useMapGetter('inboxes/getInboxes');
    this.selectedInboxes = this.inboxes.filter(inbox => this.edinboxIds.includes(inbox.id));
    this.selectedInboxIds = this.selectedInboxes.map(inbox => inbox.id);
  },
};
</script>

<template>
  <Modal v-model:show="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="$t('CANNED_MGMT.EDIT.TITLE') + ' - ' + edshortCode" />

      <form class="flex flex-col w-full" @submit.prevent="editCannedResponse">
        <div class="w-full">
          <label :class="{ error: v$.shortCode.$error }">
            {{ $t('CANNED_MGMT.EDIT.FORM.SHORT_CODE.LABEL') }}
            <input
              v-model="shortCode"
              type="text"
              :placeholder="$t('CANNED_MGMT.EDIT.FORM.SHORT_CODE.PLACEHOLDER')"
              @input="v$.shortCode.$touch"
            />
          </label>
        </div>

        <div class="w-full">
          <label :class="{ error: v$.content.$error }">
            {{ $t('CANNED_MGMT.EDIT.FORM.CONTENT.LABEL') }}
          </label>
          <div class="editor-wrap">
            <WootMessageEditor
              v-model="content"
              class="message-editor [&>div]:px-1"
              :class="{ editor_warning: v$.content.$error }"
              enable-variables
              :enable-canned-responses="false"
              :placeholder="$t('CANNED_MGMT.EDIT.FORM.CONTENT.PLACEHOLDER')"
              @blur="v$.content.$touch"
            />
          </div>
        </div>

        <div class="w-full">
          <label> Select Inboxes </label>
          <MultiSelect
            v-model="selectedInboxes"
            :options="inboxes"
            :multiple="true"
            :close-on-select="false"
            label="name"
            track-by="id"
            placeholder="Select inboxes"
          />
        </div>

        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <NextButton
            faded
            slate
            type="reset"
            :label="$t('CANNED_MGMT.EDIT.CANCEL_BUTTON_TEXT')"
            @click.prevent="onClose"
          />
          <NextButton
            type="submit"
            :label="$t('CANNED_MGMT.EDIT.FORM.SUBMIT')"
            :disabled="
              v$.content.$invalid ||
              v$.shortCode.$invalid ||
              editCanned.showLoading
            "
            :is-loading="editCanned.showLoading"
          />
        </div>
      </form>
    </div>
  </Modal>
</template>

<style scoped lang="scss">
::v-deep {
  .ProseMirror-menubar {
    @apply hidden;
  }

  .ProseMirror-woot-style {
    @apply min-h-[12.5rem];

    p {
      @apply text-base;
    }
  }
}
</style>
