import { CSAT_RATINGS } from 'shared/constants/messages';

export const buildFilterList = (items, type) =>
  items.map(item => ({
    id: item.id,
    name: type === 'ratings' ? item.emoji : item.name,
    type,
  }));

export const buildRatingsList = t =>
  CSAT_RATINGS.map(rating => ({
    id: rating.value,
    name: `${t(rating.translationKey)}`,
    type: 'ratings',
  }));

export const getActiveFilter = (filters, type, key) =>
  filters.find(item => item.id.toString() === key.toString());

export const getFilterType = (input, direction) => {
  const filterMap = {
    keyToType: {
      user_ids: 'agents',
      inbox_id: 'inboxes',
      team_id: 'teams',
      rating: 'ratings',
    },
    typeToKey: {
      agents: 'user_ids',
      inboxes: 'inbox_id',
      teams: 'team_id',
      ratings: 'rating',
    },
  };
  return filterMap[direction][input];
};
