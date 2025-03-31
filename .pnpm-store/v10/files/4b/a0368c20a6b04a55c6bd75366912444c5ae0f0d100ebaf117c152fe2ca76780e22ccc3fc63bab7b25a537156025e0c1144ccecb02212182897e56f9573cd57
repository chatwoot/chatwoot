var fs = require('fs');
var path = require('path');
var _ = require('lodash');

let iconsIndex = [];

// Merge a `source` object to a `target` recursively
function merge(target, source) {
  // Check if font name is changed
  if (source['font-name']) {
    target['font-name'] = source['font-name'];
  }

  // Check if root dir is changed
  if (source['root-dir']) {
    target['root-dir'] = source['root-dir'];
  }

  // Check for icon changes
  if (source.icons) {
    for (let icon of source['icons']) {
      let index = iconsIndex.indexOf(icon.name);

      // Icon is replaced
      if (index !== -1) {
        target.icons[index] = icon;
      }
      // New icon is added
      else {
        target.icons.push(icon);
        iconsIndex.push(icon.name);
      }
    }
  }

  return target;
}

module.exports = function(grunt) {
  grunt.initConfig({
    sass: {
      dist: {
        files: {
          'css/videojs-icons.css': 'scss/videojs-icons.scss'
        }
      }
    },
    watch: {
      all: {
        files: ['**/*.hbs', '**/*.js', './icons.json'],
        tasks: ['default']
      }
    }
  });

  grunt.registerTask('generate-font', function() {
    var done = this.async();

    let webfontsGenerator = require('webfonts-generator');
    let iconConfig = grunt.file.readJSON(path.join(__dirname, '..', 'icons.json'));

    let svgRootDir = iconConfig['root-dir'];
    if (grunt.option('exclude-default')) {
      // Exclude default video.js icons
      iconConfig.icons = [];
    }
    let icons = iconConfig.icons;

    // Index default icons
    for (let i = 0; i < icons.length; i++) {
      iconsIndex.push(icons[i].name);
    }

    // Merge custom icons
    const paths = (grunt.option('custom-json') || '').split(',').filter(Boolean);
    for (let i = 0; i < paths.length; i++) {
      let customConfig = grunt.file.readJSON(path.resolve(process.cwd(), paths[i]));
      iconConfig = merge(iconConfig, customConfig);
    }

    icons = iconConfig.icons;

    let iconFiles = icons.map(function(icon) {
      // If root-dir is specified for a specific icon, use that.
      if (icon['root-dir']) {
        return icon['root-dir'] + icon.svg;
      }

      // Otherwise, use the default root-dir.
      return svgRootDir + icon.svg;
    });

    webfontsGenerator({
      files: iconFiles,
      dest: 'fonts/',
      fontName: iconConfig['font-name'],
      cssDest: 'scss/_icons.scss',
      cssTemplate: './templates/scss.hbs',
      htmlDest: 'index.html',
      htmlTemplate: './templates/html.hbs',
      html: true,
      rename: function(iconPath) {
        let fileName = path.basename(iconPath);

        let iconName = _.result(_.find(icons, function(icon) {
          let svgName = path.basename(icon.svg);

          return svgName === fileName;
        }), 'name');

        return iconName;
      },
      types: ['svg', 'woff', 'ttf']
    }, function(error) {
      if (error) {
        console.error(error);
        done(false);
      }

      done();
    });

  });

  grunt.registerTask('update-base64', function() {
    let iconScssFile = './scss/_icons.scss';
    let iconConfig;
    if (grunt.option('custom-json')) {
        iconConfig = grunt.file.readJSON(path.resolve(process.cwd(), grunt.option('custom-json')));
    } else {
        iconConfig = grunt.file.readJSON(path.join(__dirname, '..', 'icons.json'));
    }
    let fontName = iconConfig['font-name'];
    let fontFiles = {
      woff: './fonts/' + fontName + '.woff'
    };

    let scssContents = fs.readFileSync(iconScssFile).toString();

    Object.keys(fontFiles).forEach(function(font) {
      let fontFile = fontFiles[font];
      let fontContent = fs.readFileSync(fontFile);

      let regex = new RegExp(`(url.*font-${font}.*base64,)([^\\s]+)(\\).*)`);

      scssContents = scssContents.replace(regex, `$1${fontContent.toString('base64')}$3`);
    });

    fs.writeFileSync(iconScssFile, scssContents);
  });

  grunt.registerTask('default', ['generate-font', 'update-base64', 'sass']);
};
