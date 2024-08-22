<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="h-auto overflow-auto flex flex-col">
      <woot-modal-header :header-title="pageTitle" />
      <form class="flex flex-col w-full" @submit.prevent="editCannedResponse()">
        <div class="w-full">
          <label :class="{ error: $v.shortCode.$error }">
            {{ $t('CANNED_MGMT.EDIT.FORM.SHORT_CODE.LABEL') }}
            <input
              v-model.trim="shortCode"
              type="text"
              :placeholder="$t('CANNED_MGMT.EDIT.FORM.SHORT_CODE.PLACEHOLDER')"
              @input="$v.shortCode.$touch"
            />
          </label>
        </div>

        <div class="w-full">
          <label :class="{ error: $v.content.$error }">
            {{ $t('CANNED_MGMT.EDIT.FORM.CONTENT.LABEL') }}
          </label>
          <div class="editor-wrap">
            <woot-message-editor
              v-model="content"
              class="message-editor [&>div]:px-1"
              :class="{ editor_warning: $v.content.$error }"
              :enable-variables="true"
              :enable-canned-responses="false"
              :placeholder="$t('CANNED_MGMT.EDIT.FORM.CONTENT.PLACEHOLDER')"
              @blur="$v.content.$touch"
            />
          </div>

          <div class="w-full">
            <div
              v-if="hasAttachments"
              class="attachment-preview-box"
              @paste="onPaste"
            >
              <attachment-preview
                class="flex-col mt-4"
                :attachments="attachedFiles"
                :remove-attachment="removeAttachment"
              />
            </div>
            <canned-bottom-panel
              :enable-multiple-file-upload="true"
              :on-file-upload="onFileUpload"
              :show-file-upload="true"
              :show-attach-help-text="true"
            />
          </div>
        </div>
        <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
          <woot-submit-button
            :disabled="
              $v.content.$invalid ||
              $v.shortCode.$invalid ||
              editCanned.showLoading
            "
            :button-text="$t('CANNED_MGMT.EDIT.FORM.SUBMIT')"
            :loading="editCanned.showLoading"
          />
          <button class="button clear" @click.prevent="onClose">
            {{ $t('CANNED_MGMT.EDIT.CANCEL_BUTTON_TEXT') }}
          </button>
        </div>
      </form>
    </div>
  </modal>
</template>

<script>
/* eslint no-console: 0 */
import { required, minLength } from 'vuelidate/lib/validators';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import WootSubmitButton from '../../../../components/buttons/FormSubmitButton.vue';
import alertMixin from 'shared/mixins/alertMixin';
import Modal from '../../../../components/Modal.vue';
import AttachmentPreview from 'dashboard/components/widgets/AttachmentsPreview.vue';
import CannedBottomPanel from 'dashboard/components/widgets/WootWriter/CannedBottomPanel.vue';
import fileUploadMixin from 'dashboard/mixins/fileUploadMixin';
import { mapGetters } from 'vuex';

export default {
  components: {
    WootSubmitButton,
    Modal,
    WootMessageEditor,
    AttachmentPreview,
    CannedBottomPanel,
  },
  mixins: [alertMixin, fileUploadMixin],
  props: {
    id: { type: Number, default: null },
    edcontent: { type: String, default: '' },
    edshortCode: { type: String, default: '' },
    edattachments: { type: Array, default: () => [] },
    onClose: { type: Function, default: () => {} },
  },
  data() {
    return {
      editCanned: {
        showAlert: false,
        showLoading: false,
      },
      shortCode: this.edshortCode,
      content: this.edcontent,
      show: true,
      attachedFiles: this.formatToAttachedFiles(this.edattachments),
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
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
    hasAttachments() {
      return this.attachedFiles.length;
    },
    pageTitle() {
      return `${this.$t('CANNED_MGMT.EDIT.TITLE')} - ${this.edshortCode}`;
    },
  },
  mounted() {
    // Fetch API Call
    document.addEventListener('paste', this.onPaste);
  },
  destroyed() {
    document.removeEventListener('paste', this.onPaste);
  },
  methods: {
    setPageName({ name }) {
      this.$v.content.$touch();
      this.content = name;
    },
    resetForm() {
      this.shortCode = '';
      this.content = '';
      this.attachedFiles = [];
      this.$v.shortCode.$reset();
      this.$v.content.$reset();
    },
    getCannedPayload() {
      let cannedPayload = {
        id: this.id,
        shortCode: this.shortCode,
        content: this.content,
      };

      if (this.attachedFiles && this.attachedFiles.length) {
        cannedPayload.files = [];
        this.attachedFiles.forEach(attachment => {
          if (
            this.globalConfig.directUploadsEnabled ||
            attachment.blobSignedId
          ) {
            cannedPayload.files.push(attachment.blobSignedId);
          } else {
            cannedPayload.files.push(attachment.resource.file);
          }
        });
      }

      return cannedPayload;
    },
    editCannedResponse() {
      // Show loading on button
      this.editCanned.showLoading = true;
      // Get payload for API call
      const cannedPayload = this.getCannedPayload();
      // Make API Calls
      this.$store
        .dispatch('updateCannedResponse', cannedPayload)
        .then(() => {
          // Reset Form, Show success message
          this.editCanned.showLoading = false;
          this.showAlert(this.$t('CANNED_MGMT.EDIT.API.SUCCESS_MESSAGE'));
          this.resetForm();
          setTimeout(() => {
            this.onClose();
          }, 10);
        })
        .catch(error => {
          this.editCanned.showLoading = false;
          const errorMessage =
            error?.message || this.$t('CANNED_MGMT.EDIT.API.ERROR_MESSAGE');
          this.showAlert(errorMessage);
        });
    },
    attachFile({ blob, file }) {
      const reader = new FileReader();
      reader.readAsDataURL(file.file);
      reader.onloadend = () => {
        this.attachedFiles.push({
          resource: blob || file,
          thumb: reader.result,
          blobSignedId: blob ? blob.signed_id : undefined,
        });
      };
    },
    removeAttachment(itemIndex) {
      this.attachedFiles = this.attachedFiles.filter(
        (item, index) => itemIndex !== index
      );
    },
    onPaste(e) {
      const data = e.clipboardData.files;
      if (!data.length || !data[0]) {
        return;
      }
      data.forEach(file => {
        const { name, type, size } = file;
        this.onFileUpload({ name, type, size, file: file });
      });
    },
    formatToAttachedFiles(attachments) {
      return attachments.map(({ blob, thumb_url, signed_id }) => ({
        resource: blob,
        thumb: thumb_url,
        blobSignedId: signed_id,
      }));
    },
  },
};
</script>
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
