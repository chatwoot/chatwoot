/* global axios */
import wootConstants from 'dashboard/constants/globals';

export const getTestimonialContent = () => {
  return axios.get(wootConstants.TESTIMONIAL_URL);
};
