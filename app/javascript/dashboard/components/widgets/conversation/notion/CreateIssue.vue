<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import NotionAPI from 'dashboard/api/integrations/notion';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  title: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['close']);
const { t } = useI18n();

const isCreating = ref(false);
const isTitleTouched = ref(false);

const formState = reactive({
  title: props.title,
  description: '',
  assigneeId: '',
  projectId: '',
  stateId: '',
  priority: '',
  labelIds: '',
});

const titleError = computed(() => {
  if (!isTitleTouched.value || formState.title.trim()) return '';

  return t('INTEGRATION_SETTINGS.NOTION.CREATE.FORM.TITLE.REQUIRED_ERROR');
});

const isSubmitDisabled = computed(
  () => !formState.title.trim() || isCreating.value
);

const compactLabels = labels => {
  return labels
    .split(',')
    .map(label => label.trim())
    .filter(Boolean);
};

const errorMessage = (error, fallback) => {
  const parsedError = parseAPIErrorResponse(error);
  return typeof parsedError === 'string' ? parsedError : fallback;
};

const buildPayload = () => {
  const payload = {
    conversation_id: props.conversationId,
    title: formState.title.trim(),
  };

  if (formState.description.trim()) {
    payload.description = formState.description.trim();
  }
  if (formState.assigneeId.trim()) {
    payload.assignee_id = formState.assigneeId.trim();
  }
  if (formState.projectId.trim()) {
    payload.project_id = formState.projectId.trim();
  }
  if (formState.stateId.trim()) {
    payload.state_id = formState.stateId.trim();
  }
  if (formState.priority.trim()) {
    payload.priority = formState.priority.trim();
  }
  if (formState.labelIds.trim()) {
    payload.label_ids = compactLabels(formState.labelIds);
  }

  return payload;
};

const createIssue = async () => {
  isTitleTouched.value = true;
  if (isSubmitDisabled.value) return;

  try {
    isCreating.value = true;
    await NotionAPI.createIssue(buildPayload());
    useAlert(t('INTEGRATION_SETTINGS.NOTION.CREATE.SUCCESS'));
    emit('close');
  } catch (error) {
    useAlert(
      errorMessage(error, t('INTEGRATION_SETTINGS.NOTION.CREATE.ERROR'))
    );
  } finally {
    isCreating.value = false;
  }
};
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="createIssue">
    <woot-input
      v-model="formState.title"
      :class="{ error: titleError }"
      class="w-full"
      :label="$t('INTEGRATION_SETTINGS.NOTION.CREATE.FORM.TITLE.LABEL')"
      :placeholder="
        $t('INTEGRATION_SETTINGS.NOTION.CREATE.FORM.TITLE.PLACEHOLDER')
      "
      :error="titleError"
      @blur="isTitleTouched = true"
      @input="isTitleTouched = true"
    />

    <label class="flex flex-col gap-1 text-sm font-medium text-n-slate-12">
      {{ $t('INTEGRATION_SETTINGS.NOTION.CREATE.FORM.DESCRIPTION.LABEL') }}
      <textarea
        v-model="formState.description"
        rows="3"
        class="w-full px-3 py-2 text-sm border rounded-lg resize-none border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:ring-1 focus:ring-n-brand"
        :placeholder="
          $t('INTEGRATION_SETTINGS.NOTION.CREATE.FORM.DESCRIPTION.PLACEHOLDER')
        "
      />
    </label>

    <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
      <woot-input
        v-model="formState.assigneeId"
        :label="$t('INTEGRATION_SETTINGS.NOTION.CREATE.FORM.ASSIGNEE.LABEL')"
        :placeholder="
          $t('INTEGRATION_SETTINGS.NOTION.CREATE.FORM.ASSIGNEE.PLACEHOLDER')
        "
      />
      <woot-input
        v-model="formState.projectId"
        :label="$t('INTEGRATION_SETTINGS.NOTION.CREATE.FORM.PROJECT.LABEL')"
        :placeholder="
          $t('INTEGRATION_SETTINGS.NOTION.CREATE.FORM.PROJECT.PLACEHOLDER')
        "
      />
      <woot-input
        v-model="formState.stateId"
        :label="$t('INTEGRATION_SETTINGS.NOTION.CREATE.FORM.STATUS.LABEL')"
        :placeholder="
          $t('INTEGRATION_SETTINGS.NOTION.CREATE.FORM.STATUS.PLACEHOLDER')
        "
      />
      <woot-input
        v-model="formState.priority"
        :label="$t('INTEGRATION_SETTINGS.NOTION.CREATE.FORM.PRIORITY.LABEL')"
        :placeholder="
          $t('INTEGRATION_SETTINGS.NOTION.CREATE.FORM.PRIORITY.PLACEHOLDER')
        "
      />
    </div>

    <woot-input
      v-model="formState.labelIds"
      :label="$t('INTEGRATION_SETTINGS.NOTION.CREATE.FORM.LABELS.LABEL')"
      :placeholder="
        $t('INTEGRATION_SETTINGS.NOTION.CREATE.FORM.LABELS.PLACEHOLDER')
      "
    />

    <div class="flex items-center justify-end w-full gap-2 mt-4">
      <Button
        faded
        slate
        type="reset"
        :label="$t('INTEGRATION_SETTINGS.NOTION.CREATE.CANCEL')"
        @click.prevent="emit('close')"
      />
      <Button
        type="submit"
        :label="$t('INTEGRATION_SETTINGS.NOTION.CREATE.SUBMIT')"
        :disabled="isSubmitDisabled"
        :is-loading="isCreating"
      />
    </div>
  </form>
</template>
