<template>
  <div>
    <label class="text-base font-medium text-black-800">
      {{ $t('SURVEY.FEEDBACK.LABEL') }}
    </label>
    <text-area
      v-model="feedback"
      class="my-5"
      :placeholder="$t('SURVEY.FEEDBACK.PLACEHOLDER')"
    />
    <custom-button
      class="flex items-center font-medium float-right"
      @click="onClick"
    >
      <spinner v-if="feedback" class="p-0" />
      {{ $t('SURVEY.FEEDBACK.BUTTON_TEXT') }}
    </custom-button>
  </div>
</template>

<script>
import CustomButton from 'shared/components/Button';
import TextArea from 'shared/components/TextArea.vue';
import Spinner from 'shared/components/Spinner';

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
      default: null,
    },
    isButtonDisabled: {
      type: Boolean,
      default: null,
    },
  },
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
