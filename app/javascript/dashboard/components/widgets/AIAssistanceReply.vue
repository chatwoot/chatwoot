<template>
  <div class="column">
    <woot-modal-header header-title="Reply suggestion with AI" />
    <form class="row modal-content" @submit.prevent="chooseTime">
      <div v-if="!generatedContent" class="animation-container">
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
        'Hi there! Its great to see you here. How can I be of assistance to you today? Whether you need help with a specific task or have a general question, I am here to lend a hand. Let me know what you need, and I will do my best to provide you with the information or guidance you are looking for.';
    }, 5000);
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

.animation-container {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
}
.loader {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  display: block;
  margin-top: 2rem;
  position: relative;
  color: #000;
  box-sizing: border-box;
  animation: animloader 2s linear infinite;
}

@keyframes animloader {
  0% {
    box-shadow: 14px 0 0 -2px, 38px 0 0 -2px, -14px 0 0 -2px, -38px 0 0 -2px;
  }
  25% {
    box-shadow: 14px 0 0 -2px, 38px 0 0 -2px, -14px 0 0 -2px, -38px 0 0 2px;
  }
  50% {
    box-shadow: 14px 0 0 -2px, 38px 0 0 -2px, -14px 0 0 2px, -38px 0 0 -2px;
  }
  75% {
    box-shadow: 14px 0 0 2px, 38px 0 0 -2px, -14px 0 0 -2px, -38px 0 0 -2px;
  }
  100% {
    box-shadow: 14px 0 0 -2px, 38px 0 0 2px, -14px 0 0 -2px, -38px 0 0 -2px;
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
