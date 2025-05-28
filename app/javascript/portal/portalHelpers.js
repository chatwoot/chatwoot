import { createApp } from 'vue';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import { domPurifyConfig } from '../shared/helpers/HTMLSanitizer';
import { directive as onClickaway } from 'vue3-click-away';

import slugifyWithCounter from '@sindresorhus/slugify';
import PublicArticleSearch from './components/PublicArticleSearch.vue';
import TableOfContents from './components/TableOfContents.vue';
import { initializeTheme } from './portalThemeHelper.js';

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

/**
 * Converts various input formats to URL objects.
 * Handles URL objects, domain strings, relative paths, and full URLs.
 * @param {string|URL} input - Input to convert to URL object
 * @returns {URL|null} URL object or null if input is invalid
 */
const toURL = input => {
  if (!input) return null;
  if (input instanceof URL) return input;

  if (
    typeof input === 'string' &&
    !input.includes('://') &&
    !input.startsWith('/')
  ) {
    return new URL(`https://${input}`);
  }

  if (typeof input === 'string' && input.startsWith('/')) {
    return new URL(input, window.location.origin);
  }

  return new URL(input);
};

/**
 * Determines if two URLs belong to the same host by comparing their normalized URL objects.
 * Handles various input formats including URL objects, domain strings, relative paths, and full URLs.
 * Returns false if either URL cannot be parsed or normalized.
 * @param {string|URL} url1 - First URL to compare
 * @param {string|URL} url2 - Second URL to compare
 * @returns {boolean} True if both URLs have the same host, false otherwise
 */
const isSameHost = (url1, url2) => {
  try {
    const urlObj1 = toURL(url1);
    const urlObj2 = toURL(url2);

    if (!urlObj1 || !urlObj2) return false;

    return urlObj1.hostname === urlObj2.hostname;
  } catch (error) {
    return false;
  }
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

  initializeThemesInPortal: initializeTheme,

  initialize: () => {
    openExternalLinksInNewTab();
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
