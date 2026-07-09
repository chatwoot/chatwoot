export const defaultAdvancedLeadFilters = () => ({
  has_website: '',
  has_phone: '',
  has_photos: '',
  open_now: '',
  rating_min: '',
  rating_max: '',
  reviews_min: '',
  search_rank_max: '',
});

const booleanFilterMatches = (value, filterValue) => {
  if (!filterValue) return true;
  return filterValue === 'yes' ? Boolean(value) : !value;
};

const optionalBooleanFilterMatches = (value, filterValue) => {
  if (!filterValue) return true;
  if (value === null || value === undefined) return false;

  return filterValue === 'yes' ? value === true : value === false;
};

const numberOrNull = value => {
  if (value === null || value === undefined || value === '') return null;

  const number = Number(value);
  return Number.isNaN(number) ? null : number;
};

export const filterLeadsByAdvancedFilters = (leads, filters) =>
  leads.filter(lead => {
    if (!booleanFilterMatches(lead.website, filters.has_website)) {
      return false;
    }

    if (!booleanFilterMatches(lead.phone, filters.has_phone)) {
      return false;
    }

    if (!booleanFilterMatches(lead.has_photos, filters.has_photos)) {
      return false;
    }

    if (!optionalBooleanFilterMatches(lead.open_now, filters.open_now)) {
      return false;
    }

    const rating = numberOrNull(lead.rating);
    const ratingMin = numberOrNull(filters.rating_min);
    if (ratingMin !== null && (rating === null || rating < ratingMin)) {
      return false;
    }

    const ratingMax = numberOrNull(filters.rating_max);
    if (ratingMax !== null && (rating === null || rating > ratingMax)) {
      return false;
    }

    const reviewsMin = numberOrNull(filters.reviews_min);
    if (reviewsMin !== null && Number(lead.reviews_count || 0) < reviewsMin) {
      return false;
    }

    const searchRankMax = numberOrNull(filters.search_rank_max);
    if (
      searchRankMax !== null &&
      (!lead.search_rank || Number(lead.search_rank) > searchRankMax)
    ) {
      return false;
    }

    return true;
  });

export const activeAdvancedLeadFiltersCount = filters =>
  Object.values(filters).filter(value => value !== '' && value !== null).length;
