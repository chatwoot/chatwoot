import { createApp } from 'vue';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import { domPurifyConfig } from '../shared/helpers/HTMLSanitizer';
import { directive as onClickaway } from 'vue3-click-away';
import { isSameHost } from '@chatwoot/utils';

import slugifyWithCounter from '@sindresorhus/slugify';
import PublicArticleSearch from './components/PublicArticleSearch.vue';
import TableOfContents from './components/TableOfContents.vue';
import { initializeTheme } from './portalThemeHelper.js';
import { getLanguageDirection } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages.js';

export const getHeadingsfromTheArticle = () => {
  const rows = [];
  const articleElement = document.getElementById('cw-article-content');
  articleElement.querySelectorAll('h1, h2, h3').forEach(element => {
    const slug = slugifyWithCounter(element.innerText);
    element.id = slug;
    element.className = 'scroll-mt-24 heading';
    element.innerHTML += `<a class="permalink text-slate-600 ml-3" href="#${slug}" title="${element.innerText}" data-turbolinks="false">#</a>`;
    rows.push({
      slug,
      title: element.innerText,
      tag: element.tagName.toLowerCase(),
    });
  });
  return rows;
};

export const openExternalLinksInNewTab = () => {
  const { customDomain, hostURL } = window.portalConfig;
  const isOnArticlePage =
    document.querySelector('#cw-article-content') !== null;

  document.addEventListener('click', event => {
    if (!isOnArticlePage) return;

    const link = event.target.closest('a');

    if (link) {
      const currentLocation = window.location.href;
      const linkHref = link.href;

      // Check against current location and custom domains
      const isInternalLink =
        isSameHost(linkHref, currentLocation) ||
        (customDomain && isSameHost(linkHref, customDomain)) ||
        (hostURL && isSameHost(linkHref, hostURL));

      if (!isInternalLink) {
        link.target = '_blank';
        link.rel = 'noopener noreferrer'; // Security and performance benefits
        // Prevent default if you want to stop the link from opening in the current tab
        event.stopPropagation();
      }
    }
  });
};

export const InitializationHelpers = {
  navigateToLocalePage: () => {
    document.addEventListener('change', e => {
      const localeSwitcher = e.target.closest('.locale-switcher');
      if (!localeSwitcher) return;

      const { portalSlug } = localeSwitcher.dataset;
      window.location.href = `/hc/${encodeURIComponent(portalSlug)}/${encodeURIComponent(localeSwitcher.value)}/`;
    });
  },

  initializeSearch: () => {
    const isSearchContainerAvailable = document.querySelector('#search-wrap');
    if (isSearchContainerAvailable) {
      // eslint-disable-next-line vue/one-component-per-file
      const app = createApp({
        components: { PublicArticleSearch },
        template: '<PublicArticleSearch />',
      });

      app.use(VueDOMPurifyHTML, domPurifyConfig);
      app.directive('on-clickaway', onClickaway);
      app.mount('#search-wrap');
    }
  },

  initializeTableOfContents: () => {
    const isOnArticlePage = document.querySelector('#cw-hc-toc');
    if (isOnArticlePage) {
      // eslint-disable-next-line vue/one-component-per-file
      const app = createApp({
        components: { TableOfContents },
        data() {
          return { rows: getHeadingsfromTheArticle() };
        },
        template: '<table-of-contents :rows="rows" />',
      });

      app.use(VueDOMPurifyHTML, domPurifyConfig);
      app.mount('#cw-hc-toc');
    }
  },

  appendPlainParamToURLs: () => {
    [...document.getElementsByTagName('a')].forEach(aTagElement => {
      if (aTagElement.href && aTagElement.href.includes('/hc/')) {
        const url = new URL(aTagElement.href);
        url.searchParams.set('show_plain_layout', 'true');

        aTagElement.setAttribute('href', url);
      }
    });
  },

  setDirectionAttribute: () => {
    const htmlElement = document.querySelector('html');
    // If direction is already applied through props, do not apply again (iframe case)
    const hasDirApplied = htmlElement.getAttribute('data-dir-applied');
    if (!htmlElement || hasDirApplied) return;

    const localeFromHtml = htmlElement.lang;
    htmlElement.dir =
      localeFromHtml && getLanguageDirection(localeFromHtml) ? 'rtl' : 'ltr';
  },

  initializeThemesInPortal: initializeTheme,

  initialize: () => {
    openExternalLinksInNewTab();
    InitializationHelpers.setDirectionAttribute();
    if (window.portalConfig.isPlainLayoutEnabled === 'true') {
      InitializationHelpers.appendPlainParamToURLs();
    } else {
      InitializationHelpers.initializeThemesInPortal();
      InitializationHelpers.navigateToLocalePage();
      InitializationHelpers.initializeSearch();
      InitializationHelpers.initializeTableOfContents();
    }
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
