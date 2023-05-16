import slugifyWithCounter from '@sindresorhus/slugify';
import Vue from 'vue';

import PublicArticleSearch from './components/PublicArticleSearch.vue';
import TableOfContents from './components/TableOfContents.vue';

export const getHeadingsfromTheArticle = () => {
  const rows = [];
  const articleElement = document.getElementById('cw-article-content');
  articleElement.querySelectorAll('h1, h2, h3').forEach(element => {
    const slug = slugifyWithCounter(element.innerText);
    element.id = slug;
    element.className = 'scroll-mt-24 heading';
    element.innerHTML += `<a class="invisible text-slate-600 ml-3" href="#${slug}" title="${element.innerText}" data-turbolinks="false">#</a>`;
    rows.push({
      slug,
      title: element.innerText,
      tag: element.tagName.toLowerCase(),
    });
  });
  return rows;
};

export const InitializationHelpers = {
  navigateToLocalePage: () => {
    const allLocaleSwitcher = document.querySelector('.locale-switcher');

    if (!allLocaleSwitcher) {
      return false;
    }

    const { portalSlug } = allLocaleSwitcher.dataset;
    allLocaleSwitcher.addEventListener('change', event => {
      window.location = `/hc/${portalSlug}/${event.target.value}/`;
    });
    return false;
  },

  initalizeSearch: () => {
    const isSearchContainerAvailable = document.querySelector('#search-wrap');
    if (isSearchContainerAvailable) {
      new Vue({
        components: { PublicArticleSearch },
        template: '<PublicArticleSearch />',
      }).$mount('#search-wrap');
    }
  },

  initializeTableOfContents: () => {
    const isOnArticlePage = document.querySelector('#cw-hc-toc');
    if (isOnArticlePage) {
      new Vue({
        components: { TableOfContents },
        data: { rows: getHeadingsfromTheArticle() },
        template: '<table-of-contents :rows="rows" />',
      }).$mount('#cw-hc-toc');
    }
  },

  initialize: () => {
    InitializationHelpers.navigateToLocalePage();
    InitializationHelpers.initalizeSearch();
    InitializationHelpers.initializeTableOfContents();
  },

  onLoad: () => {
    InitializationHelpers.initialize();
    if (window.location.hash) {
      if ('scrollRestoration' in window.history) {
        window.history.scrollRestoration = 'manual';
      }

      const a = document.createElement('a');
      a.href = window.location.hash;
      a['data-turbolinks'] = false;
      a.click();
    }
  },
};
