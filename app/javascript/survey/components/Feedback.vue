<script>
import CustomButton from 'shared/components/Button.vue';
import TextArea from 'shared/components/TextArea.vue';
import Spinner from 'shared/components/Spinner.vue';

export default {
  name: 'Feedback',
  components: {
    CustomButton,
    TextArea,
    Spinner,
  },
  props: {
    isUpdating: {
      type: Boolean,
      default: false,
    },
    initialFeedback: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
    isButtonDisabled: {
      type: Boolean,
      default: false,
    },
    selectedRating: {
      type: Number,
      default: null,
    },
  },
  emits: ['sendFeedback', 'updateFeedback'],
  data() {
    return {
      feedback: this.initialFeedback,
    };
  },
  computed: {
    isSubmitDisabled() {
      return (
        this.isButtonDisabled || !this.selectedRating || !this.feedback.trim()
      );
    },
  },
  methods: {
    onClick() {
      if (this.isSubmitDisabled) return;
      this.$emit('sendFeedback', this.feedback);
    },
    onInput(value) {
      this.$emit('updateFeedback', value);
    },
  },
};
</script>

<template>
  <div class="mt-6">
    <label class="text-base font-medium text-n-slate-12">
      {{ $t('SURVEY.FEEDBACK.LABEL') }}
    </label>
    <TextArea
      v-model="feedback"
      class="my-5"
      :placeholder="placeholder || $t('SURVEY.FEEDBACK.PLACEHOLDER')"
      @update:model-value="onInput"
    />
    <div class="flex items-center float-right font-medium">
      <CustomButton :disabled="isUpdating" @click="onClick">
        <Spinner v-if="isUpdating" class="p-0" />
        {{ $t('SURVEY.FEEDBACK.BUTTON_TEXT') }}
      </CustomButton>
    </div>
  </div>
</template>
