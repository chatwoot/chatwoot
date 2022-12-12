function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

/* eslint-disable import/no-unresolved */
import { addDecorator, addParameters, addLoader, addArgs, addArgTypes, addArgsEnhancer, addArgTypesEnhancer, setGlobalRender } from '{{clientApi}}';
import * as config from '{{configFilename}}';
Object.keys(config).forEach(function (key) {
  var value = config[key];

  switch (key) {
    case 'args':
      {
        return addArgs(value);
      }

    case 'argTypes':
      {
        return addArgTypes(value);
      }

    case 'decorators':
      {
        return value.forEach(function (decorator) {
          return addDecorator(decorator, false);
        });
      }

    case 'loaders':
      {
        return value.forEach(function (loader) {
          return addLoader(loader, false);
        });
      }

    case 'parameters':
      {
        return addParameters(_objectSpread({}, value), false);
      }

    case 'argTypesEnhancers':
      {
        return value.forEach(function (enhancer) {
          return addArgTypesEnhancer(enhancer);
        });
      }

    case 'argsEnhancers':
      {
        return value.forEach(function (enhancer) {
          return addArgsEnhancer(enhancer);
        });
      }

    case 'render':
      {
        return setGlobalRender(value);
      }

    case 'globals':
    case 'globalTypes':
      {
        var v = {};
        v[key] = value;
        return addParameters(v, false);
      }

    case '__namedExportsOrder':
    case 'decorateStory':
    case 'renderToDOM':
      {
        return null; // This key is not handled directly in v6 mode.
      }

    default:
      {
        // eslint-disable-next-line prefer-template
        return console.log(key + ' was not supported :( !');
      }
  }
});