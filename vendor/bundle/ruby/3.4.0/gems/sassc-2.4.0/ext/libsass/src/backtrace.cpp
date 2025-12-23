#include "backtrace.hpp"

namespace Sass {

  const sass::string traces_to_string(Backtraces traces, sass::string indent) {

    sass::ostream ss;
    sass::string cwd(File::get_cwd());

    bool first = true;
    size_t i_beg = traces.size() - 1;
    size_t i_end = sass::string::npos;
    for (size_t i = i_beg; i != i_end; i --) {

      const Backtrace& trace = traces[i];

      // make path relative to the current directory
      sass::string rel_path(File::abs2rel(trace.pstate.getPath(), cwd, cwd));

      // skip functions on error cases (unsure why ruby sass does this)
      // if (trace.caller.substr(0, 6) == ", in f") continue;

      if (first) {
        ss << indent;
        ss << "on line ";
        ss << trace.pstate.getLine();
        ss << ":";
        ss << trace.pstate.getColumn();
        ss << " of " << rel_path;
        // ss << trace.caller;
        first = false;
      } else {
        ss << trace.caller;
        ss << std::endl;
        ss << indent;
        ss << "from line ";
        ss << trace.pstate.getLine();
        ss << ":";
        ss << trace.pstate.getColumn();
        ss << " of " << rel_path;
      }

    }

    ss << std::endl;
    return ss.str();

  }

};
