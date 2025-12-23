#include "../sass.hpp"
#include <iostream>
#include <typeinfo>

#include "shared_ptr.hpp"
#include "../ast_fwd_decl.hpp"

#ifdef DEBUG_SHARED_PTR
#include "../debugger.hpp"
#endif

namespace Sass {

  #ifdef DEBUG_SHARED_PTR
  void SharedObj::dumpMemLeaks() {
    if (!all.empty()) {
      std::cerr << "###################################\n";
      std::cerr << "# REPORTING MISSING DEALLOCATIONS #\n";
      std::cerr << "###################################\n";
      for (SharedObj* var : all) {
        if (AST_Node* ast = dynamic_cast<AST_Node*>(var)) {
          debug_ast(ast);
        } else {
          std::cerr << "LEAKED " << var << "\n";
        }
      }
    }
  }
  sass::vector<SharedObj*> SharedObj::all;
  #endif

  bool SharedObj::taint = false;
}
