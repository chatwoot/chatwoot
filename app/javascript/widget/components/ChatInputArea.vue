<template>
  <resizable-textarea>
    <textarea
      class="form-input user-message-input"
      :placeholder="placeholder"
      :value="value"
      @input="$emit('input', $event.target.value)"
      @focus="onFocus"
      @blur="onBlur"
    />
  </resizable-textarea>
</template>

<script>
import ResizableTextarea from 'widget/components/ResizableTextarea.vue';

export default {
  components: {
    ResizableTextarea,
  },
  props: {
    placeholder: {
      type: String,
      default: '',
    },
    value: {
      type: String,
      default: '',
    },
  },
  methods: {
    onBlur() {
      this.toggleTyping('off');
    },
    onFocus() {
      this.toggleTyping('on');
    },
    toggleTyping(typingStatus) {
      this.$store.dispatch('conversation/toggleUserTyping', { typingStatus });
    },
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.user-message-input {
  border: 0;
  height: $space-large;
  resize: none;
  padding-top: $space-small;
}
</style>
