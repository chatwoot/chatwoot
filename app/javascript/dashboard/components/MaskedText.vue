<template>
  <div class="text--container">
    <button class="button small button--text" @click="onCopy">
      {{ $t('COMPONENTS.CODE.BUTTON_TEXT') }}
    </button>
    <woot-button
      variant="clear"
      class="small button--visibility"
      :icon="masked ? 'eye-show' : 'eye-hide'"
      @click.prevent="toggleMasked"
    />
    <highlightjs v-if="value" :code="masked ? '•'.repeat(10) : value" />
  </div>
</template>

<script>
import 'highlight.js/styles/default.css';
import { copyTextToClipboard } from 'shared/helpers/clipboard';

export default {
  props: {
    value: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      masked: true,
    };
  },
  methods: {
    async onCopy(e) {
      e.preventDefault();
      await copyTextToClipboard(this.value);
      bus.$emit('newToastMessage', this.$t('COMPONENTS.CODE.COPY_SUCCESSFUL'));
    },
    toggleMasked() {
      this.masked = !this.masked;
    },
  },
};
</script>

<style lang="scss" scoped>
.text--container {
  position: relative;
  text-align: left;

  .button--text {
    margin-top: 0;
    position: absolute;
    right: 0;
  }

  .button--visibility {
    margin-top: 0;
    position: absolute;
    right: 60px;
  }
}
</style>
