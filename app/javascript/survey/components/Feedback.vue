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
  },
  emits: ['sendFeedback'],
  data() {
    return {
      feedback: '',
    };
  },
  methods: {
    onClick() {
      this.$emit('sendFeedback', this.feedback);
    },
  },
};
</script>

<template>
  <div class="mt-6">
    <label class="text-base font-medium text-black-800">
      {{ $t('SURVEY.FEEDBACK.LABEL') }}
    </label>
    <TextArea
      v-model="feedback"
      class="my-5"
      :placeholder="$t('SURVEY.FEEDBACK.PLACEHOLDER')"
    />
    <div class="flex items-center float-right font-medium">
      <CustomButton @click="onClick">
        <Spinner v-if="isUpdating" class="p-0" />
        {{ $t('SURVEY.FEEDBACK.BUTTON_TEXT') }}
      </CustomButton>
    </div>
  </div>
</template>
