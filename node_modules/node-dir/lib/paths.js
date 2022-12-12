var fs = require('fs'),
    path = require('path');

exports.promiseFiles = function promiseFiles(dir, type, options){
  type = type || 'file'

  var processor = function(res,rej){
    var cb = function(err,data){
      if(err)return rej(err)
      res(data)
    }
    exports.files(dir,type,cb,options)
  }
  return new Promise(processor)
}

/**
 * find all files or subdirs (recursive) and pass to callback fn
 *
 * @param {string} dir directory in which to recurse files or subdirs
 * @param {string} type type of dir entry to recurse ('file', 'dir', or 'all', defaults to 'file')
 * @param {function(error, <Array.<string>)} callback fn to call when done
 * @example
 * dir.files(__dirname, function(err, files) {
 *      if (err) throw err;
 *      console.log('files:', files);
 *  });
 */
exports.files = function files(dir, type, callback, options) {
  var ofType = typeof type
  if(ofType == 'object'){
    options = options || type
    type = 'file'
    callback = function(){}
  }else if (ofType !== 'string') {
    //ignoreType = callback;
    callback = type;
    type = 'file';
  }
  
  options = options || {}

  var pending,
      results = {
          files: [],
          dirs: []
      };

  var done = function() {
    if(type==='combine'){
      results = results.files.concat(results.dirs)
    } else if (!type || options.ignoreType || ['all','combine'].indexOf(type)>=0) {
        results = results
    } else {
      results = results[type + 's']
    }

    if(options.sync)return;


    callback(null, results);
  };

  var getStatHandler = function(statPath, name, lstatCalled) {
    return function(err, stat) {
      if (err) {
        if (!lstatCalled) {
          return fs.lstat(statPath, getStatHandler(statPath, name, true));
        }
        return callback(err);
      }

      var pushVal = options.shortName ? name : statPath

      if (stat && stat.isDirectory() && stat.mode !== 17115) {
        if (type !== 'file') {
          results.dirs.push(pushVal);
        }

        if (options.recursive==null || options.recursive) {
          var subloop = function(err, res) {
            if (err){
                return callback(err)
            }
            
            if(type === 'combine'){
              results.files = results.files.concat(res);
            }else if (type === 'all') {
              results.files = results.files.concat(res.files);
              results.dirs = results.dirs.concat(res.dirs);
            } else if (type === 'file') {
                results.files = results.files.concat(res.files);
            } else {
                results.dirs = results.dirs.concat(res.dirs);
            }

            if (!--pending){
              done();
            }
          }

          var newOptions = Object.assign({}, options)
          newOptions.ignoreType = true
          var moreResults = files(statPath, type, subloop, newOptions);

          if(options.sync){
            subloop(null, moreResults)
          }
        }else if (!--pending){
          done()
        }
      } else {
        if (type !== 'dir') {
          results.files.push(pushVal);
        }
        // should be the last statement in statHandler
        if (!--pending){
          done()
        }
      }
    }
  }

  var bufdir = Buffer.from(dir);

  const onDirRead = function(err, list) {
    if (err) return callback(err);
    
    pending = list.length;
    if (!pending) return done();
    
    for (var file, i = 0, l = list.length; i < l; i++) {
      var fname = list[i].toString();
      file = path.join(dir, fname);
      var buffile = Buffer.concat([bufdir, Buffer.from(path.sep), list[i]]);

      if(options.sync){
        var res = fs.statSync(buffile);
        getStatHandler(file,fname)(null, res)
      }else{
        fs.stat(buffile, getStatHandler(file,fname));
      }
    }

    return results
  }

  const onStat = function(err, stat) {
    if (err) return callback(err);
    if (stat && stat.mode === 17115) return done();

    if(options.sync){
      const list = fs.readdirSync(bufdir, {encoding: 'buffer'})
      return onDirRead(null, list)
    }else{
      fs.readdir(bufdir, {encoding: 'buffer'}, onDirRead)
    }
  }

  if(options.sync){
    const stat = fs.statSync(bufdir);
    return onStat(null, stat)
  }else{
    fs.stat(bufdir, onStat);
  }
};


/**
 * find all files and subdirs in  a directory (recursive) and pass them to callback fn
 *
 * @param {string} dir directory in which to recurse files or subdirs
 * @param {boolean} combine whether to combine both subdirs and filepaths into one array (default false)
 * @param {function(error, Object.<<Array.<string>, Array.<string>>)} callback fn to call when done
 * @example
 * dir.paths(__dirname, function (err, paths) {
 *     if (err) throw err;
 *     console.log('files:', paths.files);
 *     console.log('subdirs:', paths.dirs);
 * });
 * dir.paths(__dirname, true, function (err, paths) {
 *      if (err) throw err;
 *      console.log('paths:', paths);
 * });
 */
exports.paths = function paths(dir, combine, callback) {

    var type;

    if (typeof combine === 'function') {
        callback = combine;
        combine = false;
    }

    exports.files(dir, 'all', function(err, results) {
        if (err) return callback(err);
        if (combine) {

            callback(null, results.files.concat(results.dirs));
        } else {
            callback(null, results);
        }
    });
};


/**
 * find all subdirs (recursive) of a directory and pass them to callback fn
 *
 * @param {string} dir directory in which to find subdirs
 * @param {string} type type of dir entry to recurse ('file' or 'dir', defaults to 'file')
 * @param {function(error, <Array.<string>)} callback fn to call when done
 * @example
 * dir.subdirs(__dirname, function (err, paths) {
 *      if (err) throw err;
 *      console.log('files:', paths.files);
 *      console.log('subdirs:', paths.dirs);
 * });
 */
exports.subdirs = function subdirs(dir, callback, type, options) {
  options = options || {}

  const iCallback = function(err, subdirs) {
    if (err) return callback(err);

    if(type=='combine'){
      subdirs = subdirs.files.concat(subdirs.dirs)
    }
    
    if(options.sync)return subdirs

    callback(null, subdirs);
  }

  const res = exports.files(dir, 'dir', iCallback, options)

  if(options && options.sync){
    return iCallback(null,res)
  }
};
