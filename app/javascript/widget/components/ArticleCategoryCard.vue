<script>
import { mapGetters } from 'vuex';
import ArticleList from './ArticleList.vue';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

export default {
  components: { FluentIcon, ArticleList },
  props: {
    title: {
      type: String,
      default: '',
    },
    articles: {
      type: Array,
      default: () => [],
    },
  },
  emits: ['view', 'viewAll'],
  computed: {
    ...mapGetters({ : '' }),
  },
  methods: {
    onArticleClick(link) {
      this.$emit('view', link);
    },
  },
};
</script>

<template></template>
