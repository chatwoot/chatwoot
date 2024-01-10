import wootConstants from 'dashboard/constants/globals';
import wootAPI from './apiClient';

export const getTestimonialContent = () => {
  return wootAPI.get(wootConstants.TESTIMONIAL_URL);
};
