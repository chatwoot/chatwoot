/* eslint-disable no-plusplus */
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
            (componentType === 'header' && isHeaderMediaFormat) ||
            (componentType === 'buttons' && hasButtons)
          "
          class="template__variables-container"
        >
          <p
            v-if="!(componentType === 'buttons' && hasButtons)"
            class="variables-label"
          >
            {{
              componentType === 'buttons'
                ? 'Buttons'
                : `${getHeaderMediaFormat}`
            }}
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
          <!-- Render buttons if they exist -->
          <template v-if="componentType === 'buttons' && hasButtons">
            <div
              v-for="(button, index) in getButtons"
              :key="index"
              class="template__button-item"
            >
              <div class="url-button-container">
                <span class="button-type-label">
                  {{ button.type }} Button: {{ button.text }}
                </span>
                <div
                  v-if="
                    button.type === 'URL' &&
                    processedParams &&
                    processedParams[componentType] &&
                    Object.entries(processedParams[componentType]).length > 0
                  "
                  class="flex w-full flex-col"
                >
                  <input
                    v-model="processedParams[componentType][index]"
                    type="text"
                    class="variable-input !mb-0 !h-8 !w-2/3"
                    :class="{
                      'error-input':
                        !isValidUrl(processedParams[componentType][index]) &&
                        processedParams[componentType][index],
                    }"
                    :styles="{
                      marginBottom: 0,
                      width: '50%',
                    }"
                    placeholder="Enter URL"
                    required
                    @blur="validateUrl(componentType, index)"
                  />
                  <p
                    v-if="
                      !isValidUrl(processedParams[componentType][index]) &&
                      processedParams[componentType][index]
                    "
                    class="url-error-message !mb-0"
                  >
                    Please enter a valid URL (e.g., https://example.com)
                  </p>
                </div>
                <div
                  v-if="button.type === 'PHONE_NUMBER'"
                  class="flex items-center w-full"
                >
                  <input
                    v-model="button.phone_number"
                    type="text"
                    class="variable-input !mb-0 !h-8 !w-2/3"
                    :styles="{
                      marginBottom: 0,
                      width: '50%',
                    }"
                    :disabled="true"
                  />
                </div>
                <div
                  v-if="button.type === 'QUICK_REPLY'"
                  class="flex items-center w-full"
                >
                  <input
                    v-model="button.text"
                    type="text"
                    class="variable-input !mb-0 !h-8 !w-2/3"
                    :styles="{
                      marginBottom: 0,
                      width: '50%',
                    }"
                    :disabled="true"
                  />
                </div>
                <div
                  v-if="button.type === 'COPY_CODE'"
                  class="flex items-center w-full"
                >
                  <input
                    v-model="button.example"
                    type="text"
                    class="variable-input !mb-0 !h-8 !w-2/3"
                    :styles="{
                      marginBottom: 0,
                      width: '50%',
                    }"
                    :disabled="true"
                  />
                </div>
              </div>
            </div>
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
              v-if="!isInputMode(variable) || isComposeMode"
              v-model="
                processedParams[componentType][processVariable(variable)]
              "
              :autofocus="true"
              type="text"
              class="variable-input"
              :styles="{ marginBottom: 0, width: '94%' }"
              required
            />
            <select
              v-else
              v-model="
                processedParams[componentType][processVariable(variable)]
              "
              class="variable-input"
              :style="{
                marginBottom: 0,
                width: '70% !important',
                marginRight: '16px',
              }"
              required
            >
              <option value="" disabled>Select an option</option>
              <option
                v-for="option in dropdownOptions"
                :key="option.value"
                :value="option.value"
              >
                {{ option.label }}
              </option>
            </select>
            <woot-button
              v-if="!isComposeMode"
              :style="{ width: 'fit-content' }"
              type="button"
              @click="toggleInputMode(variable)"
            >
              {{ !isInputMode(variable) ? 'Use Variable' : 'Use Input' }}
            </woot-button>
          </div>
        </div>
      </div>
      <p v-if="$v.$dirty && $v.$invalid" class="error">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.FORM_ERROR_MESSAGE') }}
      </p>
      <footer>
        <woot-button
          :disabled="isLoading"
          variant="smooth"
          @click="$emit('resetTemplate')"
        >
          {{ $t('WHATSAPP_TEMPLATES.PARSER.GO_BACK_LABEL') }}
        </woot-button>
        <woot-button :disabled="isLoading" type="button" @click="sendMessage">
          {{
            isLoading
              ? 'Sending...'
              : $t('WHATSAPP_TEMPLATES.PARSER.SEND_MESSAGE_LABEL')
          }}
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
import { mapGetters } from 'vuex';
import message from '../../../../../widget/api/message';

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
    isComposeMode: {
      type: Boolean,
      default: false,
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
        buttons: {},
      },
      uploadedFile: null,
      inputModes: {},
      isLoading: false,
      urlErrors: {},
    };
  },
  computed: {
    ...mapGetters({
      currentAccountId: 'getCurrentAccountId',
      currentChat: 'getSelectedChat',
      currentUser: 'getCurrentUser',
    }),
    variables() {
      const allVariables = {};
      ['header', 'body', 'footer', 'buttons'].forEach(componentType => {
        const component = this.template.components.find(
          c => c.type === componentType.toUpperCase()
        );
        if (component) {
          allVariables[componentType] = this.extractVariables(component);
        }
      });
      return allVariables;
    },
    dropdownOptions() {
      return [
        {
          label: 'Last Order Number',
          value: 'contact.shopping.orderName',
        },
        {
          label: 'Last Order ID',
          value: 'contact.shopping.id',
        },
        {
          label: 'Tracking Number',
          value: 'contact.shopping.trackingNumber',
        },
        {
          label: 'Last Order Tracking Link',
          value: 'contact.shopping.trackingLink',
        },
        {
          label: 'Last Order Status URL',
          value: 'contact.shopping.orderStatusUrl',
        },
        {
          label: 'Last Order Destination Country',
          value: 'contact.shopping.destinationCountry',
        },
        {
          label: 'Shipping Address',
          value: 'contact.shopping.shippingAddress',
        },
      ];
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
    hasButtons() {
      const buttonsComponent = this.template.components.find(
        c => c.type === 'BUTTONS'
      );
      return (
        buttonsComponent &&
        buttonsComponent.buttons &&
        buttonsComponent.buttons.length > 0
      );
    },
    getButtons() {
      const buttonsComponent = this.template.components.find(
        c => c.type === 'BUTTONS'
      );
      return buttonsComponent ? buttonsComponent.buttons || [] : [];
    },
  },
  mounted() {
    this.generateVariables();
  },
  methods: {
    extractVariables(component) {
      if (component.type === 'URL') {
        if (!component || !component.url) return [];
        return component.url.match(/{{([^}]+)}}/g) || [];
      }
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
      ['header', 'body', 'footer', 'buttons'].forEach(componentType => {
        const component = this.template.components.find(
          c => c.type === componentType.toUpperCase()
        );
        if (component) {
          if (componentType === 'buttons' && component?.buttons) {
            const variables = [];
            component.buttons.forEach((button, index) => {
              if (button.type === 'URL' && button.url) {
                const variable = this.extractVariables(button);
                if (variable) {
                  variables.push(index);
                }
              }
            });
            this.processedParams[componentType] = variables.reduce(
              (acc, variable) => {
                acc[variable] = '';
                return acc;
              },
              {}
            );
          } else {
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
    async sendMessage() {
      this.isLoading = true;
      this.$v.$touch();
      if (this.$v.$invalid) {
        this.isLoading = false;
        return;
      }

      // Check for URL errors
      let hasUrlErrors = false;
      if (this.processedParams.buttons) {
        Object.keys(this.processedParams.buttons).forEach(index => {
          const url = this.processedParams.buttons[index];
          if (url && !this.isValidUrl(url)) {
            hasUrlErrors = true;
          }
        });
      }

      if (hasUrlErrors) {
        this.showAlert('Please fix the invalid URLs before sending');
        this.isLoading = false;
        return;
      }

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

      // validate Footer
      const buttonValidations = validateNonEmptyEntries(
        'buttons',
        this.processedParams.buttons
      );
      if (buttonValidations.isValid === false) {
        this.showAlert(buttonValidations.message);
      }

      if (
        !footerValidation.isValid ||
        !bodyValidation.isValid ||
        !headerValidation.isValid ||
        !buttonValidations.isValid
      ) {
        this.isLoading = false;
        return;
      }

      let textToUse = this.processedContentString;

      if (!this.isComposeMode) {
        const text = this.processedContentString;

        // Extract items starting with 'contact.' until a comma or line break
        const matches = text.match(/contact\.[\w.]+/g);
        const contactItems = matches || []; // Store in an array

        const payloadForVariables = {
          accountId: this.currentAccountId,
          phoneNumber: this.currentChat.meta?.sender?.phone_number?.replace(
            /^\+/,
            ''
          ),
          templateFallbacks: contactItems.reduce((acc, item, index) => {
            acc[`${index + 1}`] = 'N/A';
            return acc;
          }, {}),
          templateMetaData: contactItems.reduce((acc, item, index) => {
            acc[`${index + 1}`] = {
              variableMapping: item.replace(/\.$/, ''),
            };
            return acc;
          }, {}),
        };

        const response = await message.personaliseMessageVariables(
          payloadForVariables,
          this.currentUser.access_token
        );
        const personalisedVariables = Object.values(
          response?.data?.personalisedVariables
        );

        // Replace variables in processedParams
        Object.keys(this.processedParams).forEach(section => {
          Object.keys(this.processedParams[section]).forEach(key => {
            const value = this.processedParams[section][key];
            if (value.startsWith('contact.shopping.')) {
              const index = contactItems.findIndex(
                item => item.replace(/\.$/, '') === value.replace(/\.$/, '')
              );
              if (index !== -1) {
                this.processedParams[section][key] =
                  personalisedVariables[index] || value;
              }
            }
          });
        });

        textToUse = this.processedContentString;
        personalisedVariables.forEach((variable, index) => {
          const pattern = contactItems[index];
          if (pattern) {
            // Use regex to replace the exact match of the contact.shopping.* pattern
            const regex = new RegExp(pattern.replace('.', '\\.'), 'g');
            textToUse = textToUse.replace(regex, variable);
          }
        });
      }

      const payload = {
        message: textToUse,
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
      this.isLoading = false;
    },
    processVariable(str) {
      return str.replace(/{{|}}/g, '');
    },
    toggleInputMode(variable) {
      this.$set(this.inputModes, variable, !this.inputModes[variable]);
      // Find the component type (header, body, or footer) that contains this variable
      const componentType = Object.keys(this.variables).find(type =>
        this.variables[type].includes(variable)
      );
      if (componentType) {
        this.processedParams[componentType][this.processVariable(variable)] =
          '';
      }
    },
    isInputMode(variable) {
      return this.inputModes[variable] || false;
    },
    isValidUrl(url) {
      if (!url) return true; // Empty is handled by required validation
      const pattern = new RegExp(
        '^(https?:\\/\\/)?' + // protocol
          '((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|' + // domain name
          '((\\d{1,3}\\.){3}\\d{1,3}))' + // OR ip (v4) address
          '(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*' + // port and path
          '(\\?[;&a-z\\d%_.~+=-]*)?' + // query string
          '(\\#[-a-z\\d_]*)?$',
        'i'
      );
      return pattern.test(url);
    },
    validateUrl(componentType, index) {
      const url = this.processedParams[componentType][index];
      if (url && !this.isValidUrl(url)) {
        this.$set(this.urlErrors, `${componentType}_${index}`, true);
      } else {
        this.$set(this.urlErrors, `${componentType}_${index}`, false);
      }
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
  @apply bg-slate-25 dark:bg-slate-900 text-slate-700 dark:text-slate-100 mt-2;
}
.template__buttons-container {
  @apply p-2.5;
}
.template__button-item {
  @apply mb-2.5;
}
.button-type-label {
  @apply font-semibold text-sm mb-2;
}

.url-button-container {
  @apply flex flex-col mb-3;
}

.button-url-prefix {
  @apply text-slate-600 dark:text-slate-300 mr-1 text-sm;
}

.error-input {
  @apply border-red-500 dark:border-red-500 border-2;
}

.url-error-message {
  @apply text-red-600 dark:text-red-400 text-xs mt-1 ml-2;
}
</style>
