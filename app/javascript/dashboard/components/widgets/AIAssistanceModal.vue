<template>
  <div class="column">
    <woot-modal-header header-title="Rephrase the content" />
    <form class="row modal-content" @submit.prevent="chooseTime">
      <div>
        <h4 class="sub-block-title margin-top-1">
          Draft content
        </h4>
      </div>

      <p>
        {{ draftContent }}
      </p>
      <div class="container">
        <h4 class="sub-block-title margin-top-1">
          AI generated content
        </h4>
      </div>
      <div class="animation-container margin-top-1">
        <div class="ai-typing--wrap ">
          <fluent-icon icon="wand" size="14" class="ai-typing--icon" />
          <label>AI is writing</label>
        </div>
        <span class="loader" />
        <span class="loader" />
        <span class="loader" />
      </div>

      <div class="modal-footer justify-content-end w-full">
        <!-- <woot-button
          icon="delete-outline"
          variant="clear"
          @click.prevent="onClose"
        >
          Discard
        </woot-button> -->
        <woot-button variant="clear" @click.prevent="onClose">
          Discard
        </woot-button>
        <!-- <woot-button
          v-tooltip.top-end="$t('CONVERSATION.TRY_AGAIN')"
          color-scheme="alert"
          variant="clear"
          icon="arrow-clockwise"
          :disabled="!enableButtons"
          >Retry
        </woot-button> -->
        <woot-button :disabled="!enableButtons">
          Apply
        </woot-button>
      </div>
    </form>
  </div>
</template>

<script>
export default {
  data() {
    return {
      draftContent:
        'I am closing this thread as there is no response. Please feel to create a new one if the issue/query is not resolved.',
      generatedContent: '',
    };
  },
  computed: {
    aiContent() {
      return this.generatedContent.length > 0
        ? this.generatedContent
        : 'Generating content...';
    },
    enableButtons() {
      return this.generatedContent.length > 0;
    },
  },
  mounted() {
    setTimeout(() => {
      this.generatedContent =
        'I am closing this thread as there has been no response. Please feel free to create a new thread if the issue or query remains unresolved.';
    }, 6000);
  },

  methods: {
    onClose() {
      this.$emit('close');
    },
    chooseTime() {},
  },
};
</script>

<style lang="scss" scoped>
.modal-content {
  padding-top: var(--space-small);
}

.container {
  width: 100%;
}

.ai-typing--wrap {
  display: flex;
  align-items: center;
  gap: 4px;

  .ai-typing--icon {
    color: var(--v-500);
  }
}

.animation-container {
  position: relative;
  display: flex;
}

.animation-container label {
  display: inline-block;
  margin-right: 8px;
  color: var(--v-400);
}

.loader {
  display: inline-block;
  width: 6px;
  height: 6px;
  margin-right: 4px;
  margin-top: 12px;
  background-color: var(--v-300);
  border-radius: 50%;
  animation: bubble-scale 1.2s infinite;
}

.loader:nth-child(2) {
  animation-delay: 0.4s;
}

.loader:nth-child(3) {
  animation-delay: 0.8s;
}

@keyframes bubble-scale {
  0%,
  100% {
    transform: scale(1);
  }
  25% {
    transform: scale(1.3);
  }
  50% {
    transform: scale(1);
  }
}
</style>
