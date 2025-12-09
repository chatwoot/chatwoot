<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { uploadFile } from 'dashboard/helper/uploadHelper';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'shared/components/Spinner.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  product: {
    type: Object,
    default: null,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'submit']);

const { t } = useI18n();
const { accountId } = useAccount();

const dialogRef = ref(null);
const fileInputRef = ref(null);

const form = ref({
  title_en: '',
  title_ar: '',
  description_en: '',
  description_ar: '',
  price: '',
  currency: 'SAR',
});

const imageFile = ref(null);
const imagePreviewUrl = ref('');
const existingImageUrl = ref('');
const isUploading = ref(false);
const uploadError = ref('');

const currencyOptions = [
  { label: 'SAR', value: 'SAR' },
  { label: 'USD', value: 'USD' },
  { label: 'EUR', value: 'EUR' },
  { label: 'GBP', value: 'GBP' },
  { label: 'AED', value: 'AED' },
];

const isEditMode = computed(() => !!props.product);

const dialogTitle = computed(() =>
  isEditMode.value
    ? t('CATALOG.DIALOG.EDIT.TITLE')
    : t('CATALOG.DIALOG.ADD.TITLE')
);

const confirmButtonLabel = computed(() =>
  isEditMode.value
    ? t('CATALOG.DIALOG.EDIT.CONFIRM')
    : t('CATALOG.DIALOG.ADD.CONFIRM')
);

const isFormValid = computed(() => {
  return (
    form.value.title_en.trim() !== '' &&
    form.value.price !== '' &&
    Number(form.value.price) > 0 &&
    form.value.currency !== '' &&
    !isUploading.value
  );
});

const displayImageUrl = computed(
  () => imagePreviewUrl.value || existingImageUrl.value
);

const hasImage = computed(() => !!displayImageUrl.value);

const resetForm = () => {
  form.value = {
    title_en: '',
    title_ar: '',
    description_en: '',
    description_ar: '',
    price: '',
    currency: 'SAR',
  };
  imageFile.value = null;
  imagePreviewUrl.value = '';
  existingImageUrl.value = '';
  isUploading.value = false;
  uploadError.value = '';
};

const populateForm = () => {
  if (props.product) {
    form.value = {
      title_en: props.product.title_en || '',
      title_ar: props.product.title_ar || '',
      description_en: props.product.description_en || '',
      description_ar: props.product.description_ar || '',
      price: props.product.price || '',
      currency: props.product.currency || 'SAR',
    };
    existingImageUrl.value = props.product.image_url || '';
    imageFile.value = null;
    imagePreviewUrl.value = '';
  } else {
    resetForm();
  }
};

const handleClose = () => {
  emit('close');
  resetForm();
};

const handleImageClick = () => {
  fileInputRef.value?.click();
};

const handleImageSelect = event => {
  const [file] = event.target.files;
  if (file) {
    imageFile.value = file;
    imagePreviewUrl.value = URL.createObjectURL(file);
    uploadError.value = '';
  }
};

const handleRemoveImage = () => {
  imageFile.value = null;
  imagePreviewUrl.value = '';
  existingImageUrl.value = '';
  if (fileInputRef.value) {
    fileInputRef.value.value = null;
  }
};

const handleSubmit = async () => {
  if (!isFormValid.value) return;

  let blobId = null;

  if (imageFile.value) {
    try {
      isUploading.value = true;
      uploadError.value = '';
      const result = await uploadFile(imageFile.value, accountId.value);
      blobId = result.blobId;
    } catch {
      uploadError.value = t('CATALOG.FORM.IMAGE.ERROR');
      isUploading.value = false;
      return;
    }
    isUploading.value = false;
  }

  emit('submit', {
    product: {
      title_en: form.value.title_en,
      title_ar: form.value.title_ar,
      description_en: form.value.description_en,
      description_ar: form.value.description_ar,
      price: Number(form.value.price),
      currency: form.value.currency,
    },
    blobId,
  });
};

watch(
  () => props.show,
  newVal => {
    if (newVal) {
      populateForm();
      dialogRef.value?.open();
    } else {
      dialogRef.value?.close();
    }
  }
);

