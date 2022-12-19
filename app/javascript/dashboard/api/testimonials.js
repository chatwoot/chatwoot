/* global axios */
import wootConstants from 'dashboard/constants';

export const getTestimonialContent = () => {
  return axios.get(wootConstants.TESTIMONIAL_URL);
};
