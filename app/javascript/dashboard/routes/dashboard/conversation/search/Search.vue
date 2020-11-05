<template>
  <woot-modal
    :show.sync="show"
    :on-close="onClose"
    :close-on-backdrop-click="false"
  >
    <div class="search--container">
      <form class="search--form">
        <label>
          <input
            v-model="q"
            autofocus
            placeholder="Search for messages"
            type="text"
          />
        </label>
      </form>
      <div
        v-if="q && (conversations.length || uiFlags.isFetching)"
        class="results--container"
      >
        <div v-if="uiFlags.isFetching">
          Searching for conversations...
        </div>

        <div v-else>
          <div v-for="conversation in conversations" :key="conversation.id">
            <span>{{ conversation.id }}</span>
            <button
              v-for="message in conversation.messages"
              :key="message.id"
              class="search--messages"
            >
              <span v-html="prepareContent(message.content)" />
            </button>
          </div>
        </div>
      </div>
    </div>
  </woot-modal>
</template>

<script>
import { mapGetters } from 'vuex';
export default {
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    onClose: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      q: '',
    };
  },
  computed: {
    ...mapGetters({
      conversations: 'conversationSearch/getConversations',
      uiFlags: 'conversationSearch/getUIFlags',
    }),
  },
  watch: {
    q(newValue) {
      if (this.typingTimer) {
        clearTimeout(this.typingTimer);
      }

      this.typingTimer = setTimeout(() => {
        this.$store.dispatch('conversationSearch/get', { q: newValue });
      }, 1000);
    },
  },
  methods: {
    prepareContent(content = '') {
      return content
        .split(this.q)
        .join(`<span class="search--highlight">${this.q}</span>`);
    },
  },
};
</script>

<style>
.search--container {
  font-size: var(--font-size-default);
  padding: var(--space-normal) 0 var(--space-large);
}

.search--form {
  padding-bottom: 0 !important;
}

.search--highlight {
  background: var(--w-500);
  color: var(--white);
}

.results--container {
  padding: 0 var(--space-large) var(--space-large);
}

.search--messages {
  border-bottom: 1px solid var(--b-100);
  font-size: var(--font-size-normal);
  line-height: 1.5;
  padding-bottom: var(--space-normal);
  padding-top: var(--space-normal);
  text-align: left;
  width: 100%;
}
</style>
