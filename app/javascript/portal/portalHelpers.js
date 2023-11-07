import slugifyWithCounter from '@sindresorhus/slugify';
import Vue from 'vue';
import Cookies from 'js-cookie';

import PublicArticleSearch from './components/PublicArticleSearch.vue';
import TableOfContents from './components/TableOfContents.vue';
import { adjustColorForContrast } from '../shared/helpers/colorHelper.js';

const SYSTEM_COOKIE = 'system_theme';
const SELECTED_COOKIE = 'selected_theme';

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

export const setPortalHoverColor = theme => {
  if (window.portalConfig.isPlainLayoutEnabled === 'true') return;
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
  portalDiv.classList.remove('light', 'dark', 'system');
  if (!portalDiv) return;
  portalDiv.classList.add(theme);
};

export const updateThemeStyles = theme => {
  setPortalClass(theme);
  setPortalHoverColor(theme);
};

export const toggleAppearanceDropdown = () => {
  const dropdown = document.getElementById('appearance-dropdown');
  if (!dropdown) return;
  dropdown.style.display =
    dropdown.style.display === 'none' || !dropdown.style.display
      ? 'flex'
      : 'none';
};

export const switchTheme = theme => {
  Cookies.set(SELECTED_COOKIE, theme, { expires: 365 });

  if (theme === 'system') {
    const mediaQueryList = window.matchMedia('(prefers-color-scheme: dark)');
    updateThemeStyles(mediaQueryList.matches ? 'dark' : 'light');
  } else {
    updateThemeStyles(theme);
  }
  updateActiveThemeInHeader(theme);
  toggleAppearanceDropdown();
};

export const updateThemeSelectionInHeader = theme => {
  // This function is to update the theme selection in the header in real time
  const buttonContainer = document.getElementById('toggle-appearance');
  const allElementInButton = buttonContainer.querySelectorAll('.theme-button');
  const activeThemeElement = document.querySelector(
    `.theme-button.${theme}-theme`
  );

  allElementInButton.forEach(button => {
    button.classList.remove('flex');
    button.classList.add('hidden');
  });

  if (activeThemeElement) {
    activeThemeElement.classList.remove('hidden');
    activeThemeElement.classList.add('flex');
  }
};

export const setActiveThemeIconInDropdown = theme => {
  // This function is to set the check mark icon for the active theme in the dropdown in real time
  const dropdownContainer = document.getElementById('appearance-dropdown');
  const allCheckMarkIcons =
    dropdownContainer.querySelectorAll('.check-mark-icon');
  const activeIcon = document.querySelector(`.check-mark-icon.${theme}-theme`);

  allCheckMarkIcons.forEach(icon => {
    icon.classList.remove('flex');
    icon.classList.add('hidden');
  });

  if (activeIcon) {
    activeIcon.classList.remove('hidden');
    activeIcon.classList.add('flex');
  }
};

export const updateActiveThemeInHeader = theme => {
  updateThemeSelectionInHeader(theme);
  setActiveThemeIconInDropdown(theme);
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
        if (Cookies.get(SELECTED_COOKIE) !== 'system') return;

        const newTheme = event.matches ? 'dark' : 'light';
        Cookies.set(SYSTEM_COOKIE, newTheme, { expires: 365 });
        updateThemeStyles(newTheme);
      });

      const themePreference = getThemePreference();
      Cookies.set(SYSTEM_COOKIE, themePreference, { expires: 365 });
      updateThemeStyles(themePreference);
      updateActiveThemeInHeader('system');
    } else {
      Cookies.set(SELECTED_COOKIE, themeFromServer, { expires: 365 });
      updateThemeStyles(themeFromServer);
      updateActiveThemeInHeader(themeFromServer);
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
