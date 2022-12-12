#!/usr/bin/env node

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var fs = _interopDefault(require('fs'));
var parser = _interopDefault(require('postcss-selector-parser'));
var postcss = _interopDefault(require('postcss'));

const selectorRegExp = /:has/;
var plugin = postcss.plugin('css-has-pseudo', opts => {
  const preserve = Boolean('preserve' in Object(opts) ? opts.preserve : true);
  return root => {
    root.walkRules(selectorRegExp, rule => {
      const modifiedSelector = parser(selectors => {
        selectors.walkPseudos(selector => {
          if (selector.value === ':has' && selector.nodes) {
            const isNotHas = checkIfParentIsNot(selector);
            selector.value = isNotHas ? ':not-has' : ':has';
            const attribute = parser.attribute({
              attribute: encodeURIComponent(String(selector)).replace(/%3A/g, ':').replace(/%5B/g, '[').replace(/%5D/g, ']').replace(/%2C/g, ',').replace(/[():%\[\],]/g, '\\$&')
            });

            if (isNotHas) {
              selector.parent.parent.replaceWith(attribute);
            } else {
              selector.replaceWith(attribute);
            }
          }
        });
      }).processSync(rule.selector);
      const clone = rule.clone({
        selector: modifiedSelector
      });

      if (preserve) {
        rule.before(clone);
      } else {
        rule.replaceWith(clone);
      }
    });
  };
});

function checkIfParentIsNot(selector) {
  return Object(Object(selector.parent).parent).type === 'pseudo' && selector.parent.parent.value === ':not';
}

const fileRegExp = /^[\w\/.]+$/;
const argRegExp = /^--(\w+)=("|')?(.+)\2$/;
const relaxedJsonPropRegExp = /(['"])?([a-z0-9A-Z_]+)(['"])?:/g;
const relaxedJsonValueRegExp = /("[a-z0-9A-Z_]+":\s*)(?!true|false|null|\d+)'?([A-z0-9]+)'?([,}])/g;
const argo = process.argv.slice(2).reduce((object, arg) => {
  const argMatch = arg.match(argRegExp);
  const fileMatch = arg.match(fileRegExp);

  if (argMatch) {
    object[argMatch[1]] = argMatch[3];
  } else if (fileMatch) {
    if (object.from === '<stdin>') {
      object.from = arg;
    } else if (object.to === '<stdout>') {
      object.to = arg;
    }
  }

  return object;
}, {
  from: '<stdin>',
  to: '<stdout>',
  opts: 'null'
}); // get css from command line arguments or stdin

(argo.from === '<stdin>' ? getStdin() : readFile(argo.from)).then(css => {
  if (argo.from === '<stdin>' && !css) {
    console.log(['CSS Has Pseudo\n', '  Transforms CSS with :has {}\n', 'Usage:\n', '  css-has-pseudo source.css transformed.css', '  css-has-pseudo --from=source.css --to=transformed.css --opts={}', '  echo "body:has(:focus) {}" | css-has-pseudo\n'].join('\n'));
    process.exit(0);
  }

  const pluginOpts = JSON.parse(argo.opts.replace(relaxedJsonPropRegExp, '"$2": ').replace(relaxedJsonValueRegExp, '$1"$2"$3'));
  const processOptions = Object.assign({
    from: argo.from,
    to: argo.to || argo.from
  }, argo.map ? {
    map: JSON.parse(argo.map)
  } : {});
  const result = plugin.process(css, processOptions, pluginOpts);

  if (argo.to === '<stdout>') {
    return result.css;
  } else {
    return writeFile(argo.to, result.css).then(() => `CSS was written to "${argo.to}"`);
  }
}).catch(error => {
  if (Object(error).name === 'CssSyntaxError') {
    throw new Error(`PostCSS had trouble reading the file (${error.reason} on line ${error.line}, column ${error.column}).`);
  }

  if (Object(error).errno === -2) {
    throw new Error(`Sorry, "${error.path}" could not be read.`);
  }

  throw error;
}).then(result => {
  console.log(result);
  process.exit(0);
}, error => {
  console.error(Object(error).message || 'Something bad happened and we don’t even know what it was.');
  process.exit(1);
});

function readFile(pathname) {
  return new Promise((resolve, reject) => {
    fs.readFile(pathname, 'utf8', (error, data) => {
      if (error) {
        reject(error);
      } else {
        resolve(data);
      }
    });
  });
}

function writeFile(pathname, data) {
  return new Promise((resolve, reject) => {
    fs.writeFile(pathname, data, (error, content) => {
      if (error) {
        reject(error);
      } else {
        resolve(content);
      }
    });
  });
}

function getStdin() {
  return new Promise(resolve => {
    let data = '';

    if (process.stdin.isTTY) {
      resolve(data);
    } else {
      process.stdin.setEncoding('utf8');
      process.stdin.on('readable', () => {
        let chunk;

        while (chunk = process.stdin.read()) {
          data += chunk;
        }
      });
      process.stdin.on('end', () => {
        resolve(data);
      });
    }
  });
}
