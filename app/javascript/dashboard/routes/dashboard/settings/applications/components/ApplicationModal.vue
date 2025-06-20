<script setup>
import { ref, computed, reactive, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { required, helpers, url } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  type: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
  selectedApplication: {
    type: Object,
    default: () => ({}),
  },
});

const MODAL_TYPES = {
  CREATE: 'create',
  EDIT: 'edit',
};

const store = useStore();
const { t } = useI18n();
const dialogRef = ref(null);
const uiFlags = useMapGetter('applications/getUIFlags');

const formState = reactive({
  name: '',
  description: '',
  appUrl: '',
  avatar: null,
  avatarUrl: '',
  active: true,
});

const v$ = useVuelidate(
  {
    name: {
      required: helpers.withMessage(
        () => t('APPLICATIONS.FORM.ERRORS.NAME'),
        required
      ),
    },
    appUrl: {
      required: helpers.withMessage(
        () => t('APPLICATIONS.FORM.ERRORS.URL'),
        required
      ),
      url: helpers.withMessage(
        () => t('APPLICATIONS.FORM.ERRORS.VALID_URL'),
        url
      ),
    },
  },
  formState
);

const isLoading = computed(() =>
  props.type === MODAL_TYPES.CREATE
    ? uiFlags.value.isCreating
    : uiFlags.value.isUpdating
);

const dialogTitle = computed(() =>
  props.type === MODAL_TYPES.CREATE
    ? t('APPLICATIONS.ADD.TITLE')
    : t('APPLICATIONS.EDIT.TITLE')
);

const confirmButtonLabel = computed(() =>
  props.type === MODAL_TYPES.CREATE
    ? t('APPLICATIONS.FORM.CREATE')
    : t('APPLICATIONS.FORM.UPDATE')
);

const nameError = computed(() =>
  v$.value.name.$error ? v$.value.name.$errors[0]?.$message : ''
);

const urlError = computed(() =>
  v$.value.appUrl.$error ? v$.value.appUrl.$errors[0]?.$message : ''
);

const resetForm = () => {
  Object.assign(formState, {
    name: '',
    description: '',
    appUrl: '',
    avatar: null,
    avatarUrl: '',
    active: true,
  });
  v$.value.$reset();
};

const handleImageUpload = ({ file, uploadedUrl }) => {
  formState.avatar = file;
  formState.avatarUrl = uploadedUrl;
};

const handleAvatarDelete = async () => {
  if (props.selectedApplication?.id) {
    try {
      await store.dispatch(
        'applications/deleteApplicationAvatar',
        props.selectedApplication.id
      );
      formState.avatar = null;
      formState.avatarUrl = '';
      useAlert(t('APPLICATIONS.AVATAR.SUCCESS_DELETE'));
    } catch (error) {
      useAlert(t('APPLICATIONS.AVATAR.ERROR_DELETE'));
    }
  } else {
    formState.avatar = null;
    formState.avatarUrl = '';
  }
};

const handleSubmit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  const applicationData = {
    name: formState.name,
    description: formState.description,
    url: formState.appUrl,
    status: formState.active ? 'active' : 'inactive',
    avatar: formState.avatar,
  };

  const isCreate = props.type === MODAL_TYPES.CREATE;

  try {
    const actionPayload = isCreate
      ? applicationData
      : { id: props.selectedApplication.id, data: applicationData };

    await store.dispatch(
      `applications/${isCreate ? 'create' : 'update'}`,
      actionPayload
    );

    const alertKey = isCreate
      ? t('APPLICATIONS.ADD.API.SUCCESS_MESSAGE')
      : t('APPLICATIONS.EDIT.API.SUCCESS_MESSAGE');
    useAlert(alertKey);

    dialogRef.value.close();
    resetForm();
  } catch (error) {
    const errorKey = isCreate
      ? t('APPLICATIONS.ADD.API.ERROR_MESSAGE')
      : t('APPLICATIONS.EDIT.API.ERROR_MESSAGE');
    useAlert(errorKey);
  }
};

const initializeForm = () => {
  if (
    props.selectedApplication &&
    Object.keys(props.selectedApplication).length
  ) {
    const {
      name,
      description,
      url: applicationUrl,
      thumbnail,
      status,
    } = props.selectedApplication;

    formState.name = name || '';
    formState.description = description || '';
    formState.appUrl = applicationUrl || '';
    formState.avatarUrl = thumbnail || '';
    formState.active = status === 'active';
  } else {
    resetForm();
  }
};

const closeModal = () => {
  v$.value?.$reset();
};

const onClickClose = () => {
  closeModal();
  dialogRef.value.close();
};

watch(() => props.selectedApplication, initializeForm, {
  immediate: true,
  deep: true,
});

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="dialogTitle"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="closeModal"
  >
    <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
      <div class="flex flex-col gap-4">
        <div class="mb-2 flex flex-col items-start">
          <span class="mb-2 text-sm font-medium text-n-slate-12">
            {{ $t('APPLICATIONS.FORM.AVATAR.LABEL') }}
          </span>
          <Avatar
            :src="formState.avatarUrl"
            :name="formState.name"
            :size="68"
            allow-upload
            icon-name="i-lucide-app-window"
            @upload="handleImageUpload"
            @delete="handleAvatarDelete"
          />
        </div>

        <Input
          id="application-name"
          v-model="formState.name"
          :label="$t('APPLICATIONS.FORM.NAME.LABEL')"
          :placeholder="$t('APPLICATIONS.FORM.NAME.PLACEHOLDER')"
          :message="nameError"
          :message-type="nameError ? 'error' : 'info'"
          @blur="v$.name.$touch()"
        />

        <TextArea
          id="application-description"
          v-model="formState.description"
          :label="$t('APPLICATIONS.FORM.DESCRIPTION.LABEL')"
          :placeholder="$t('APPLICATIONS.FORM.DESCRIPTION.PLACEHOLDER')"
        />

        <Input
          id="application-url"
          v-model="formState.appUrl"
          :label="$t('APPLICATIONS.FORM.URL.LABEL')"
          :placeholder="$t('APPLICATIONS.FORM.URL.PLACEHOLDER')"
          :message="urlError"
          :message-type="urlError ? 'error' : 'info'"
          @blur="v$.appUrl.$touch()"
        />

        <div class="flex items-center">
          <input
            id="application-active"
            v-model="formState.active"
            type="checkbox"
            class="rounded border-slate-300 text-woot-600 shadow-sm focus:border-woot-300 focus:ring focus:ring-woot-200 focus:ring-opacity-50"
          />
          <label for="application-active" class="ml-2 text-sm text-slate-700">
            {{ $t('APPLICATIONS.FORM.ACTIVE.LABEL') }}
          </label>
        </div>
      </div>

      <div class="flex items-center justify-end w-full gap-2 px-0 py-2">
        <NextButton
          faded
          slate
          type="reset"
          :label="$t('APPLICATIONS.FORM.CANCEL')"
          @click="onClickClose()"
        />
        <NextButton
          type="submit"
          data-testid="application-submit"
          :label="confirmButtonLabel"
          :is-loading="isLoading"
          :disabled="v$.$invalid"
        />
      </div>
    </form>
  </Dialog>
</template>
