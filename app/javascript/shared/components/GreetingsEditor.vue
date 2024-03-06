<template>
  <section class="w-3/4">
    <div
      v-if="richtext"
      class="py-0 px-4 rounded-md border border-solid border-slate-200 dark:border-slate-600 bg-white dark:bg-slate-900 mt-0 mx-0 mb-4"
    >
      <woot-message-editor
        v-model="greetingsMessage"
        :is-format-mode="true"
        :enable-variables="true"
        class="input bg-white dark:bg-slate-900"
        :placeholder="placeholder"
        :min-height="4"
        @input="handleInput"
      />
    </div>
    <resizable-text-area
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
