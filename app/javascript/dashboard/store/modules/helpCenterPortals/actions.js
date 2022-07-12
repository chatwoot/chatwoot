import HelpCenterPortalsAPI from 'widget/api/conversationPublic';

export const actions = {
  fetchAllHelpCenters: async ({ commit }) => {
    try {
      commit('setUIFlag', { isFetching: true });
      const { data } = await HelpCenterPortalsAPI.get();
      data.forEach(helpCenter => {
        const { id: helpCenterId, locales } = helpCenter;

        commit('addHelpCenterEntry', helpCenter);
        commit('addHelpCenterId', helpCenterId);
        commit('setHelpCenterUIFlag', {
          uiFlags: {},
          helpCenterId,
        });
        // commit(
        //   'locales/addLocalesEntry',
        //   { helpCenterId, locales: locales },
        //   { root: true }
        // );
        commit('appendLocaleIdsToHelpCenter', {
          helpCenterId,
          locales,
        });
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },

  createHelpCenter: async ({ commit }, params) => {
    commit('setUIFlag', { isCreating: true });
    try {
      const { data } = await HelpCenterPortalsAPI.create(params);
      const { id: helpCenterId, locales } = data;

      commit('addHelpCenterEntry', data);
      commit('addHelpCenterId', helpCenterId);
      // commit(
      //   'locales/addLocalesEntry',
      //   { helpCenterId, locales: locales },
      //   { root: true }
      // );
      commit('appendLocaleIdsToHelpCenter', {
        helpCenterId,
        locales,
      });
      return helpCenterId;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isCreating: false });
    }
  },

  updateHelpCenter: async ({ commit }, params) => {
    const helpCenterId = params.id;
    commit('setHelpCenterUIFlag', {
      uiFlags: {
        isUpdating: true,
      },
      helpCenterId,
    });
    try {
      const { data } = await HelpCenterPortalsAPI.update(params);
      const { locales } = data;

      commit('updateHelpCenterEntry', data);
      // commit(
      //   'locales/addLocalesEntry',
      //   { helpCenterId, locales: locales },
      //   { root: true }
      // );
      commit('appendLocaleIdsToHelpCenter', {
        helpCenterId,
        locales,
      });
      return helpCenterId;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setHelpCenterUIFlag', {
        uiFlags: {
          isUpdating: false,
        },
        helpCenterId,
      });
    }
  },

  deleteHelpCenter: async ({ commit }, helpCenterId) => {
    commit('setHelpCenterUIFlag', {
      uiFlags: {
        isDeleting: true,
      },
      helpCenterId,
    });
    try {
      await HelpCenterPortalsAPI.delete(helpCenterId);

      commit('removeHelpCenterEntry', helpCenterId);
      commit('removeHelpCenterId', helpCenterId);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setHelpCenterUIFlag', {
        uiFlags: {
          isDeleting: false,
        },
        helpCenterId,
      });
    }
  },
};
