<script>
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import { DirectUpload } from 'activestorage';
import {
  checkFileSizeLimit,
  resolveMaximumFileUploadSize,
} from 'shared/helpers/FileHelper';
import Spinner from 'shared/components/Spinner.vue';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

export default {
  components: { Spinner, FluentIcon },
  props: {
    buttonLabel: {
      type: String,
      default: '',
    },
    items: {
      type: Array,
      default: () => [],
    },
    submittedValues: {
      type: Array,
      default: () => [],
    },
  },
  emits: ['submit'],
  data() {
    return {
      formValues: {},
      hasSubmitted: false,
      imageUploads: {},
    };
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
      globalConfig: 'globalConfig/get',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    fileUploadSizeLimit() {
      return resolveMaximumFileUploadSize(
        this.globalConfig.maximumFileUploadSize
      );
    },
    directUploadsEnabled() {
      return !!this.globalConfig.directUploadsEnabled;
    },
    isAnyImageUploading() {
      return Object.values(this.imageUploads).some(
        u => u.status === 'uploading'
      );
    },
    isFormValid() {
      return this.items.reduce((acc, { name, type }) => {
        if (type === 'image') {
          const upload = this.imageUploads[name];
          return acc && !!this.formValues[name] && upload?.status === 'done';
        }
        return !!this.formValues[name] && acc;
      }, true);
    },
  },
  mounted() {
    if (this.submittedValues.length) {
      this.updateFormValues();
    } else {
      this.setFormDefaults();
    }
  },
  methods: {
    onSubmitClick() {
      this.hasSubmitted = true;
    },
    onSubmit() {
      if (!this.isFormValid || this.isAnyImageUploading) {
        return;
      }
      this.$emit('submit', this.formValues);
    },
    buildFormObject(formObjectArray) {
      return formObjectArray.reduce((acc, obj) => {
        return {
          ...acc,
          [obj.name]: obj.value || obj.default,
        };
      }, {});
    },
    updateFormValues() {
      this.formValues = this.buildFormObject(this.submittedValues);
    },
    setFormDefaults() {
      this.formValues = this.buildFormObject(this.items);
      this.items.forEach(item => {
        if (item.type === 'image') {
          this.imageUploads[item.name] = { status: 'idle', previewUrl: '' };
          this.formValues[item.name] = '';
        }
      });
    },
    triggerImageInput(item) {
      this.$refs[`imageInput_${item.name}`].click();
    },
    onImageFileChange(event, item) {
      const file = event.target.files[0];
      if (!file) return;

      if (!file.type.startsWith('image/')) {
        this.imageUploads[item.name] = {
          status: 'error',
          previewUrl: '',
          errorMessage: this.$t('CHAT_FORM.INVALID.IMAGE_TYPE'),
        };
        return;
      }

      if (!checkFileSizeLimit(file, this.fileUploadSizeLimit)) {
        this.imageUploads[item.name] = {
          status: 'error',
          previewUrl: '',
          errorMessage: this.$t('FILE_SIZE_LIMIT', {
            MAXIMUM_FILE_UPLOAD_SIZE: this.fileUploadSizeLimit,
          }),
        };
        return;
      }

      const previewUrl = URL.createObjectURL(file);
      this.imageUploads[item.name] = {
        status: 'uploading',
        previewUrl,
      };

      this.uploadImage(file, item);
    },
    uploadImage(file, item) {
      const { websiteToken } = window.chatwootWebChannel;
      const upload = new DirectUpload(
        file,
        `/api/v1/widget/direct_uploads?website_token=${websiteToken}`,
        {
          directUploadWillCreateBlobWithXHR: xhr => {
            xhr.setRequestHeader('X-Auth-Token', window.authToken);
          },
        }
      );

      upload.create((error, blob) => {
        if (error) {
          this.imageUploads[item.name] = {
            ...this.imageUploads[item.name],
            status: 'error',
            errorMessage: this.$t('CHAT_FORM.INVALID.UPLOAD_FAILED'),
          };
          return;
        }
        this.formValues[item.name] = blob.signed_id;
        this.imageUploads[item.name] = {
          ...this.imageUploads[item.name],
          status: 'done',
        };
      });
    },
    removeImage(item) {
      if (this.imageUploads[item.name]?.previewUrl) {
        URL.revokeObjectURL(this.imageUploads[item.name].previewUrl);
      }
      this.imageUploads[item.name] = { status: 'idle', previewUrl: '' };
      this.formValues[item.name] = '';
      const input = this.$refs[`imageInput_${item.name}`];
      if (input) input.value = '';
    },
  },
};
</script>

