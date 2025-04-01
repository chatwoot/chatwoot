<template>
  <div class="tags-container">
    <button
      v-for="(tag, index) in tags"
      :key="index"
      :disabled="selectedTag === tag.id"
      class="tag-button"
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
    selectedTag: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isUpdating: false,
    };
  },
  methods: {
    ...mapActions('conversation', ['sendMessage']),
    async handleTagClick(tag) {
      this.isUpdating = true;
      try {
        await this.$store.dispatch('message/update', {
          messageId: this.messageId,
          selectedReply: tag.id,
        });
        await this.sendMessage({
          content: tag.text,
          selectedReply: tag.id,
          replyTo: this.messageId,
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
  background-color: #fafafa;
  color: white;
  border: 1px solid #d9d9d9;
  border-radius: 200px;
  padding: 6px 12px;
  font-size: 14px;
  cursor: pointer;
  outline: none;
  color: #262626;
  font-weight: 500;
}

.tag-button:hover {
  scale: 1.02;
}

.selected-tag {
  opacity: 0.5;
}
</style>
