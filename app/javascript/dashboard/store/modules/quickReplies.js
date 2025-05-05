import QuickReplies from '../../api/quickReplies';

export const actions = {
  get(_) {
    return QuickReplies.show();
  },
  create(_, { name, content }) {
    return QuickReplies.create({ name, content });
  },
  update(_, {  id, name, content }) {
    return QuickReplies.update({ id, name, content });
  },
  destroy(_, { id }) {
    return QuickReplies.destroy({ id });
  },
};

export default {
  namespaced: true,
  actions,
};
