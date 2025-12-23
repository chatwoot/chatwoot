#ifndef SASS_CONTEXT_H
#define SASS_CONTEXT_H

// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"
#include "ast.hpp"


#define BUFFERSIZE 255
#include "b64/encode.h"

#include "sass_context.hpp"
#include "stylesheet.hpp"
#include "plugins.hpp"
#include "output.hpp"

namespace Sass {

  class Context {
  public:
    void import_url (Import* imp, sass::string load_path, const sass::string& ctx_path);
    bool call_headers(const sass::string& load_path, const char* ctx_path, SourceSpan& pstate, Import* imp)
    { return call_loader(load_path, ctx_path, pstate, imp, c_headers, false); };
    bool call_importers(const sass::string& load_path, const char* ctx_path, SourceSpan& pstate, Import* imp)
    { return call_loader(load_path, ctx_path, pstate, imp, c_importers, true); };

  private:
    bool call_loader(const sass::string& load_path, const char* ctx_path, SourceSpan& pstate, Import* imp, sass::vector<Sass_Importer_Entry> importers, bool only_one = true);

  public:
    const sass::string CWD;
    struct Sass_Options& c_options;
    sass::string entry_path;
    size_t head_imports;
    Plugins plugins;
    Output emitter;

    // generic ast node garbage container
    // used to avoid possible circular refs
    CallStack ast_gc;
    // resources add under our control
    // these are guaranteed to be freed
    sass::vector<char*> strings;
    sass::vector<Resource> resources;
    std::map<const sass::string, StyleSheet> sheets;
    ImporterStack import_stack;
    sass::vector<Sass_Callee> callee_stack;
    sass::vector<Backtrace> traces;
    Extender extender;

    struct Sass_Compiler* c_compiler;

    // absolute paths to includes
    sass::vector<sass::string> included_files;
    // relative includes for sourcemap
    sass::vector<sass::string> srcmap_links;
    // vectors above have same size

    sass::vector<sass::string> plugin_paths; // relative paths to load plugins
    sass::vector<sass::string> include_paths; // lookup paths for includes

    void apply_custom_headers(Block_Obj root, const char* path, SourceSpan pstate);

    sass::vector<Sass_Importer_Entry> c_headers;
    sass::vector<Sass_Importer_Entry> c_importers;
    sass::vector<Sass_Function_Entry> c_functions;

    void add_c_header(Sass_Importer_Entry header);
    void add_c_importer(Sass_Importer_Entry importer);
    void add_c_function(Sass_Function_Entry function);

    const sass::string indent; // String to be used for indentation
    const sass::string linefeed; // String to be used for line feeds
    const sass::string input_path; // for relative paths in src-map
    const sass::string output_path; // for relative paths to the output
    const sass::string source_map_file; // path to source map file (enables feature)
    const sass::string source_map_root; // path for sourceRoot property (pass-through)

    virtual ~Context();
    Context(struct Sass_Context&);
    virtual Block_Obj parse() = 0;
    virtual Block_Obj compile();
    virtual char* render(Block_Obj root);
    virtual char* render_srcmap();

    void register_resource(const Include&, const Resource&);
    void register_resource(const Include&, const Resource&, SourceSpan&);
    sass::vector<Include> find_includes(const Importer& import);
    Include load_import(const Importer&, SourceSpan pstate);

    Sass_Output_Style output_style() { return c_options.output_style; };
    sass::vector<sass::string> get_included_files(bool skip = false, size_t headers = 0);

  private:
    void collect_plugin_paths(const char* paths_str);
    void collect_plugin_paths(string_list* paths_array);
    void collect_include_paths(const char* paths_str);
    void collect_include_paths(string_list* paths_array);
    sass::string format_embedded_source_map();
    sass::string format_source_mapping_url(const sass::string& out_path);


    // void register_built_in_functions(Env* env);
    // void register_function(Signature sig, Native_Function f, Env* env);
    // void register_function(Signature sig, Native_Function f, size_t arity, Env* env);
    // void register_overload_stub(sass::string name, Env* env);

  public:
    const sass::string& cwd() { return CWD; };
  };

  class File_Context : public Context {
  public:
    File_Context(struct Sass_File_Context& ctx)
    : Context(ctx)
    { }
    virtual ~File_Context();
    virtual Block_Obj parse();
  };

  class Data_Context : public Context {
  public:
    char* source_c_str;
    char* srcmap_c_str;
    Data_Context(struct Sass_Data_Context& ctx)
    : Context(ctx)
    {
      source_c_str       = ctx.source_string;
      srcmap_c_str       = ctx.srcmap_string;
      ctx.source_string = 0; // passed away
      ctx.srcmap_string = 0; // passed away
    }
    virtual ~Data_Context();
    virtual Block_Obj parse();
  };

}

#endif
