<script setup>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';

import { defineComponent, reactive, computed, onMounted } from 'vue';
import { useI18n } from 'dashboard/composables/useI18n';
import { useAlert } from 'dashboard/composables';

import { convertToCategorySlug } from 'dashboard/helper/commons.js';
import { buildPortalURL } from 'dashboard/helper/portalHelper';
import wootConstants from 'dashboard/constants/globals';
import { hasValidAvatarUrl } from 'dashboard/helper/URLHelper';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import { isDomain } from 'shared/helpers/Validators';
import SettingsLayout from './Layout/SettingsLayout.vue';

const { EXAMPLE_URL } = wootConstants;
const MAXIMUM_FILE_UPLOAD_SIZE = 4; // in MB

const { t } = useI18n();

defineComponent({
  name: 'PortalSettingsBasicForm',
});

const props = defineProps({
  portal: {
    type: Object,
    default: () => {},
  },
  isSubmitting: {
    type: Boolean,
    default: false,
  },
  submitButtonText: {
    type: String,
    default: '',
  },
});

const state = reactive({
  name: '',
  slug: '',
  domain: '',
  logoUrl: '',
  avatarBlobId: '',
});

const rules = {
  name: {
    required,
    minLength: minLength(2),
  },
  slug: {
    required,
  },
  domain: {
    isDomain,
  },
};

const v$ = useVuelidate(rules, state);

const nameError = computed(() => {
  if (v$.value.name.$error) {
    return t('HELP_CENTER.CATEGORY.ADD.NAME.ERROR');
  }
  return '';
});

const slugError = computed(() => {
  if (v$.value.slug.$error) {
    return t('HELP_CENTER.CATEGORY.ADD.SLUG.ERROR');
  }
  return '';
});

const domainError = computed(() => {
  if (v$.value.domain.$error) {
    return t('HELP_CENTER.PORTAL.ADD.DOMAIN.ERROR');
  }
  return '';
});

const domainHelpText = computed(() => {
  return buildPortalURL(state.slug);
});

const domainExampleHelpText = computed(() => {
  return t('HELP_CENTER.PORTAL.ADD.DOMAIN.HELP_TEXT', {
    exampleURL: EXAMPLE_URL,
  });
});

const showDeleteButton = computed(() => {
  return hasValidAvatarUrl(state.logoUrl);
});

const emit = defineEmits(['submit', 'delete-logo']);

onMounted(() => {
  const portal = props.portal || {};
  state.name = portal.name || '';
  state.slug = portal.slug || '';
  state.domain = portal.custom_domain || '';

  if (portal.logo) {
    const {
      logo: { file_url: logoURL, blob_id: blobId },
    } = portal;
    state.logoUrl = logoURL;
    state.avatarBlobId = blobId;
  }
});

function onNameChange() {
  state.slug = convertToCategorySlug(state.name);
}

function onSubmitClick() {
  v$.value.$touch();
  if (v$.value.$invalid) {
    return;
  }

  const portal = {
    name: state.name,
    slug: state.slug,
    custom_domain: state.domain,
    blob_id: state.avatarBlobId || null,
  };
  emit('submit', portal);
}
async function deleteAvatar() {
  state.logoUrl = '';
  state.avatarBlobId = '';
  emit('delete-logo');
}

async function uploadLogoToStorage(file) {
  try {
    const { fileUrl, blobId } = await uploadFile(file);
    if (fileUrl) {
      state.logoUrl = fileUrl;
      state.avatarBlobId = blobId;
    }
  } catch (error) {
    useAlert(t('HELP_CENTER.PORTAL.ADD.LOGO.IMAGE_UPLOAD_ERROR'));
  }
}

function onFileChange({ file }) {
  if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
    uploadLogoToStorage(file);
  } else {
    const errorKey =
      'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.IMAGE_UPLOAD_SIZE_ERROR';
    useAlert(t(errorKey, { size: MAXIMUM_FILE_UPLOAD_SIZE }));
  }
}
</script>

<template>
  <SettingsLayout
    :title="
      $t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.BASIC_SETTINGS_PAGE.TITLE')
    "
  >
    <div>
      <div class="mb-4">
        <div class="flex flex-row items-center">
          <woot-avatar-uploader
            :label="$t('HELP_CENTER.PORTAL.ADD.LOGO.LABEL')"
            :src="state.logoUrl"
            @change="onFileChange"
          />
          <div v-if="showDeleteButton" class="avatar-delete-btn">
            <woot-button
              type="button"
              color-scheme="alert"
              variant="hollow"
              size="small"
              @click="deleteAvatar"
            >
              {{ $t('PROFILE_SETTINGS.DELETE_AVATAR') }}
            </woot-button>
          </div>
        </div>
        <p
          class="mt-1 mb-0 text-xs not-italic text-slate-600 dark:text-slate-400"
        >
          {{ $t('HELP_CENTER.PORTAL.ADD.LOGO.HELP_TEXT') }}
        </p>
      </div>
      <div class="mb-4">
        <woot-input
          v-model="state.name"
          :class="{ error: v$.name.$error }"
          :error="nameError"
          :label="$t('HELP_CENTER.PORTAL.ADD.NAME.LABEL')"
          :placeholder="$t('HELP_CENTER.PORTAL.ADD.NAME.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.PORTAL.ADD.NAME.HELP_TEXT')"
          @blur="v$.name.$touch"
          @input="onNameChange"
        />
      </div>
      <div class="mb-4">
        <woot-input
          v-model="state.slug"
          :class="{ error: v$.slug.$error }"
          :error="slugError"
          :label="$t('HELP_CENTER.PORTAL.ADD.SLUG.LABEL')"
          :placeholder="$t('HELP_CENTER.PORTAL.ADD.SLUG.PLACEHOLDER')"
          :help-text="domainHelpText"
          @blur="v$.slug.$touch"
        />
      </div>
      <div class="mb-4">
        <woot-input
          v-model="state.domain"
          :class="{ error: v$.domain.$error }"
          :label="$t('HELP_CENTER.PORTAL.ADD.DOMAIN.LABEL')"
          :placeholder="$t('HELP_CENTER.PORTAL.ADD.DOMAIN.PLACEHOLDER')"
          :help-text="domainExampleHelpText"
          :error="domainError"
          @blur="v$.domain.$touch"
        />
      </div>
    </div>
    <template #footer-right>
      <woot-button
        :is-loading="isSubmitting"
        :is-disabled="v$.$invalid"
        @click="onSubmitClick"
      >
        {{ submitButtonText }}
      </woot-button>
    </template>
  </SettingsLayout>
</template>
