#ifndef SASS_FILE_H
#define SASS_FILE_H

// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include <string>
#include <vector>

#include "sass/context.h"
#include "ast_fwd_decl.hpp"

namespace Sass {

  namespace File {

    // return the current directory
    // always with forward slashes
    sass::string get_cwd();

    // test if path exists and is a file
    bool file_exists(const sass::string& file);

    // return if given path is absolute
    // works with *nix and windows paths
    bool is_absolute_path(const sass::string& path);

    // return only the directory part of path
    sass::string dir_name(const sass::string& path);

    // return only the filename part of path
    sass::string base_name(const sass::string&);

    // do a locigal clean up of the path
    // no physical check on the filesystem
    sass::string make_canonical_path (sass::string path);

    // join two path segments cleanly together
    // but only if right side is not absolute yet
    sass::string join_paths(sass::string root, sass::string name);

    // if the relative path is outside of the cwd we want want to
    // show the absolute path in console messages
    sass::string path_for_console(const sass::string& rel_path, const sass::string& abs_path, const sass::string& orig_path);

    // create an absolute path by resolving relative paths with cwd
    sass::string rel2abs(const sass::string& path, const sass::string& base = ".", const sass::string& cwd = get_cwd());

    // create a path that is relative to the given base directory
    // path and base will first be resolved against cwd to make them absolute
    sass::string abs2rel(const sass::string& path, const sass::string& base = ".", const sass::string& cwd = get_cwd());

    // helper function to resolve a filename
    // searching without variations in all paths
    sass::string find_file(const sass::string& file, struct Sass_Compiler* options);
    sass::string find_file(const sass::string& file, const sass::vector<sass::string> paths);

    // helper function to resolve a include filename
    // this has the original resolve logic for sass include
    sass::string find_include(const sass::string& file, const sass::vector<sass::string> paths);

    // split a path string delimited by semicolons or colons (OS dependent)
    sass::vector<sass::string> split_path_list(const char* paths);

    // try to load the given filename
    // returned memory must be freed
    // will auto convert .sass files
    char* read_file(const sass::string& file);

  }

  // requested import
  class Importer {
    public:
      // requested import path
      sass::string imp_path;
      // parent context path
      sass::string ctx_path;
      // base derived from context path
      // this really just acts as a cache
      sass::string base_path;
    public:
      Importer(sass::string imp_path, sass::string ctx_path)
      : imp_path(File::make_canonical_path(imp_path)),
        ctx_path(File::make_canonical_path(ctx_path)),
        base_path(File::dir_name(ctx_path))
      { }
  };

  // a resolved include (final import)
  class Include : public Importer {
    public:
      // resolved absolute path
      sass::string abs_path;
    public:
      Include(const Importer& imp, sass::string abs_path)
      : Importer(imp), abs_path(abs_path)
      { }
  };

  // a loaded resource
  class Resource {
    public:
      // the file contents
      char* contents;
      // connected sourcemap
      char* srcmap;
    public:
      Resource(char* contents, char* srcmap)
      : contents(contents), srcmap(srcmap)
      { }
  };

  namespace File {

    sass::vector<Include> resolve_includes(const sass::string& root, const sass::string& file,
      const sass::vector<sass::string>& exts = { ".scss", ".sass", ".css" });

  }

}

#endif
