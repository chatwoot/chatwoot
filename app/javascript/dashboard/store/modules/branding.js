import brandingAPI from 'dashboard/api/branding';

const state = {
  brandName: 'SynkiCRM',
  brandWebsite: 'https://synkicrm.com.br/',
  supportEmail: 'suporte@synkicrm.com.br',
  logoMainUrl: null,
  logoCompactUrl: null,
  faviconUrl: null,
  appleTouchIconUrl: null,
  uiFlags: {
    isFetching: false,
  },
};

export const getters = {
  get: $state => $state,
  brandName: $state => $state.brandName,
  brandWebsite: $state => $state.brandWebsite,
  supportEmail: $state => $state.supportEmail,
  logoMainUrl: $state => $state.logoMainUrl,
  logoCompactUrl: $state => $state.logoCompactUrl || $state.logoMainUrl,
  faviconUrl: $state => $state.faviconUrl,
  appleTouchIconUrl: $state => $state.appleTouchIconUrl,
};

export const actions = {
  async fetch({ commit }) {
    commit('SET_UI_FLAG', { isFetching: true });
    try {
      const response = await brandingAPI.get();
      const data = response.data;
      commit('SET_BRANDING', {
        brandName: data.brand_name || 'SynkiCRM',
        brandWebsite: data.brand_website || 'https://synkicrm.com.br/',
        supportEmail: data.support_email || 'suporte@synkicrm.com.br',
        logoMainUrl: data.logo_main_url,
        logoCompactUrl: data.logo_compact_url,
        faviconUrl: data.favicon_url,
        appleTouchIconUrl: data.apple_touch_icon_url,
      });
      // Update favicon if available
      if (data.favicon_url) {
        updateFavicon(data.favicon_url);
      }
      // Update document title
      if (data.brand_name) {
        document.title = data.brand_name;
      }
    } catch (error) {
      console.error('Failed to fetch branding:', error);
    } finally {
      commit('SET_UI_FLAG', { isFetching: false });
    }
  },
};

export const mutations = {
  SET_BRANDING($state, branding) {
    Object.assign($state, branding);
  },
  SET_UI_FLAG($state, flag) {
    $state.uiFlags = { ...$state.uiFlags, ...flag };
  },
};

function updateFavicon(url) {
  // Remove existing favicon links
  const existingLinks = document.querySelectorAll('link[rel*="icon"]');
  existingLinks.forEach(link => link.remove());

  // Add new favicon
  const link = document.createElement('link');
  link.rel = 'icon';
  link.type = 'image/x-icon';
  link.href = url;
  document.head.appendChild(link);

  // Also update apple-touch-icon if available
  const appleLink = document.querySelector('link[rel="apple-touch-icon"]');
  if (appleLink) {
    appleLink.href = url;
  }
}

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};

