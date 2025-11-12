import { from } from './list';

export const findChildren = (element, name) =>
  from(element.childNodes).filter(({tagName}) => tagName === name);

export const getContent = element => element.textContent.trim();
