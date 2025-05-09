<template>
  <div
    class="tags-container"
    :class="{
      'mt-0': filteredTags && filteredTags.length === 0,
    }"
  >
    <button
      v-for="(tag, index) in filteredTags"
      :key="index"
      :disabled="previousSelectedReplies.includes(tag.id)"
      class="tag-button transition-all duration-300"
      :class="{
        'selected-tag': previousSelectedReplies.includes(tag.id),
        'cursor-not-allowed': previousSelectedReplies.includes(tag.id),
      }"
      @click="handleTagClick(tag)"
    >
      {{ tag.text }}
    </button>
  </div>
</template>

<script>
import { mapActions } from 'vuex';

export default {
  name: 'TagButtonList',
  props: {
    tags: {
      type: Array,
      required: true, // A string array of tags is expected
    },
    messageId: {
      type: Number,
      required: true,
    },
    previousSelectedReplies: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      isUpdating: false,
    };
  },
  computed: {
    filteredTags() {
      return this.tags?.filter(tag => tag.text != null && tag.text !== '');
    },
  },
  methods: {
    ...mapActions('conversation', ['sendMessage']),
    async handleTagClick(tag) {
      this.isUpdating = true;
      try {
        await this.$store.dispatch('message/update', {
          messageId: this.messageId,
          selectedReply: tag.id,
          previousSelectedReplies: [...this.previousSelectedReplies, tag.id],
        });
        await this.sendMessage({
          content: tag.text,
          selectedReply: tag.id,
          replyTo: this.messageId,
          previousSelectedReplies: [...this.previousSelectedReplies, tag.id],
        });
      } catch (error) {
        // Ignore error
      } finally {
        this.isUpdating = false;
      }
    },
  },
};
</script>

<style scoped>
.tags-container {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tag-button {
  background: white;
  border: 1px solid #cccccc;
  border-radius: 200px;
  padding: 6px 12px;
  font-size: 14px;
  cursor: pointer;
  outline: none;
  color: #262626;
  font-weight: 500;
}

.tag-button:hover {
  background: var(--widget-color);
  color: var(--text-color);
  border: 1px solid var(--widget-color);
}

.tag-button:disabled:hover {
  cursor: not-allowed;
  background: white;
  border: 1px solid #cccccc;
  color: #262626;
}

.selected-tag {
  opacity: 0.5;
}
</style>
