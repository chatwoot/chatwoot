"use strict";

const clone = require('clone');

const docgen = require('vue-docgen-api');

const loaderUtils = require('loader-utils');

const qs = require('querystring');

const inject = require('./inject');

const {
  filterDescriptors
} = require('./utils');

const defaultOptions = {
  injectAt: '__docgenInfo'
};

module.exports = async function (content, map) {
  const callback = this.async();
  const queries = qs.parse(this.resourceQuery.slice(1)); // When vue-loader takes an input file (foo.vue), it calls itself multiple times
  // with same file with different queries. If there is 'vue' query, the import is
  // the 'indirect' one.

  if ('vue' in queries) {
    callback(null, content, map);
    return;
  }

  const ext = this.resourcePath.replace(/^[\s\S]*\.([^.]+)$/, '$1').toLowerCase();
  const isSFC = ext === 'vue';

  try {
    const options = { ...defaultOptions,
      ...(clone(loaderUtils.getOptions(this)) || {})
    }; // For SFCs, we can't use docgen.parseSource because the loader runs *after*
    // vue-loader. Since what we get in `content` is the code transpiled by
    // vue-loader, we need to read file to get the source code.

    const infoOrPromise = isSFC ? docgen.parse(this.resourcePath, options.docgenOptions) : attemptMultiParse(content, this.resourcePath, options.docgenOptions); // `parse` is async since vue-docgen-api@4.

    const allInfo = [].concat(infoOrPromise instanceof Promise ? await infoOrPromise : infoOrPromise);
    const filteredInfo = allInfo.map(info => {
      return { ...info,
        props: filterDescriptors(info.props, prop => !isIgnoredDescriptor(prop)),
        events: filterDescriptors(info.events, ev => !isIgnoredEvent(ev)),
        slots: filterDescriptors(info.slots, slot => !isIgnoredDescriptor(slot))
      };
    });
    callback(null, inject(content, filteredInfo, options.injectAt), map);
  } catch (e) {
    if (e instanceof Error) {
      e.message = '[vue-docgen-loader] failed to parse the component file with docgen-api: ' + e.message;
    }

    this.emitWarning(e);
    callback(null, content, map);
  }
};

function attemptMultiParse(content, path, options) {
  if (docgen.parseMulti) return docgen.parseMulti(path, options);else return docgen.parseSource(content, path, options);
}

function isIgnoredDescriptor(descriptor) {
  return descriptor.tags && descriptor.tags.ignore;
}

function isIgnoredEvent(eventDescriptor) {
  return eventDescriptor.tags && eventDescriptor.tags instanceof Array && eventDescriptor.tags.find(t => t.title === 'ignore');
}