watch(
  () => props.product,
  () => {
    if (props.show) {
      populateForm();
    }
  }
);
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="dialogTitle"
    :confirm-button-label="confirmButtonLabel"
    :disable-confirm-button="!isFormValid"
    :is-loading="isLoading"
    width="xl"
    overflow-y-auto
    @close="handleClose"
    @confirm="handleSubmit"
  >
    <div class="flex flex-col gap-4">
      <!-- Image Upload -->
      <div>
        <label class="block mb-1.5 text-sm font-medium text-n-slate-12">
          {{ t('CATALOG.FORM.IMAGE.LABEL') }}
        </label>
        <div class="relative inline-block group">
          <div
            class="relative flex items-center justify-center w-24 h-24 overflow-hidden border rounded-lg cursor-pointer bg-n-alpha-2 border-n-weak hover:border-n-brand"
            @click="handleImageClick"
          >
            <img
              v-if="hasImage"
              :src="displayImageUrl"
              :alt="form.title_en || t('CATALOG.FORM.IMAGE.LABEL')"
              class="object-cover w-full h-full"
            />
            <div
              v-else
              class="flex flex-col items-center justify-center gap-1 text-n-slate-10"
            >
              <Icon icon="i-lucide-image-plus" class="size-6" />
              <span class="text-xs">{{ t('CATALOG.FORM.IMAGE.UPLOAD') }}</span>
            </div>
            <div
              v-if="isUploading"
              class="absolute inset-0 flex items-center justify-center bg-n-alpha-black1"
            >
              <Spinner />
            </div>
          </div>
          <button
            v-if="hasImage && !isUploading"
            type="button"
            class="absolute z-10 flex items-center justify-center invisible w-6 h-6 transition-opacity bg-white rounded-full opacity-0 shadow -top-2 -right-2 group-hover:visible group-hover:opacity-100 hover:bg-n-slate-2"
            @click.stop="handleRemoveImage"
          >
            <Icon icon="i-lucide-x" class="text-n-slate-11 size-4" />
          </button>
          <input
            ref="fileInputRef"
            type="file"
            accept="image/png, image/jpeg, image/jpg, image/gif, image/webp"
            class="hidden"
            @change="handleImageSelect"
          />
        </div>
        <p v-if="uploadError" class="mt-1 text-xs text-n-ruby-9">
          {{ uploadError }}
        </p>
      </div>

      <!-- Title English -->
      <Input
        v-model="form.title_en"
        :label="t('CATALOG.FORM.TITLE_EN.LABEL')"
        :placeholder="t('CATALOG.FORM.TITLE_EN.PLACEHOLDER')"
      />

      <!-- Title Arabic -->
      <Input
        v-model="form.title_ar"
        :label="t('CATALOG.FORM.TITLE_AR.LABEL')"
        :placeholder="t('CATALOG.FORM.TITLE_AR.PLACEHOLDER')"
        dir="rtl"
      />

      <!-- Description English -->
      <TextArea
        v-model="form.description_en"
        :label="t('CATALOG.FORM.DESCRIPTION_EN.LABEL')"
        :placeholder="t('CATALOG.FORM.DESCRIPTION_EN.PLACEHOLDER')"
        rows="3"
      />

      <!-- Description Arabic -->
      <TextArea
        v-model="form.description_ar"
        :label="t('CATALOG.FORM.DESCRIPTION_AR.LABEL')"
        :placeholder="t('CATALOG.FORM.DESCRIPTION_AR.PLACEHOLDER')"
        rows="3"
        dir="rtl"
      />

      <!-- Price and Currency Row -->
      <div class="flex gap-4">
        <div class="flex-1">
          <Input
            v-model="form.price"
            type="number"
            :label="t('CATALOG.FORM.PRICE.LABEL')"
            :placeholder="t('CATALOG.FORM.PRICE.PLACEHOLDER')"
            min="0"
            step="0.01"
          />
        </div>
        <div class="w-32">
          <label class="block mb-1.5 text-sm font-medium text-n-slate-12">
            {{ t('CATALOG.FORM.CURRENCY.LABEL') }}
          </label>
          <select
            v-model="form.currency"
            class="block w-full h-10 px-3 pr-7 py-2 text-sm border-0 rounded-lg outline outline-1 outline-offset-[-1px] outline-n-weak bg-n-alpha-black2 text-n-slate-12 focus:outline-n-brand"
          >
            <option
              v-for="option in currencyOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </div>
      </div>
    </div>
  </Dialog>
</template>
