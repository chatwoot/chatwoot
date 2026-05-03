import actions from './actions';
import mutations from './mutations';

const state = {
  board: null,
  columns: [],
  cards: {}, // keyed by columnId
  selectedCard: null,
  uiFlags: {
    isFetchingBoard: false,
    isCreatingColumn: false,
    isDeletingColumn: false,
    isCreatingCard: false,
  },
};

const getters = {
  getBoard: $state => $state.board,
  getColumns: $state => $state.columns,
  getCardsByColumn: $state => columnId => $state.cards[columnId] || [],
  getSelectedCard: $state => $state.selectedCard,
  getUIFlags: $state => $state.uiFlags,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
