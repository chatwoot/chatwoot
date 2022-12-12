import global from 'global';
import { parse } from 'qs';
const {
  document
} = global;
export const getQueryParams = () => {
  // document.location is not defined in react-native
  if (document && document.location && document.location.search) {
    return parse(document.location.search, {
      ignoreQueryPrefix: true
    });
  }

  return {};
};
export const getQueryParam = key => {
  const params = getQueryParams();
  return params[key];
};