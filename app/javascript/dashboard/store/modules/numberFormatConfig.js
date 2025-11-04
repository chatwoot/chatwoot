import NumberFormatConfigAPI from '../../api/numberFormatConfig';

const state = {
  config: {
    id: null,
    prefix: '',
    format: '[NUMBER]/[MONTH]/[YEAR]',
    currentNumber: 1,
    resetEvery: 'never',
    number_digits: 3,
  },
  loading: false,
  error: null,
};

const getters = {
  // Getter ini aman jika state.config null
  errorMessage: state => {
    if (!state.error) return '';
  },
  // Kita biarkan getter ini di sini untuk referensi,
  // tapi kita buat aman
  sampleOutput: state => {
    if (!state.config) return '...';
  }
};

const actions = {
  async fetchConfig({ commit }) {
    commit('SET_LOADING', true);
    commit('SET_ERROR', null);
    try {
      const response = await NumberFormatConfigAPI.getConfig();
      const config = response.data;

      if (config) {
        commit('SET_CONFIG', {
          id: config.id,
          prefix: config.prefix,
          format: config.format,
          currentNumber: config.current_number, 
          resetEvery: config.reset_every,
          number_digits: config.number_digits,
        });
      } else {
        commit('SET_CONFIG', state.config);
      }
    } catch (err) {
      commit('SET_ERROR', state.config);
    } finally {
      commit('SET_LOADING', false);
    }
  },

  async saveConfig({ commit, dispatch }, formPayload) {
    commit('SET_LOADING', true);
    commit('SET_ERROR', null);

    const apiPayload = {
      id: formPayload.id,
      prefix: formPayload.prefix,
      format: formPayload.format,
      current_number: Number(formPayload.currentNumber),
      reset_every: formPayload.resetEvery,
      number_digits: Number(formPayload.number_digits),
    };

    try {
      if (apiPayload.id) {
        await NumberFormatConfigAPI.updateConfig(apiPayload);
      } else {
        await NumberFormatConfigAPI.createConfig(apiPayload);
      }
      await dispatch('fetchConfig'); 
    } catch (err) {
      commit('SET_ERROR', err);
    } finally {
      commit('SET_LOADING', false);
    }
  },
};

const mutations = {
  SET_LOADING(state, value) {
    state.loading = value;
  },
  SET_ERROR(state, error) {
    state.error = error;
  },
  SET_CONFIG(state, configPayload) {
    state.config = configPayload;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};