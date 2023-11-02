import { itemById, uIFlags } from 'shared/helpers/vuex/getterHelpers.js';

export const getters = {
  uIFlags,
  messageById: state => itemById(state, 'messages'),
};
