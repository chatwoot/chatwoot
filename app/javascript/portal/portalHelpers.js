import slugifyWithCounter from '@sindresorhus/slugify';
import Vue from 'vue';

import PublicArticleSearch from './components/PublicArticleSearch.vue';
import TableOfContents from './components/TableOfContents.vue';
import { adjustColorForContrast } from '../shared/helpers/colorHelper.js';

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

export const isPlainLayoutEnabled = () => {
  return window.portalConfig.isPlainLayoutEnabled === 'true';
};

export const setPortalHoverStyles = theme => {
  if (isPlainLayoutEnabled()) return;
  const portalColor = window.portalConfig.portalColor;
  const bgColor = theme === 'dark' ? '#151718' : 'white';
  const hoverColor = adjustColorForContrast(portalColor, bgColor);

  // Set hover color for border and text dynamically
  document.documentElement.style.setProperty(
    '--dynamic-hover-color',
    hoverColor
  );
};

export const setPortalClass = theme => {
  const portalDiv = document.querySelector('#portal');
  portalDiv.classList.remove('light', 'dark');
  if (!portalDiv) return;
  portalDiv.classList.add(theme);
};

export const updateThemeStyles = theme => {
  setPortalClass(theme);
  setPortalHoverStyles(theme);
};

export const toggleAppearanceDropdown = () => {
  const dropdown = document.getElementById('appearance-dropdown');
  if (!dropdown) return;
  dropdown.style.display =
    dropdown.style.display === 'none' || !dropdown.style.display
      ? 'flex'
      : 'none';
};

export const updateURLParameter = (param, paramVal) => {
  const urlObj = new URL(window.location);
  urlObj.searchParams.set(param, paramVal);
  return urlObj.toString();
};

export const removeURLParameter = parameter => {
  const urlObj = new URL(window.location);
  urlObj.searchParams.delete(parameter);
  return urlObj.toString();
};

export const switchTheme = theme => {
  updateThemeStyles(theme);
  const newUrl =
    theme !== 'system'
      ? updateURLParameter('theme', theme)
      : removeURLParameter('theme');
  window.location.href = newUrl;
  toggleAppearanceDropdown();
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

  appendPlainParamToURLs: () => {
    document.getElementsByTagName('a').forEach(aTagElement => {
      if (aTagElement.href && aTagElement.href.includes('/hc/')) {
        const url = new URL(aTagElement.href);
        url.searchParams.set('show_plain_layout', 'true');

        aTagElement.setAttribute('href', url);
      }
    });
  },

  initializeTheme: () => {
    const mediaQueryList = window.matchMedia('(prefers-color-scheme: dark)');
    const getThemePreference = () =>
      mediaQueryList.matches ? 'dark' : 'light';
    const { theme: themeFromServer } = window.portalConfig || {};

    if (themeFromServer === 'system') {
      // Handle dynamic theme changes for system theme
      mediaQueryList.addEventListener('change', event => {
        const newTheme = event.matches ? 'dark' : 'light';
        updateThemeStyles(newTheme);
      });
      const themePreference = getThemePreference();
      updateThemeStyles(themePreference);
    } else {
      updateThemeStyles(themeFromServer);
    }
  },

  initializeToggleButton: () => {
    const toggleButton = document.getElementById('toggle-appearance');
    if (toggleButton) {
      toggleButton.addEventListener('click', toggleAppearanceDropdown);
    }
  },

  initializeThemeSwitchButtons: () => {
    const appearanceDropdown = document.getElementById('appearance-dropdown');
    if (!appearanceDropdown) return;
    appearanceDropdown.addEventListener('click', event => {
      const target = event.target.closest('button[data-theme]');

      if (target) {
        const theme = target.getAttribute('data-theme');
        switchTheme(theme);
      }
    });
  },

  initialize: () => {
    if (window.portalConfig.isPlainLayoutEnabled === 'true') {
      InitializationHelpers.appendPlainParamToURLs();
    } else {
      InitializationHelpers.initializeTheme();
      InitializationHelpers.initializeToggleButton();
      InitializationHelpers.initializeThemeSwitchButtons();
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
