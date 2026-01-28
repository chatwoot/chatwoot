<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import CsatReviewNotesPaywall from './CsatReviewNotesPaywall.vue';
import { dynamicTime } from 'shared/helpers/timeHelper';

const props = defineProps({
  response: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const { isCloudFeatureEnabled, isOnChatwootCloud } = useAccount();
const { formatMessage } = useMessageFormatter();

const isFeatureEnabled = computed(() =>
  isCloudFeatureEnabled('csat_review_notes')
);
const showPaywall = computed(
  () => !isFeatureEnabled.value && isOnChatwootCloud.value
);

const reviewNotes = ref(props.response.csat_review_notes || '');
const isEditing = ref(!props.response.csat_review_notes);
const isSaving = ref(false);

const hasExistingReviewNotes = computed(
  () => !!props.response.csat_review_notes
);

const hasChanges = computed(
  () => reviewNotes.value !== (props.response.csat_review_notes || '')
);

const startEditing = () => {
  isEditing.value = true;
};

const cancelEditing = () => {
  reviewNotes.value = props.response.csat_review_notes || '';
  if (hasExistingReviewNotes.value) {
    isEditing.value = false;
  }
};

const saveReviewNotes = async () => {
  isSaving.value = true;
  try {
    await store.dispatch('csat/update', {
      id: props.response.id,
      reviewNotes: reviewNotes.value,
    });
    useAlert(t('CSAT_REPORTS.REVIEW_NOTES.SAVED'));
    isEditing.value = false;
  } catch {
    useAlert(t('CSAT_REPORTS.REVIEW_NOTES.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <div class="py-4 px-5 border-t border-n-container bg-n-background">
    <CsatReviewNotesPaywall v-if="showPaywall" />
    <div v-else-if="isFeatureEnabled" class="flex flex-col gap-3">
      <div class="flex items-start gap-4">
        <div
          class="flex items-center gap-1.5 text-n-slate-11 shrink-0 w-36 pt-3"
        >
          <i class="i-lucide-notebook-pen size-4" />
          <span class="text-sm font-medium">
            {{ $t('CSAT_REPORTS.REVIEW_NOTES.TITLE') }}
          </span>
        </div>

        <div class="flex-1 max-w-2xl">
          <div
            v-if="hasExistingReviewNotes && !isEditing"
            class="group flex items-start gap-2 py-2 px-3 rounded-lg hover:bg-n-slate-2 dark:hover:bg-n-solid-3 cursor-pointer transition-colors"
            @click.stop="startEditing"
          >
            <p
              v-dompurify-html="formatMessage(response.csat_review_notes || '')"
              class="flex-1 text-sm text-n-slate-12 prose-sm prose-p:text-sm prose-p:leading-relaxed prose-p:mb-1 prose-p:mt-0"
            />
            <i
              class="i-lucide-pencil size-4 text-n-slate-10 opacity-0 group-hover:opacity-100 transition-opacity shrink-0 mt-0.5"
            />
          </div>

          <div
            v-else
            class="flex flex-col gap-3 [&_.ProseMirror]:min-h-32 [&_.ProseMirror]:max-h-64 [&_.ProseMirror-menubar]:!mt-0"
            @click.stop
          >
            <Editor
              v-model="reviewNotes"
              :placeholder="$t('CSAT_REPORTS.REVIEW_NOTES.PLACEHOLDER')"
              :show-character-count="false"
              :enable-canned-responses="false"
              focus-on-mount
            >
              <template #actions>
                <div class="flex items-center gap-2 py-2">
                  <Button
                    v-if="hasExistingReviewNotes"
                    variant="ghost"
                    size="xs"
                    :label="$t('CSAT_REPORTS.REVIEW_NOTES.CANCEL')"
                    @click.stop="cancelEditing"
                  />
                  <Button
                    :label="$t('CSAT_REPORTS.REVIEW_NOTES.SAVE')"
                    :disabled="!hasChanges || isSaving"
                    :loading="isSaving"
                    size="xs"
                    @click.stop="saveReviewNotes"
                  />
                </div>
              </template>
            </Editor>
          </div>
        </div>
      </div>

      <div
        v-if="
          hasExistingReviewNotes &&
          !isEditing &&
          response.review_notes_updated_by
        "
        class="flex items-center gap-4"
      >
        <div class="flex items-center gap-1.5 text-n-slate-11 shrink-0 w-36">
          <i class="i-lucide-user-pen size-4" />
          <span class="text-sm font-medium">
            {{ $t('CSAT_REPORTS.REVIEW_NOTES.UPDATED_BY_LABEL') }}
          </span>
        </div>
        <div class="flex items-center gap-1 flex-1 max-w-2xl px-3">
          <span class="text-sm text-n-slate-12">
            {{ response.review_notes_updated_by.name }}
          </span>
          <span class="text-n-slate-10">·</span>
          <span class="text-sm text-n-slate-10">
            {{ dynamicTime(response.review_notes_updated_at) }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
