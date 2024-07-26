<script>
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import ResizableTextArea from 'shared/components/ResizableTextArea.vue';

export default {
  components: {
    WootMessageEditor,
    ResizableTextArea,
  },
  props: {
    value: {
      type: String,
      default: '',
    },
    richtext: {
      type: Boolean,
      default: false,
    },
    label: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      greetingsMessage: this.value,
    };
  },
  watch: {
    value(newValue) {
      this.greetingsMessage = newValue;
    },
  },
  methods: {
    handleInput() {
      this.$emit('input', this.greetingsMessage);
    },
  },
};
</script>

<template>
  <section class="w-3/4">
    <div
      v-if="richtext"
      class="px-4 py-0 mx-0 mt-0 mb-4 bg-white border border-solid rounded-md border-slate-200 dark:border-slate-600 dark:bg-slate-900"
    >
      <WootMessageEditor
        v-model="greetingsMessage"
        is-format-mode
        enable-variables
        class="bg-white input dark:bg-slate-900"
        :placeholder="placeholder"
        :min-height="4"
        @input="handleInput"
      />
    </div>
    <ResizableTextArea
      v-else
      v-model="greetingsMessage"
      :rows="4"
      type="text"
      class="greetings--textarea"
      :label="label"
      :placeholder="placeholder"
      @input="handleInput"
    />
  </section>
</template>
