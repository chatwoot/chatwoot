import global from 'global';
import qs from 'qs';
import { addons, makeDecorator } from '@storybook/addons';
import { STORY_CHANGED, SELECT_STORY } from '@storybook/core-events';
import { toId } from '@storybook/csf';
import { PARAM_KEY } from './constants';
const {
  document,
  HTMLElement
} = global;
export const navigate = params => addons.getChannel().emit(SELECT_STORY, params);
export const hrefTo = (title, name) => {
  return new Promise(resolve => {
    const {
      location
    } = document;
    const query = qs.parse(location.search, {
      ignoreQueryPrefix: true
    });
    const existingId = [].concat(query.id)[0];
    const titleToLink = title || existingId.split('--', 2)[0];
    const id = toId(titleToLink, name);
    const url = `${location.origin + location.pathname}?${qs.stringify(Object.assign({}, query, {
      id
    }), {
      encode: false
    })}`;
    resolve(url);
  });
};

const valueOrCall = args => value => typeof value === 'function' ? value(...args) : value;

export const linkTo = (idOrTitle, nameInput) => (...args) => {
  const resolver = valueOrCall(args);
  const title = resolver(idOrTitle);
  const name = resolver(nameInput);

  if (title !== null && title !== void 0 && title.match(/--/) && !name) {
    navigate({
      storyId: title
    });
  } else {
    navigate({
      kind: title,
      story: name
    });
  }
};

const linksListener = e => {
  const {
    target
  } = e;

  if (!(target instanceof HTMLElement)) {
    return;
  }

  const element = target;
  const {
    sbKind: kind,
    sbStory: story
  } = element.dataset;

  if (kind || story) {
    e.preventDefault();
    navigate({
      kind,
      story
    });
  }
};

let hasListener = false;

const on = () => {
  if (!hasListener) {
    hasListener = true;
    document.addEventListener('click', linksListener);
  }
};

const off = () => {
  if (hasListener) {
    hasListener = false;
    document.removeEventListener('click', linksListener);
  }
};

export const withLinks = makeDecorator({
  name: 'withLinks',
  parameterName: PARAM_KEY,
  wrapper: (getStory, context) => {
    on();
    addons.getChannel().once(STORY_CHANGED, off);
    return getStory(context);
  }
});