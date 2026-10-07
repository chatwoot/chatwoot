<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAlert } from 'dashboard/composables';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';

const props = defineProps({
  assistant: { type: Object, required: true },
});

const { t } = useI18n();
const store = useStore();
const { isAdmin } = useAdmin();
const avatar = ref(null);
const isSaving = ref(false);
const MAX_AVATAR_SIZE = 15; // MB, matching Avatarable

const uploadAvatar = async ({ file, url }) => {
  URL.revokeObjectURL(url);
  if (!checkFileSizeLimit(file, MAX_AVATAR_SIZE)) {
    useAlert(t('CAPTAIN.ASSISTANTS.FORM.AVATAR.INVALID_FILE'));
    return;
  }
  isSaving.value = true;
  try {
    await store.dispatch('captainAssistants/uploadAvatar', {
      id: props.assistant.id,
      file,
    });
    useAlert(t('CAPTAIN.ASSISTANTS.FORM.AVATAR.UPLOAD_SUCCESS'));
  } catch (error) {
    useAlert(
      error?.message || t('CAPTAIN.ASSISTANTS.FORM.AVATAR.UPLOAD_ERROR')
    );
  } finally {
    isSaving.value = false;
  }
};

const removeAvatar = async () => {
  isSaving.value = true;
  try {
    await store.dispatch('captainAssistants/deleteAvatar', props.assistant.id);
    useAlert(t('CAPTAIN.ASSISTANTS.FORM.AVATAR.REMOVE_SUCCESS'));
  } catch (error) {
    useAlert(
      error?.message || t('CAPTAIN.ASSISTANTS.FORM.AVATAR.REMOVE_ERROR')
    );
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col gap-3">
    <span class="text-sm font-medium text-n-slate-12">
      {{ t('CAPTAIN.ASSISTANTS.FORM.AVATAR.LABEL') }}
    </span>
    <div class="flex items-center gap-4">
      <Avatar
        ref="avatar"
        :src="assistant.avatar_url"
        :name="assistant.name || ''"
        :size="64"
        :allow-upload="isAdmin && !isSaving"
        rounded-full
        @upload="uploadAvatar"
        @delete="removeAvatar"
      />
      <div class="flex flex-col gap-2">
        <div v-if="isAdmin" class="flex flex-wrap gap-2">
          <Button
            :label="t('CAPTAIN.ASSISTANTS.FORM.AVATAR.UPLOAD')"
            icon="i-lucide-upload"
            color="slate"
            size="sm"
            :is-loading="isSaving"
            :disabled="isSaving"
            @click="avatar.openFilePicker()"
          />
          <Button
            v-if="assistant.avatar_attached"
            :label="t('CAPTAIN.ASSISTANTS.FORM.AVATAR.REMOVE')"
            color="slate"
            variant="ghost"
            size="sm"
            :disabled="isSaving"
            @click="removeAvatar"
          />
        </div>
        <p class="text-xs text-n-slate-11">
          {{ t('CAPTAIN.ASSISTANTS.FORM.AVATAR.FILE_HINT') }}
        </p>
      </div>
    </div>
    <p class="text-sm text-n-slate-11">
      {{ t('CAPTAIN.ASSISTANTS.FORM.AVATAR.HELP_TEXT') }}
    </p>
  </div>
</template>
