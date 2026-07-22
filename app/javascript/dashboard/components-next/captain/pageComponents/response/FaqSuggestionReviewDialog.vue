<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { dynamicTime } from 'shared/helpers/timeHelper';

import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const props = defineProps({
  suggestion: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['close', 'resolved']);
const { t } = useI18n();
const router = useRouter();
const store = useStore();
const dialogRef = ref(null);
const details = ref(null);
const detailsError = ref(false);

const uiFlags = useMapGetter('captainFaqSuggestions/getUIFlags');
const isFetching = computed(() => uiFlags.value.fetchingItem);
const isSaving = computed(() => uiFlags.value.updatingItem);
const isDismissing = computed(() => uiFlags.value.deletingItem);

const state = reactive({
  question: props.suggestion.question,
  answer: props.suggestion.answer,
});

const observations = computed(() => details.value?.observations || []);
const isInvalid = computed(
  () => !state.question.trim() || !state.answer.trim()
);

const loadDetails = async () => {
  detailsError.value = false;

  try {
    details.value = await store.dispatch(
      'captainFaqSuggestions/show',
      props.suggestion.id
    );
  } catch (error) {
    detailsError.value = true;
    useAlert(
      error?.message || t('CAPTAIN.FAQ_SUGGESTIONS.ERRORS.LOAD_DETAILS')
    );
  }
};

const close = () => dialogRef.value.close();

const handleSave = async () => {
  try {
    const updatedSuggestion = await store.dispatch(
      'captainFaqSuggestions/update',
      {
        id: props.suggestion.id,
        question: state.question.trim(),
        answer: state.answer.trim(),
      }
    );
    details.value = { ...details.value, ...updatedSuggestion };
    useAlert(t('CAPTAIN.FAQ_SUGGESTIONS.SUCCESS.SAVED'));
  } catch (error) {
    useAlert(error?.message || t('CAPTAIN.FAQ_SUGGESTIONS.ERRORS.SAVE'));
  }
};

const handleApprove = async () => {
  try {
    await store.dispatch('captainFaqSuggestions/approve', {
      id: props.suggestion.id,
      question: state.question.trim(),
      answer: state.answer.trim(),
    });
    useAlert(t('CAPTAIN.FAQ_SUGGESTIONS.SUCCESS.APPROVED'));
    emit('resolved', { id: props.suggestion.id, action: 'approved' });
    close();
  } catch (error) {
    useAlert(error?.message || t('CAPTAIN.FAQ_SUGGESTIONS.ERRORS.APPROVE'));
  }
};

const handleDismiss = async () => {
  try {
    await store.dispatch('captainFaqSuggestions/dismiss', props.suggestion.id);
    useAlert(t('CAPTAIN.FAQ_SUGGESTIONS.SUCCESS.DISMISSED'));
    emit('resolved', { id: props.suggestion.id, action: 'dismissed' });
    close();
  } catch (error) {
    useAlert(error?.message || t('CAPTAIN.FAQ_SUGGESTIONS.ERRORS.DISMISS'));
  }
};

const openConversation = conversationId => {
  close();
  router.push({
    name: 'inbox_conversation',
    params: { conversation_id: conversationId },
  });
};

onMounted(loadDetails);

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="3xl"
    position="top"
    overflow-y-auto
    :title="$t('CAPTAIN.FAQ_SUGGESTIONS.DETAILS.TITLE')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="emit('close')"
  >
    <template #description>
      <p class="mb-0 text-sm text-n-slate-11">
        {{
          $t('CAPTAIN.FAQ_SUGGESTIONS.DETAILS.DESCRIPTION', {
            count: suggestion.source_count,
          })
        }}
      </p>
    </template>

    <div
      class="grid min-h-0 grid-cols-1 gap-6 lg:grid-cols-[minmax(0,1fr)_18rem]"
    >
      <div class="flex min-w-0 flex-col gap-4">
        <Input
          v-model="state.question"
          :label="$t('CAPTAIN.RESPONSES.FORM.QUESTION.LABEL')"
          :placeholder="$t('CAPTAIN.RESPONSES.FORM.QUESTION.PLACEHOLDER')"
        />
        <TextArea
          v-model="state.answer"
          :label="$t('CAPTAIN.RESPONSES.FORM.ANSWER.LABEL')"
          :placeholder="$t('CAPTAIN.RESPONSES.FORM.ANSWER.PLACEHOLDER')"
          auto-height
          resize
          min-height="10rem"
          max-height="20rem"
        />
        <div class="flex flex-wrap items-center gap-2 text-xs text-n-slate-10">
          <span
            class="inline-flex items-center gap-1.5 rounded-full bg-n-alpha-2 px-2.5 py-1"
          >
            <Icon icon="i-lucide-languages" class="size-3.5" />
            {{ suggestion.language?.replace('_', '-').toUpperCase() }}
          </span>
          <span
            class="inline-flex items-center gap-1.5 rounded-full bg-n-alpha-2 px-2.5 py-1"
          >
            <Icon icon="i-woot-captain" class="size-3.5" />
            {{ suggestion.assistant?.name }}
          </span>
        </div>
      </div>

      <section class="min-h-0 rounded-xl border border-n-weak bg-n-alpha-2 p-3">
        <div class="mb-3 flex items-center justify-between gap-2 px-1">
          <h4 class="text-sm font-medium text-n-slate-12">
            {{ $t('CAPTAIN.FAQ_SUGGESTIONS.DETAILS.SOURCES') }}
          </h4>
          <span class="text-xs tabular-nums text-n-slate-10">
            {{
              $t('CAPTAIN.FAQ_SUGGESTIONS.DETAILS.SOURCE_PROGRESS', {
                visible: observations.length,
                total: suggestion.source_count,
              })
            }}
          </span>
        </div>

        <div v-if="isFetching" class="flex h-40 items-center justify-center">
          <Spinner />
        </div>
        <div
          v-else-if="detailsError"
          role="alert"
          class="flex h-40 flex-col items-center justify-center gap-3 px-4 text-center"
        >
          <Icon icon="i-lucide-circle-alert" class="size-5 text-n-ruby-10" />
          <p class="mb-0 text-sm text-n-slate-11">
            {{ $t('CAPTAIN.FAQ_SUGGESTIONS.ERRORS.LOAD_DETAILS') }}
          </p>
          <Button
            :label="$t('CAPTAIN.FAQ_SUGGESTIONS.DETAILS.RETRY')"
            variant="faded"
            color="slate"
            size="sm"
            @click="loadDetails"
          />
        </div>
        <div
          v-else-if="!observations.length"
          class="flex h-40 items-center justify-center px-4 text-center text-sm text-n-slate-10"
        >
          {{ $t('CAPTAIN.FAQ_SUGGESTIONS.DETAILS.NO_SOURCES') }}
        </div>
        <div v-else class="flex max-h-[24rem] flex-col gap-2 overflow-y-auto">
          <button
            v-for="observation in observations"
            :key="observation.id"
            type="button"
            class="flex w-full flex-col gap-1.5 rounded-lg border border-n-weak bg-n-solid-2 p-3 text-start transition-colors hover:border-n-brand"
            @click="openConversation(observation.conversation.display_id)"
          >
            <span class="flex items-center justify-between gap-2">
              <span class="text-xs font-medium text-n-blue-11">
                {{
                  $t('CAPTAIN.RESPONSES.DOCUMENTABLE.CONVERSATION', {
                    id: observation.conversation.display_id,
                  })
                }}
              </span>
              <Icon
                icon="i-lucide-arrow-up-right"
                class="size-3.5 text-n-slate-10"
              />
            </span>
            <span class="line-clamp-2 text-xs leading-5 text-n-slate-11">
              {{ observation.generated_question }}
            </span>
            <span class="text-xs text-n-slate-10">
              {{ dynamicTime(observation.created_at) }}
            </span>
          </button>
        </div>
      </section>
    </div>

    <template #footer>
      <div
        class="flex w-full flex-col-reverse gap-3 sm:flex-row sm:items-center sm:justify-between"
      >
        <Button
          :label="$t('CAPTAIN.FAQ_SUGGESTIONS.DISMISS')"
          icon="i-lucide-x"
          variant="ghost"
          color="ruby"
          :is-loading="isDismissing"
          :disabled="isSaving || isDismissing"
          @click="handleDismiss"
        />
        <div class="flex items-center justify-end gap-2">
          <Button
            :label="$t('DIALOG.BUTTONS.CANCEL')"
            variant="faded"
            color="slate"
            :disabled="isSaving || isDismissing"
            @click="close"
          />
          <Button
            :label="$t('CAPTAIN.FAQ_SUGGESTIONS.SAVE')"
            variant="faded"
            color="slate"
            :is-loading="isSaving"
            :disabled="isInvalid || isSaving || isDismissing"
            @click="handleSave"
          />
          <Button
            :label="$t('CAPTAIN.FAQ_SUGGESTIONS.APPROVE_FAQ')"
            icon="i-lucide-circle-check-big"
            :is-loading="isSaving"
            :disabled="isInvalid || isSaving || isDismissing"
            @click="handleApprove"
          />
        </div>
      </div>
    </template>
  </Dialog>
</template>