<template>
  <div
    class="form chat-bubble agent w-full p-4 bg-n-background dark:bg-n-solid-3"
  >
    <form @submit.prevent="onSubmit">
      <div
        v-for="item in items"
        :key="item.key"
        class="pb-2 w-full"
        :class="{
          'has-submitted': hasSubmitted,
        }"
      >
        <label class="text-n-slate-12">
          {{ item.label }}
        </label>
        <input
          v-if="item.type === 'email'"
          v-model="formValues[item.name]"
          :type="item.type"
          :pattern="item.regex"
          :title="item.title"
          :required="item.required && 'required'"
          :name="item.name"
          :placeholder="item.placeholder"
          :disabled="!!submittedValues.length"
        />
        <input
          v-else-if="item.type === 'text'"
          v-model="formValues[item.name]"
          :required="item.required && 'required'"
          :pattern="item.pattern"
          :title="item.title"
          :type="item.type"
          :name="item.name"
          :placeholder="item.placeholder"
          :disabled="!!submittedValues.length"
        />
        <textarea
          v-else-if="item.type === 'text_area'"
          v-model="formValues[item.name]"
          :required="item.required && 'required'"
          :title="item.title"
          :name="item.name"
          :placeholder="item.placeholder"
          :disabled="!!submittedValues.length"
        />
        <select
          v-else-if="item.type === 'select'"
          v-model="formValues[item.name]"
          :required="item.required && 'required'"
        >
          <option
            v-for="option in item.options"
            :key="option.key"
            :value="option.value"
          >
            {{ option.label }}
          </option>
        </select>
        <div v-else-if="item.type === 'image'" class="mt-1">
          <input
            :ref="`imageInput_${item.name}`"
            type="file"
            accept="image/*"
            class="hidden"
            @change="onImageFileChange($event, item)"
          />
          <div
            v-if="imageUploads[item.name]?.previewUrl"
            class="relative inline-block"
          >
            <img
              :src="imageUploads[item.name].previewUrl"
              alt=""
              class="max-w-[200px] max-h-[200px] rounded-lg object-cover"
            />
            <button
              v-if="imageUploads[item.name]?.status !== 'uploading'"
              type="button"
              class="absolute top-1 ltr:right-1 rtl:left-1 flex items-center justify-center w-6 h-6 rounded-full bg-n-solid-3 text-n-slate-12 hover:bg-n-solid-4"
              @click="removeImage(item)"
            >
              <FluentIcon icon="dismiss" size="12" />
            </button>
            <div
              v-if="imageUploads[item.name]?.status === 'uploading'"
              class="absolute inset-0 flex items-center justify-center rounded-lg bg-n-alpha-black2"
            >
              <Spinner />
            </div>
          </div>
          <button
            v-else
            type="button"
            class="flex items-center gap-2 px-3 py-2 text-sm rounded-lg border border-dashed border-n-slate-7 text-n-slate-11 hover:border-n-slate-9 hover:text-n-slate-12 dark:bg-n-alpha-black1"
            :disabled="!directUploadsEnabled"
            @click="triggerImageInput(item)"
          >
            <FluentIcon icon="image" size="16" />
            {{ $t('CHAT_FORM.UPLOAD_IMAGE') }}
          </button>
          <span
            v-if="imageUploads[item.name]?.errorMessage"
            class="text-n-ruby-9 text-xs mt-1 block"
          >
            {{ imageUploads[item.name].errorMessage }}
          </span>
          <span
            v-else-if="
              hasSubmitted &&
              item.required &&
              !formValues[item.name]
            "
            class="text-n-ruby-9 text-xs mt-1 block"
          >
            {{ $t('CHAT_FORM.INVALID.IMAGE_REQUIRED') }}
          </span>
        </div>
        <span v-if="item.type !== 'image'" class="error-message">
          {{ item.pattern_error || $t('CHAT_FORM.INVALID.FIELD') }}
        </span>
      </div>
      <button
        v-if="!submittedValues.length"
        class="button block"
        type="submit"
        :disabled="isAnyImageUploading"
        :style="{
          background: widgetColor,
          borderColor: widgetColor,
          color: textColor,
          opacity: isAnyImageUploading ? 0.6 : 1,
        }"
        @click="onSubmitClick"
      >
        {{ buttonLabel || $t('COMPONENTS.FORM_BUBBLE.SUBMIT') }}
      </button>
    </form>
  </div>
</template>

<style scoped lang="scss">
.form {
  label {
    @apply block font-medium py-1 px-0 capitalize;
  }

  .button {
    @apply text-sm rounded-lg;
  }

  .error-message {
    @apply text-n-ruby-9 mt-1 hidden;
  }

  input,
  textarea,
  select {
    @apply dark:bg-n-alpha-black1;
  }

  .has-submitted {
    input:invalid,
    textarea:invalid {
      @apply outline-n-ruby-8 dark:outline-n-ruby-8 hover:outline-n-ruby-9 dark:hover:outline-n-ruby-9;
    }
    input:invalid + .error-message,
    textarea:invalid + .error-message {
      display: block;
    }
  }
}
</style>
