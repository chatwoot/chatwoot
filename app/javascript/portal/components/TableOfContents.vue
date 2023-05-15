<template>
  <div class="hidden lg:block flex-1 scroll-mt-24 pl-4">
    <div v-if="rows.length > 0" class="sticky top-24 py-12">
      <nav aria-labelledby="on-this-page-title" class="max-w-2xl">
        <h2
          id="on-this-page-title"
          class="text-slate-800 font-semibold tracking-wide border-b mb-3 leading-7"
        >
          {{ tocHeader }}
        </h2>
        <ol role="list" class="mt-4 space-y-3 text-base">
          <li
            v-for="(element, index) in rows"
            :key="element.slug"
            class="leading-6"
          >
            <p :class="getClassName(element)">
              <a
                :href="`#${element.slug}`"
                data-turbolinks="false"
                class="text-base text-slate-800 cursor-pointer"
                :class="activeSection === index ? 'text-woot-500' : ''"
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
    return { activeSection: -1 };
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
  },
};
</script>
