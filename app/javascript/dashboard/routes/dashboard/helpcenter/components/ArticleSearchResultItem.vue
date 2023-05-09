<template>
  <div>
    <h4 class="text-block-title">{{ title }}</h4>
    <p>{{ body }}</p>
    <div>
      <p class="text-small">{{ locale }}/{{ category || 'Uncategorized' }}</p>
      <div class="action-buttons">
        <woot-button
          :variant="hollow"
          :color-scheme="secondary"
          size="tiny"
          icon="copy"
          @click="handleCopy"
        />
        <woot-button
          :variant="hollow"
          :color-scheme="secondary"
          size="tiny"
          icon="arrow-up-right"
          @click="handleOpen"
        />
        <woot-button
          :variant="hollow"
          :color-scheme="secondary"
          size="tiny"
          icon="preview-link"
          @click="handlePreview"
        />
        <woot-button @click="handleClick">Insert</woot-button>
      </div>
    </div>
  </div>
</template>

<script>
import WootButton from '../../../../components/ui/WootButton.vue';
export default {
  name: 'ArticleSearchResultItem',
  components: { WootButton },
  props: {
    title: {
      type: String,
      default: 'Untitled',
    },
    body: {
      type: String,
      default: '',
    },
    url: {
      type: String,
      default: '',
    },
    category: {
      type: String,
      default: '',
    },
    locale: {
      type: String,
      default: 'en-US',
    },
  },
  methods: {
    handleClick() {
      this.$emit('click');
    },
    handlePreview() {
      this.$emit('preview');
    },
    handleOpen() {
      this.$emit('open');
    },
  },
};
</script>
