<template>
  <div class="column">
    <woot-modal-header header-title="Reply suggestion with AI" />
    <form class="row modal-content" @submit.prevent="chooseTime">
      <div v-if="!generatedContent" class="animation-container margin-top-1">
        <div class="ai-typing--wrap ">
          <fluent-icon icon="wand" size="14" class="ai-typing--icon" />
          <label>AI is writing</label>
        </div>
        <span class="loader" />
        <span class="loader" />
        <span class="loader" />
      </div>

      <div v-else>
        <p>
          {{ aiContent }}
        </p>
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
        <woot-button :disabled="!enableButtons" @click="applyContent">
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
        'Hi there! Its great to see you here. How can I be of assistance to you today? Whether you need help with a specific task or have a general question, I am here to lend a hand. Let me know what you need, and I will do my best to provide you with the information or guidance you are looking for.';
    }, 5000);
  },

  methods: {
    onClose() {
      this.$emit('close');
    },
    chooseTime() {},
    applyContent() {
      this.$emit('apply-text', this.generatedContent);
      this.$emit('close');
    },
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

// .typewriter p {
//   overflow: hidden; /* Ensures the content is not revealed until the animation */
//   border-right: 0.15em solid orange; /* The typwriter cursor */
//   margin: 0 auto; /* Gives that scrolling effect as the typing happens */
//   animation: typing 3.5s steps(30, end), blink-caret 0.5s step-end infinite;
// }

// /* The typing effect */
// @keyframes typing {
//   from {
//     width: 0;
//   }
//   to {
//     width: 100%;
//   }
// }

// @keyframes blink-caret {
//   from,
//   to {
//     border-color: transparent;
//   }
//   50% {
//     border-color: orange;
//   }
// }
</style>
