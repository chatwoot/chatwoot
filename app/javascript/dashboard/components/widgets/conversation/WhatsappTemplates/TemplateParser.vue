<template>
  <div class="w-full">
    <div :class="{ 'max-h-[22.75rem] overflow-y-auto': !removeOverflow }">
      <div
        v-for="(componentVariables, componentType) in variables"
        :key="componentType"
      >
        <h3>
          {{ `${componentType.toUpperCase()}` }}
        </h3>
        <textarea
          v-if="processedString[componentType]"
          v-model="processedString[componentType]"
          rows="10"
          readonly
          class="template-input"
        />
        <div
          v-if="
            componentVariables.length ||
            (componentType === 'header' && isHeaderMediaFormat)
          "
          class="template__variables-container"
        >
          <p class="variables-label">
            {{ `${getHeaderMediaFormat}` }}
          </p>
          <!-- Add file upload option for header with specific formats -->
          <template v-if="componentType === 'header' && isHeaderMediaFormat">
            <file-upload
              :accept="acceptedFileTypes"
              :size="MAXIMUM_FILE_UPLOAD_SIZE * 1024 * 1024"
              @input-file="handleFileUpload"
            >
              <woot-button variant="smooth">
                {{ `Upload ${getHeaderMediaFormat}` }}
              </woot-button>
            </file-upload>
            <p v-if="uploadedFile">
              {{ uploadedFile.name }}
            </p>
          </template>
          <div
            v-for="variable in componentVariables"
            :key="`${componentType}-${variable}`"
            class="template__variable-item"
          >
            <span class="variable-label">
              {{ processVariable(variable) }}
            </span>
            <woot-input
              v-model="
                processedParams[componentType][processVariable(variable)]
              "
              type="text"
              class="variable-input"
              :styles="{ marginBottom: 0 }"
              required
            />
          </div>
        </div>
      </div>
      <p v-if="$v.$dirty && $v.$invalid" class="error">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.FORM_ERROR_MESSAGE') }}
      </p>
      <footer>
        <woot-button variant="smooth" @click="$emit('resetTemplate')">
          {{ $t('WHATSAPP_TEMPLATES.PARSER.GO_BACK_LABEL') }}
        </woot-button>
        <woot-button type="button" @click="sendMessage">
          {{ $t('WHATSAPP_TEMPLATES.PARSER.SEND_MESSAGE_LABEL') }}
        </woot-button>
      </footer>
    </div>
  </div>
</template>
<script>
import { requiredIf } from 'vuelidate/lib/validators';
import FileUpload from 'vue-upload-component';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { MAXIMUM_FILE_UPLOAD_SIZE } from 'shared/constants/messages';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import alertMixin from 'shared/mixins/alertMixin';
import { validateNonEmptyEntries } from '../../../../helper/commons';

