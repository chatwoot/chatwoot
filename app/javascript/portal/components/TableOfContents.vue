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
      intersectionObserver: null,
    };
  },
  computed: {
    h1Count() {
      return this.rows.filter(el => el.tag === 'h1').length;
    },
    h2Count() {
      return this.rows.filter(el => el.tag === 'h2').length;
    },
  },
  mounted() {
    this.initializeIntersectionObserver();
    window.addEventListener('hashchange', this.onURLHashChange);
  },
  unmounted() {
    window.removeEventListener('hashchange', this.onURLHashChange);
    if (this.intersectionObserver) {
      this.intersectionObserver.disconnect();
    }
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
        return 'ml-5';
      }

      return '';
    },
    initializeIntersectionObserver() {
      this.intersectionObserver = new IntersectionObserver(
        entries => {
          const currentSection = entries.find(entry => entry.isIntersecting);
          if (currentSection) {
            this.currentSlug = currentSection.target.id;
          }
        },
        {
          threshold: 0.25,
          rootMargin: '0px 0px -20% 0px',
        }
      );

      this.rows.forEach(el => {
        const sectionElement = document.getElementById(el.slug);
        if (!sectionElement) return;
        this.intersectionObserver.observe(sectionElement);
      });
    },
    onURLHashChange() {
      this.currentSlug = window.location?.hash?.substring(1) || '';
    },
    isElementActive(el) {
      return this.currentSlug === el.slug;
    },
    elementBorderStyles(el) {
      if (this.isElementActive(el)) {
        return 'border-slate-400 dark:border-slate-50 transition-colors duration-200';
      }
      return 'border-slate-100 dark:border-slate-800';
    },
    elementTextStyles(el) {
      if (this.isElementActive(el)) {
        return 'text-slate-900 dark:text-slate-25 transition-colors duration-200';
      }
      return 'text-slate-700 dark:text-slate-100';
    },
  },
};
</script>

<template>
  <div class="hidden lg:block flex-1 py-6 scroll-mt-24 pl-4 sticky top-24">
    <div v-if="rows.length > 0" class="py-2 overflow-auto">
      <nav class="max-w-2xl">
        <ol
          role="list"
          class="flex flex-col gap-2 text-base border-l-2 border-solid border-slate-100 dark:border-slate-800"
        >
          <li
            v-for="element in rows"
            :key="element.slug"
            class="leading-6 border-l-2 relative -left-0.5 border-solid"
            :class="elementBorderStyles(element)"
          >
            <p class="py-1 px-3" :class="getClassName(element)">
              <a
                :href="`#${element.slug}`"
                data-turbolinks="false"
                class="font-medium text-sm tracking-[0.28px] cursor-pointer"
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
