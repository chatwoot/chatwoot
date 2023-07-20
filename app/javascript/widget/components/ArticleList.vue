<template>
  <ul role="list" class="py-2">
    <li
      v-for="article in articles"
      :key="article.name"
      class="py-1 flex items-center justify-between"
    >
      <a
        :href="article.href"
        class="text-slate-800 hover:underline underline-offset-2 text-sm leading-6"
      >
        {{ article.name }}
      </a>
      <span class="pl-1 text-slate-700 arrow">
        <fluent-icon icon="arrow-right" size="14" />
      </span>
    </li>
  </ul>
</template>
<script>
export default {
  props: {
    articles: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {};
  },
  mounted() {},
};
</script>
<style scoped>
.arrow svg {
  color: var(--brand-textButtonClear);
}
</style>
