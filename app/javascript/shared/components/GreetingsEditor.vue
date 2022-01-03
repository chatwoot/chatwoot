<template>
  <section>
    <label v-if="richtext" class="greetings--richtext">
      <woot-message-editor
        v-model="greetingsMessage"
        :is-format-mode="true"
        class="input"
        :placeholder="placeholder"
        :min-height="4"
        @input="handleInput"
      />
    </label>
    <resizable-text-area
      v-else
      v-model="greetingsMessage"
      rows="4"
      type="text"
      class="medium-9 greetings--textarea"
      :label="label"
      :placeholder="placeholder"
      @input="handleInput"
    />
  </section>
</template>

<script>
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor';
import ResizableTextArea from 'shared/components/ResizableTextArea';

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

<style scoped>
.greetings--richtext {
  padding: 0 var(--space-normal);
  border-radius: var(--border-radius-normal);
  border: 1px solid var(--color-border);
  margin: 0 0 var(--space-normal);
}
</style>