export default {
  components: {
    FileUpload,
  },
  mixins: [alertMixin],
  props: {
    template: {
      type: Object,
      default: () => {},
    },
    removeOverflow: {
      type: Boolean,
      default: false,
    },
  },
  validations: {
    processedParams: {
      header: {
        $each: {
          $required: requiredIf(function (value, key) {
            return (
              this.variables.header &&
              this.variables.header.includes(`{{${key}}}`)
            );
          }),
        },
      },
      body: {
        $each: {
          $required: requiredIf(function (value, key) {
            return (
              this.variables.body && this.variables.body.includes(`{{${key}}}`)
            );
          }),
        },
      },
      footer: {
        $each: {
          $required: requiredIf(function (value, key) {
            return (
              this.variables.footer &&
              this.variables.footer.includes(`{{${key}}}`)
            );
          }),
        },
      },
    },
  },
  data() {
    return {
      processedParams: {
        header: {},
        body: {},
        footer: {},
      },
      uploadedFile: null,
    };
  },
  computed: {
    variables() {
      const allVariables = {};
      ['header', 'body', 'footer'].forEach(componentType => {
        const component = this.template.components.find(
          c => c.type === componentType.toUpperCase()
        );
        if (component) {
          allVariables[componentType] = this.extractVariables(component);
        }
      });
      return allVariables;
    },
    processedString() {
      const processed = {};
      ['header', 'body', 'footer'].forEach(componentType => {
        const component = this.template.components.find(
          c => c.type === componentType.toUpperCase()
        );
        if (component) {
          processed[componentType] = this.replaceVariables(
            component,
            componentType
          );
        }
      });
      return processed;
    },
    processedContentString() {
      let content = this.processedString.body;
      if (this.processedString.footer) {
        content += `\n\n${this.processedString.footer}`;
      }
      if (
        this.processedString.header &&
        !['IMAGE', 'VIDEO', 'DOCUMENT'].includes(
          this.template.components.find(c => c.type === 'HEADER').format
        )
      ) {
        content = `${this.processedString.header}\n\n${content}`;
      }
      return content;
    },
    getHeaderMediaFormat() {
      const headerComponent = this.template.components.find(
        c => c.type === 'HEADER'
      );
      return (
        headerComponent?.format
          ?.toLowerCase()
          .replace(/^./, c => c.toUpperCase()) || ''
      );
    },
    isHeaderMediaFormat() {
      const headerComponent = this.template.components.find(
        c => c.type === 'HEADER'
      );
      return (
        headerComponent &&
        ['IMAGE', 'VIDEO', 'DOCUMENT'].includes(headerComponent.format)
      );
    },
    acceptedFileTypes() {
      const headerComponent = this.template.components.find(
        c => c.type === 'HEADER'
      );
      switch (headerComponent?.format) {
        case 'IMAGE':
          return 'image/*';
        case 'VIDEO':
          return 'video/*';
        case 'DOCUMENT':
          return '.pdf,.doc,.docx,.xls,.xlsx';
        default:
          return '';
      }
    },
  },
  mounted() {
    this.generateVariables();
  },
  methods: {
    extractVariables(component) {
      if (!component || !component.text) return [];
      return component.text.match(/{{([^}]+)}}/g) || [];
    },
    replaceVariables(component, componentType) {
      if (!component || !component.text) return '';
      return component.text.replace(/{{([^}]+)}}/g, (match, variable) => {
        const variableKey = this.processVariable(variable);
        return (
          this.processedParams[componentType][variableKey] || `{{${variable}}}`
        );
      });
    },
    generateVariables() {
      ['header', 'body', 'footer'].forEach(componentType => {
        const component = this.template.components.find(
          c => c.type === componentType.toUpperCase()
        );
        if (component) {
          const variables = this.extractVariables(component);
          this.processedParams[componentType] = variables.reduce(
            (acc, variable) => {
              const key = this.processVariable(variable);
              acc[key] = '';
              return acc;
            },
            {}
          );
        }
      });
    },
    async handleFileUpload(file) {
      if (!file) return;

      if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
        try {
          const { fileUrl, blobId } = await uploadFile(file.file);
          this.uploadedFile = {
            file: file.file,
            name: file.name,
            url: fileUrl,
            blobId: blobId,
          };

          this.processedParams.header[this.processVariable('{{1}}')] = fileUrl;
        } catch (error) {
          // Handle error
          // console.error('Error uploading file:', error);
        }
      } else {
        // Show error message for file size limit
        this.$emit('show-alert', {
          message: this.$t('CONVERSATION.FILE_SIZE_LIMIT', {
            MAXIMUM_FILE_UPLOAD_SIZE,
          }),
        });
      }
    },
    sendMessage() {
      this.$v.$touch();
      if (this.$v.$invalid) return;

      // validate Header
      const headerValidation = validateNonEmptyEntries(
        'header',
        this.processedParams.header,
        this.isHeaderMediaFormat
      );

      if (headerValidation.isValid === false) {
        this.showAlert(headerValidation.message);
      }

      // validate Body
      const bodyValidation = validateNonEmptyEntries(
        'body',
        this.processedParams.body
      );
      if (bodyValidation.isValid === false) {
        this.showAlert(bodyValidation.message);
      }

      // validate Footer
      const footerValidation = validateNonEmptyEntries(
        'footer',
        this.processedParams.footer
      );
      if (footerValidation.isValid === false) {
        this.showAlert(footerValidation.message);
      }

      if (
        !footerValidation.isValid ||
        !bodyValidation.isValid ||
        !headerValidation.isValid
      ) {
        return;
      }

      const payload = {
        message: this.processedContentString,
        templateParams: {
          name: this.template.name,
          category: this.template.category,
          language: this.template.language,
          namespace: this.template.namespace,
          processed_params: this.processedParams,
        },
        private: false,
      };
      if (this.uploadedFile) {
        payload.files = [this.uploadedFile.file];
      }
      this.$emit('sendMessage', payload);
    },
    processVariable(str) {
      return str.replace(/{{|}}/g, '');
    },
  },
};
</script>

<style scoped lang="scss">
.template__variables-container {
  @apply p-2.5;
}

.variables-label {
  @apply text-sm font-semibold mb-2.5;
}

.template__variable-item {
  @apply items-center flex mb-2.5;

  .label {
    @apply text-xs;
  }

  .variable-input,
  input[type='file'] {
    @apply flex-1 text-sm ml-2.5;
  }

  .variable-label {
    @apply bg-slate-75 dark:bg-slate-700 text-slate-700 dark:text-slate-100 inline-block rounded-md text-xs py-2.5 px-6;
  }
}

footer {
  @apply flex justify-end;

  button {
    @apply ml-2.5;
  }
}
.error {
  @apply bg-red-100 dark:bg-red-100 rounded-md text-red-800 dark:text-red-800 p-2.5 text-center;
}
.template-input {
  @apply bg-slate-25 dark:bg-slate-900 text-slate-700 dark:text-slate-100 mt-2 min-h-[250px];
}
</style>
