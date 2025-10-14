<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Modal from 'dashboard/components/Modal.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversationId: {
    type: Number,
    required: true,
  },
  agentName: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const store = useStore();

const isOpen = ref(true);
const selectedRating = ref(null);
const comment = ref('');
const isSubmitting = ref(false);

const ratings = computed(() => [
  { value: 1, emoji: '😞', label: t('QUALITY_RATING.RATINGS.POOR') },
  { value: 2, emoji: '😐', label: t('QUALITY_RATING.RATINGS.FAIR') },
  { value: 3, emoji: '🙂', label: t('QUALITY_RATING.RATINGS.GOOD') },
  { value: 4, emoji: '😊', label: t('QUALITY_RATING.RATINGS.VERY_GOOD') },
  { value: 5, emoji: '😍', label: t('QUALITY_RATING.RATINGS.EXCELLENT') },
]);

const canSubmit = computed(() => selectedRating.value !== null);

const selectRating = rating => {
  selectedRating.value = rating;
};

const closeModal = () => {
  isOpen.value = false;
  emit('close');
};

const submitRating = async () => {
  if (!canSubmit.value) return;

  isSubmitting.value = true;

  try {
    // Save rating to conversation metadata
    await store.dispatch('conversationMetadata/update', {
      conversationId: props.conversationId,
      data: {
        quality_rating: selectedRating.value,
        quality_comment: comment.value,
        rated_at: new Date().toISOString(),
      },
    });

    useAlert(t('QUALITY_RATING.SUCCESS_MESSAGE'));
    closeModal();
  } catch (error) {
    useAlert(t('QUALITY_RATING.ERROR_MESSAGE'));
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <Modal v-model:show="isOpen" :on-close="closeModal" @close="closeModal">
    <div class="flex flex-col">
      <!-- Header -->
      <div class="p-4 border-b border-n-slate-5">
        <h1 class="text-n-slate-12 text-lg font-semibold">
          {{ $t('QUALITY_RATING.TITLE') }}
        </h1>
      </div>

      <!-- Body -->
      <div class="flex flex-col gap-4 p-4">
        <p v-if="agentName" class="text-n-slate-11">
          {{ $t('QUALITY_RATING.QUESTION_WITH_AGENT', { agentName }) }}
        </p>
        <p v-else class="text-n-slate-11">
          {{ $t('QUALITY_RATING.QUESTION_GENERAL') }}
        </p>

        <!-- Rating selector -->
        <div class="flex justify-center gap-2 my-4">
          <button
            v-for="rating in ratings"
            :key="rating.value"
            class="flex flex-col items-center gap-1 p-3 rounded-lg transition-all cursor-pointer hover:bg-n-slate-3"
            :class="{
              'bg-n-blue-2 border-2 border-n-blue-9':
                selectedRating === rating.value,
              'bg-n-slate-2': selectedRating !== rating.value,
            }"
            @click="selectRating(rating.value)"
          >
            <span class="text-3xl">{{ rating.emoji }}</span>
            <span class="text-xs text-n-slate-11">{{ rating.label }}</span>
          </button>
        </div>

        <!-- Comment field -->
        <div class="flex flex-col gap-2">
          <label class="text-sm font-medium text-n-slate-11">
            {{ $t('QUALITY_RATING.COMMENT_LABEL') }}
          </label>
          <textarea
            v-model="comment"
            class="w-full p-2 border border-n-slate-5 rounded-lg resize-none focus:outline-none focus:ring-2 focus:ring-n-blue-9"
            rows="3"
            :placeholder="$t('QUALITY_RATING.COMMENT_PLACEHOLDER')"
          />
        </div>
      </div>

      <!-- Footer -->
      <div class="flex justify-end gap-2 p-4 border-t border-n-slate-5">
        <Button
          :label="$t('QUALITY_RATING.SKIP_BUTTON')"
          size="sm"
          color="slate"
          @click="closeModal"
        />
        <Button
          :label="$t('QUALITY_RATING.SUBMIT_BUTTON')"
          size="sm"
          color="blue"
          :disabled="!canSubmit"
          :is-loading="isSubmitting"
          @click="submitRating"
        />
      </div>
    </div>
  </Modal>
</template>
