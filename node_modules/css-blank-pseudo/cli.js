#!/usr/bin/env node

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var fs = _interopDefault(require('fs'));
var postcss = _interopDefault(require('postcss'));

const selectorRegExp = /:blank([^\w-]|$)/gi;
var plugin = postcss.plugin('css-blank-pseudo', opts => {
  const replaceWith = String(Object(opts).replaceWith || '[blank]');
  const preserve = Boolean('preserve' in Object(opts) ? opts.preserve : true);
  return root => {
    root.walkRules(selectorRegExp, rule => {
      const selector = rule.selector.replace(selectorRegExp, ($0, $1) => {
        return `${replaceWith}${$1}`;
      });
      const clone = rule.clone({
        selector
      });

      if (preserve) {
        rule.before(clone);
      } else {
        rule.replaceWith(clone);
      }
    });
  };
});

if (process.argv.length < 3) {
  console.log(['CSS Blank Pseudo\n', '  Transforms CSS with :blank {}\n', 'Usage:\n', '  css-blank-pseudo source.css transformed.css', '  css-blank-pseudo --in=source.css --out=transformed.css --opts={}', '  echo "@media (prefers-color-scheme: dark) {}" | css-blank-pseudo\n'].join('\n'));
  process.exit(0);
} // get process and plugin options from the command line


const fileRegExp = /^[\w\/.]+$/;
const argRegExp = /^--(\w+)=("|')?(.+)\2$/;
const relaxedJsonPropRegExp = /(['"])?([a-z0-9A-Z_]+)(['"])?:/g;
const relaxedJsonValueRegExp = /("[a-z0-9A-Z_]+":\s*)'?([A-z0-9]+)'?([,}])/g;
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
}).then(result => {
  console.log(result);
  process.exit(0);
}, error => {
  console.error(error);
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
