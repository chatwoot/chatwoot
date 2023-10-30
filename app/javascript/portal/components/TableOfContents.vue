<template>
  <div class="hidden lg:block flex-1 py-6 scroll-mt-24 pl-4">
    <div v-if="rows.length > 0" class="sticky top-24 py-2 overflow-auto">
      <nav class="max-w-2xl">
        <h2
          id="on-this-page-title"
          class="text-slate-800 pl-6 dark:text-slate-50 font-semibold tracking-wide py-3 leading-7 border-l-2 border-solid border-slate-100 dark:border-slate-800"
          :class="{
            '!border-slate-400 dark:!border-slate-100': !currentSlug,
          }"
        >
          {{ tocHeader }}
        </h2>
        <ol role="list" class="text-base">
          <li
            v-for="element in rows"
            :key="element.slug"
            class="leading-6 py-2 pl-6 border-l-2 border-solid"
            :class="elementBorderStyles(element)"
          >
            <p :class="getClassName(element)">
              <a
                :href="`#${element.slug}`"
                data-turbolinks="false"
                class="text-base cursor-pointer"
                :class="elementTextStyles(element)"
              >
                {{ element.title }}
              </a>
            </p>
          </li>
        </ol>
      </nav>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    rows: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      currentSlug: window.location?.hash?.substring(1) || '',
    };
  },
  computed: {
    tocHeader() {
      return window.portalConfig.tocHeader;
    },
    h1Count() {
      return this.rows.filter(el => el.tag === 'h1').length;
    },
    h2Count() {
      return this.rows.filter(el => el.tag === 'h2').length;
    },
  },
  mounted() {
    window.addEventListener('hashchange', this.onURLHashChange);
  },
  beforeDestroy() {
    window.removeEventListener('hashchange', this.onURLHashChange);
  },
  methods: {
    getClassName(el) {
      if (el.tag === 'h1') {
        return '';
      }
      if (el.tag === 'h2') {
        if (this.h1Count > 0) {
          return 'ml-2';
        }
        return '';
      }

      if (el.tag === 'h3') {
        if (!this.h1Count && !this.h2Count) {
          return '';
        }
        return 'ml-8';
      }

      return '';
    },
    onURLHashChange() {
      this.currentSlug = window.location?.hash?.substring(1) || '';
    },
    isElementActive(el) {
      return this.currentSlug === el.slug;
    },
    tocHeaderBorderStyles() {
      if (this.currentSlug === '') {
        return 'border-slate-400 dark:border-slate-100';
      }
      return 'border-slate-100 dark:border-slate-800';
    },
    elementBorderStyles(el) {
      if (this.isElementActive(el)) {
        return 'border-slate-400 dark:border-slate-50 transition-colors duration-200';
      }
      return 'border-slate-100 dark:border-slate-800';
    },
    elementTextStyles(el) {
      if (this.isElementActive(el)) {
        return 'font-semibold text-slate-900 dark:text-slate-25';
      }
      return 'text-slate-700 dark:text-slate-100';
    },
  },
};
</script>
