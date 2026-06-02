<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { dynamicTime } from 'shared/helpers/timeHelper';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import { useCompaniesStore } from 'dashboard/stores/companies';

const props = defineProps({
  company: { type: Object, default: () => ({}) },
  isLoading: { type: Boolean, default: false },
});

const { t } = useI18n();
const companiesStore = useCompaniesStore();

const form = reactive({ name: '', domain: '', description: '' });
const avatarPreviewUrl = ref('');
const isUploadingAvatar = ref(false);

const uiFlags = computed(() => companiesStore.getUIFlags);
const isUpdating = computed(() => uiFlags.value.updatingItem);
const isAvatarBusy = computed(
  () =>
    isUploadingAvatar.value || uiFlags.value.deletingAvatar || isUpdating.value
);

const displayName = computed(
  () => props.company?.name || t('COMPANIES.UNNAMED')
);
const avatarSource = computed(
  () => avatarPreviewUrl.value || props.company?.avatarUrl || ''
);
const isFormInvalid = computed(() => !form.name.trim());
const hasChanges = computed(
  () =>
    form.name.trim() !== (props.company?.name || '').trim() ||
    form.domain.trim() !== (props.company?.domain || '').trim() ||
    form.description.trim() !== (props.company?.description || '').trim()
);

const summary = computed(() => {
  const { createdAt, lastActivityAt } = props.company || {};
  return [
    createdAt &&
      t('COMPANIES.DETAIL.PROFILE.CREATED_AT', {
        date: dynamicTime(createdAt),
      }),
    lastActivityAt &&
      t('COMPANIES.DETAIL.PROFILE.LAST_ACTIVE', {
        date: dynamicTime(lastActivityAt),
      }),
  ]
    .filter(Boolean)
    .join(' • ');
});

const syncForm = company => {
  form.name = company?.name || '';
  form.domain = company?.domain || '';
  form.description = company?.description || '';
};

const isCurrentCompany = companyId => Number(props.company?.id) === companyId;

watch(
  () => [
    props.company?.id,
    props.company?.name,
    props.company?.domain,
    props.company?.description,
    props.company?.avatarUrl,
  ],
  () => {
    avatarPreviewUrl.value = '';
    syncForm(props.company);
  },
  { immediate: true }
);

const handleAvatarUpload = async ({ file, url }) => {
  avatarPreviewUrl.value = url;
  isUploadingAvatar.value = true;
  try {
    await companiesStore.update({ id: props.company.id, avatar: file });
    useAlert(t('COMPANIES.DETAIL.AVATAR.UPLOAD_SUCCESS'));
  } catch {
    avatarPreviewUrl.value = '';
    useAlert(t('COMPANIES.DETAIL.AVATAR.UPLOAD_ERROR'));
  } finally {
    isUploadingAvatar.value = false;
  }
};

const handleAvatarDelete = async () => {
  try {
    await companiesStore.deleteCompanyAvatar(props.company.id);
    avatarPreviewUrl.value = '';
    useAlert(t('COMPANIES.DETAIL.AVATAR.DELETE_SUCCESS'));
  } catch {
    useAlert(t('COMPANIES.DETAIL.AVATAR.DELETE_ERROR'));
  }
};

const handleUpdateCompany = async () => {
  const companyId = Number(props.company.id);

  try {
    const updated = await companiesStore.update({
      id: companyId,
      name: form.name.trim(),
      domain: form.domain.trim() || null,
      description: form.description.trim() || null,
    });
    if (!isCurrentCompany(companyId)) return;

    syncForm(updated);
    useAlert(t('COMPANIES.DETAIL.PROFILE.MESSAGES.UPDATE_SUCCESS'));
  } catch {
    if (!isCurrentCompany(companyId)) return;

    syncForm(props.company);
    useAlert(t('COMPANIES.DETAIL.PROFILE.MESSAGES.UPDATE_ERROR'));
  }
};
</script>

<template>
  <div v-if="isLoading && !company?.id" class="text-sm text-n-slate-11">
    {{ t('COMPANIES.DETAIL.LOADING') }}
  </div>

  <div v-else-if="company?.id" class="flex flex-col items-start gap-8 pb-6">
    <div class="flex flex-col items-start gap-3">
      <Avatar
        :name="displayName"
        :src="avatarSource"
        :size="72"
        :allow-upload="!isAvatarBusy"
        rounded-full
        hide-offline-status
        @upload="handleAvatarUpload"
        @delete="handleAvatarDelete"
      />

      <div class="flex flex-col gap-1">
        <h3 class="text-base font-medium text-n-slate-12">
          {{ displayName }}
        </h3>
        <span class="text-sm leading-6 text-n-slate-11">{{ summary }}</span>
        <p
          v-if="isUploadingAvatar || uiFlags.deletingAvatar"
          class="text-sm text-n-slate-11"
        >
          {{ t('COMPANIES.DETAIL.AVATAR.UPDATING') }}
        </p>
      </div>
    </div>

    <div class="flex flex-col items-start w-full gap-6">
      <span class="py-1 text-sm font-medium text-n-slate-12">
        {{ t('COMPANIES.DETAIL.PROFILE.TITLE') }}
      </span>

      <div class="grid w-full gap-4 sm:grid-cols-2">
        <Input
          v-model="form.name"
          :placeholder="t('COMPANIES.DETAIL.PROFILE.FIELDS.NAME')"
          :disabled="isUpdating"
          custom-input-class="h-8 !pt-1 !pb-1"
        />
        <Input
          v-model="form.domain"
          :placeholder="t('COMPANIES.DETAIL.PROFILE.FIELDS.DOMAIN')"
          :disabled="isUpdating"
          custom-input-class="h-8 !pt-1 !pb-1"
        />
      </div>

      <TextArea
        v-model="form.description"
        :placeholder="t('COMPANIES.DETAIL.PROFILE.DESCRIPTION_PLACEHOLDER')"
        :disabled="isUpdating"
        :max-length="280"
        class="w-full"
        show-character-count
        auto-height
      />

      <Button
        :label="t('COMPANIES.DETAIL.PROFILE.ACTIONS.SAVE')"
        size="sm"
        :is-loading="isUpdating"
        :disabled="isUpdating || isFormInvalid || !hasChanges"
        @click="handleUpdateCompany"
      />
    </div>
  </div>
</template>
