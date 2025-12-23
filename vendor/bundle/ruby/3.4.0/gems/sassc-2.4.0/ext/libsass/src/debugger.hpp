#ifndef SASS_DEBUGGER_H
#define SASS_DEBUGGER_H

// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include <queue>
#include <vector>
#include <string>
#include <sstream>
#include "ast.hpp"
#include "ast_fwd_decl.hpp"
#include "extension.hpp"

#include "ordered_map.hpp"

using namespace Sass;

inline void debug_ast(AST_Node* node, sass::string ind = "", Env* env = 0);

inline sass::string debug_vec(const AST_Node* node) {
  if (node == NULL) return "null";
  else return node->to_string();
}

inline sass::string debug_dude(sass::vector<sass::vector<int>> vec) {
  sass::sstream out;
  out << "{";
  bool joinOut = false;
  for (auto ct : vec) {
    if (joinOut) out << ", ";
    joinOut = true;
    out << "{";
    bool joinIn = false;
    for (auto nr : ct) {
      if (joinIn) out << ", ";
      joinIn = true;
      out << nr;
    }
    out << "}";
  }
  out << "}";
  return out.str();
}

inline sass::string debug_vec(sass::string& str) {
  return str;
}

inline sass::string debug_vec(Extension& ext) {
  sass::sstream out;
  out << debug_vec(ext.extender);
  out << " {@extend ";
  out << debug_vec(ext.target);
  if (ext.isOptional) {
    out << " !optional";
  }
  out << "}";
  return out.str();
}

template <class T>
inline sass::string debug_vec(sass::vector<T> vec) {
  sass::sstream out;
  out << "[";
  for (size_t i = 0; i < vec.size(); i += 1) {
    if (i > 0) out << ", ";
    out << debug_vec(vec[i]);
  }
  out << "]";
  return out.str();
}

template <class T>
inline sass::string debug_vec(std::queue<T> vec) {
  sass::sstream out;
  out << "{";
  for (size_t i = 0; i < vec.size(); i += 1) {
    if (i > 0) out << ", ";
    out << debug_vec(vec[i]);
  }
  out << "}";
  return out.str();
}

template <class T, class U, class O>
inline sass::string debug_vec(std::map<T, U, O> vec) {
  sass::sstream out;
  out << "{";
  bool joinit = false;
  for (auto it = vec.begin(); it != vec.end(); it++)
  {
    if (joinit) out << ", ";
    out << debug_vec(it->first) // string (key)
      << ": "
      << debug_vec(it->second); // string's value
    joinit = true;
  }
  out << "}";
  return out.str();
}

template <class T, class U, class O, class V>
inline sass::string debug_vec(const ordered_map<T, U, O, V>& vec) {
  sass::sstream out;
  out << "{";
  bool joinit = false;
  for (auto it = vec.begin(); it != vec.end(); it++)
  {
    if (joinit) out << ", ";
    out << debug_vec(*it); // string (key)
    // << debug_vec(it->second); // string's value
    joinit = true;
  }
  out << "}";
  return out.str();
}

template <class T, class U, class O, class V>
inline sass::string debug_vec(std::unordered_map<T, U, O, V> vec) {
  sass::sstream out;
  out << "{";
  bool joinit = false;
  for (auto it = vec.begin(); it != vec.end(); it++)
  {
    if (joinit) out << ", ";
    out << debug_vec(it->first) // string (key)
      << ": "
      << debug_vec(it->second); // string's value
    joinit = true;
  }
  out << "}";
  return out.str();
}

template <class T, class U, class O, class V>
inline sass::string debug_keys(std::unordered_map<T, U, O, V> vec) {
  sass::sstream out;
  out << "{";
  bool joinit = false;
  for (auto it = vec.begin(); it != vec.end(); it++)
  {
    if (joinit) out << ", ";
    out << debug_vec(it->first); // string (key)
    joinit = true;
  }
  out << "}";
  return out.str();
}

inline sass::string debug_vec(ExtListSelSet& vec) {
  sass::sstream out;
  out << "{";
  bool joinit = false;
  for (auto it = vec.begin(); it != vec.end(); it++)
  {
    if (joinit) out << ", ";
    out << debug_vec(*it); // string (key)
    joinit = true;
  }
  out << "}";
  return out.str();
}

/*
template <class T, class U, class O, class V>
inline sass::string debug_values(tsl::ordered_map<T, U, O, V> vec) {
  sass::sstream out;
  out << "{";
  bool joinit = false;
  for (auto it = vec.begin(); it != vec.end(); it++)
  {
    if (joinit) out << ", ";
    out << debug_vec(const_cast<U&>(it->second)); // string's value
    joinit = true;
  }
  out << "}";
  return out.str();
}
 
template <class T, class U, class O, class V>
inline sass::string debug_vec(tsl::ordered_map<T, U, O, V> vec) {
  sass::sstream out;
  out << "{";
  bool joinit = false;
  for (auto it = vec.begin(); it != vec.end(); it++)
  {
    if (joinit) out << ", ";
    out << debug_vec(it->first) // string (key)
      << ": "
      << debug_vec(const_cast<U&>(it->second)); // string's value
    joinit = true;
  }
  out << "}";
  return out.str();
}

template <class T, class U, class O, class V>
inline sass::string debug_vals(tsl::ordered_map<T, U, O, V> vec) {
  sass::sstream out;
  out << "{";
  bool joinit = false;
  for (auto it = vec.begin(); it != vec.end(); it++)
  {
    if (joinit) out << ", ";
    out << debug_vec(const_cast<U&>(it->second)); // string's value
    joinit = true;
  }
  out << "}";
  return out.str();
}

template <class T, class U, class O, class V>
inline sass::string debug_keys(tsl::ordered_map<T, U, O, V> vec) {
  sass::sstream out;
  out << "{";
  bool joinit = false;
  for (auto it = vec.begin(); it != vec.end(); it++)
  {
    if (joinit) out << ", ";
    out << debug_vec(it->first);
    joinit = true;
  }
  out << "}";
  return out.str();
}
*/

template <class T, class U>
inline sass::string debug_vec(std::set<T, U> vec) {
  sass::sstream out;
  out << "{";
  bool joinit = false;
  for (auto item : vec) {
    if (joinit) out << ", ";
    out << debug_vec(item);
    joinit = true;
  }
  out << "}";
  return out.str();
}

/*
template <class T, class U, class O, class V>
inline sass::string debug_vec(tsl::ordered_set<T, U, O, V> vec) {
  sass::sstream out;
  out << "{";
  bool joinit = false;
  for (auto item : vec) {
    if (joinit) out << ", ";
    out << debug_vec(item);
    joinit = true;
  }
  out << "}";
  return out.str();
}
*/

template <class T, class U, class O, class V>
inline sass::string debug_vec(std::unordered_set<T, U, O, V> vec) {
  sass::sstream out;
  out << "{";
  bool joinit = false;
  for (auto item : vec) {
    if (joinit) out << ", ";
    out << debug_vec(item);
    joinit = true;
  }
  out << "}";
  return out.str();
}

inline sass::string debug_bool(bool val) {
  return val ? "true" : "false";
}
inline sass::string debug_vec(ExtSmplSelSet* node) {
  if (node == NULL) return "null";
  else return debug_vec(*node);
}

inline void debug_ast(const AST_Node* node, sass::string ind = "", Env* env = 0) {
  debug_ast(const_cast<AST_Node*>(node), ind, env);
}

inline sass::string str_replace(sass::string str, const sass::string& oldStr, const sass::string& newStr)
{
  size_t pos = 0;
  while((pos = str.find(oldStr, pos)) != sass::string::npos)
  {
     str.replace(pos, oldStr.length(), newStr);
     pos += newStr.length();
  }
  return str;
}

inline sass::string prettyprint(const sass::string& str) {
  sass::string clean = str_replace(str, "\n", "\\n");
  clean = str_replace(clean, "	", "\\t");
  clean = str_replace(clean, "\r", "\\r");
  return clean;
}

inline sass::string longToHex(long long t) {
  sass::sstream is;
  is << std::hex << t;
  return is.str();
}

inline sass::string pstate_source_position(AST_Node* node)
{
  sass::sstream str;
  Offset start(node->pstate().position);
  Offset end(start + node->pstate().offset);
  size_t file = node->pstate().getSrcId();
  str << (file == sass::string::npos ? 99999999 : file)
    << "@[" << start.line << ":" << start.column << "]"
    << "-[" << end.line << ":" << end.column << "]";
#ifdef DEBUG_SHARED_PTR
      str << "x" << node->getRefCount() << ""
      << " " << node->getDbgFile()
      << "@" << node->getDbgLine();
#endif
  return str.str();
}

inline void debug_ast(AST_Node* node, sass::string ind, Env* env)
{
  if (node == 0) return;
  if (ind == "") std::cerr << "####################################################################\n";
  if (Cast<Bubble>(node)) {
    Bubble* bubble = Cast<Bubble>(node);
    std::cerr << ind << "Bubble " << bubble;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << bubble->tabs();
    std::cerr << std::endl;
    debug_ast(bubble->node(), ind + " ", env);
  } else if (Cast<Trace>(node)) {
    Trace* trace = Cast<Trace>(node);
    std::cerr << ind << "Trace " << trace;
    std::cerr << " (" << pstate_source_position(node) << ")"
    << " [name:" << trace->name() << ", type: " << trace->type() << "]"
    << std::endl;
    debug_ast(trace->block(), ind + " ", env);
  } else if (Cast<AtRootRule>(node)) {
    AtRootRule* root_block = Cast<AtRootRule>(node);
    std::cerr << ind << "AtRootRule " << root_block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << root_block->tabs();
    std::cerr << std::endl;
    debug_ast(root_block->expression(), ind + ":", env);
    debug_ast(root_block->block(), ind + " ", env);
  } else if (Cast<SelectorList>(node)) {
    SelectorList* selector = Cast<SelectorList>(node);
    std::cerr << ind << "SelectorList " << selector;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " <" << selector->hash() << ">";
    std::cerr << (selector->is_invisible() ? " [is_invisible]" : " -");
    std::cerr << (selector->isInvisible() ? " [isInvisible]" : " -");
    std::cerr << (selector->has_real_parent_ref() ? " [real-parent]": " -");
    std::cerr << std::endl;

    for(const ComplexSelector_Obj& i : selector->elements()) { debug_ast(i, ind + " ", env); }

  } else if (Cast<ComplexSelector>(node)) {
    ComplexSelector* selector = Cast<ComplexSelector>(node);
    std::cerr << ind << "ComplexSelector " << selector
      << " (" << pstate_source_position(node) << ")"
      << " <" << selector->hash() << ">"
      << " [" << (selector->chroots() ? "CHROOT" : "CONNECT") << "]"
      << " [length:" << longToHex(selector->length()) << "]"
      << " [weight:" << longToHex(selector->specificity()) << "]"
      << (selector->is_invisible() ? " [is_invisible]" : " -")
      << (selector->isInvisible() ? " [isInvisible]" : " -")
      << (selector->hasPreLineFeed() ? " [hasPreLineFeed]" : " -")

      // << (selector->is_invisible() ? " [INVISIBLE]": " -")
      // << (selector->has_placeholder() ? " [PLACEHOLDER]": " -")
      // << (selector->is_optional() ? " [is_optional]": " -")
      << (selector->has_real_parent_ref() ? " [real parent]": " -")
      // << (selector->has_line_feed() ? " [line-feed]": " -")
      // << (selector->has_line_break() ? " [line-break]": " -")
      << " -- \n";

    for(const SelectorComponentObj& i : selector->elements()) { debug_ast(i, ind + " ", env); }

  } else if (Cast<SelectorCombinator>(node)) {
    SelectorCombinator* selector = Cast<SelectorCombinator>(node);
    std::cerr << ind << "SelectorCombinator " << selector
      << " (" << pstate_source_position(node) << ")"
      << " <" << selector->hash() << ">"
      << " [weight:" << longToHex(selector->specificity()) << "]"
      << (selector->has_real_parent_ref() ? " [real parent]": " -")
      << " -- ";

      sass::string del;
      switch (selector->combinator()) {
        case SelectorCombinator::CHILD:    del = ">"; break;
        case SelectorCombinator::GENERAL:  del = "~"; break;
        case SelectorCombinator::ADJACENT: del = "+"; break;
      }

      std::cerr << "[" << del << "]" << "\n";

  } else if (Cast<CompoundSelector>(node)) {
    CompoundSelector* selector = Cast<CompoundSelector>(node);
    std::cerr << ind << "CompoundSelector " << selector;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " <" << selector->hash() << ">";
    std::cerr << (selector->hasRealParent() ? " [REAL PARENT]" : "") << ">";
    std::cerr << " [weight:" << longToHex(selector->specificity()) << "]";
    std::cerr << (selector->hasPostLineBreak() ? " [hasPostLineBreak]" : " -");
    std::cerr << (selector->is_invisible() ? " [is_invisible]" : " -");
    std::cerr << (selector->isInvisible() ? " [isInvisible]" : " -");
    std::cerr << "\n";
    for(const SimpleSelector_Obj& i : selector->elements()) { debug_ast(i, ind + " ", env); }

  } else if (Cast<Parent_Reference>(node)) {
    Parent_Reference* selector = Cast<Parent_Reference>(node);
    std::cerr << ind << "Parent_Reference " << selector;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " <" << selector->hash() << ">";
    std::cerr << std::endl;

  } else if (Cast<PseudoSelector>(node)) {
    PseudoSelector* selector = Cast<PseudoSelector>(node);
    std::cerr << ind << "PseudoSelector " << selector;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " <" << selector->hash() << ">";
    std::cerr << " <<" << selector->ns_name() << ">>";
    std::cerr << (selector->isClass() ? " [isClass]": " -");
    std::cerr << (selector->isSyntacticClass() ? " [isSyntacticClass]": " -");
    std::cerr << std::endl;
    debug_ast(selector->argument(), ind + " <= ", env);
    debug_ast(selector->selector(), ind + " || ", env);
  } else if (Cast<AttributeSelector>(node)) {
    AttributeSelector* selector = Cast<AttributeSelector>(node);
    std::cerr << ind << "AttributeSelector " << selector;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " <" << selector->hash() << ">";
    std::cerr << " <<" << selector->ns_name() << ">>";
    std::cerr << std::endl;
    debug_ast(selector->value(), ind + "[" + selector->matcher() + "] ", env);
  } else if (Cast<ClassSelector>(node)) {
    ClassSelector* selector = Cast<ClassSelector>(node);
    std::cerr << ind << "ClassSelector " << selector;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " <" << selector->hash() << ">";
    std::cerr << " <<" << selector->ns_name() << ">>";
    std::cerr << std::endl;
  } else if (Cast<IDSelector>(node)) {
    IDSelector* selector = Cast<IDSelector>(node);
    std::cerr << ind << "IDSelector " << selector;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " <" << selector->hash() << ">";
    std::cerr << " <<" << selector->ns_name() << ">>";
    std::cerr << std::endl;
  } else if (Cast<TypeSelector>(node)) {
    TypeSelector* selector = Cast<TypeSelector>(node);
    std::cerr << ind << "TypeSelector " << selector;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " <" << selector->hash() << ">";
    std::cerr << " <<" << selector->ns_name() << ">>";
    std::cerr << std::endl;
  } else if (Cast<PlaceholderSelector>(node)) {

    PlaceholderSelector* selector = Cast<PlaceholderSelector>(node);
    std::cerr << ind << "PlaceholderSelector [" << selector->ns_name() << "] " << selector;
    std::cerr << " (" << pstate_source_position(selector) << ")"
      << " <" << selector->hash() << ">"
      << (selector->isInvisible() ? " [isInvisible]" : " -")
    << std::endl;

  } else if (Cast<SimpleSelector>(node)) {
    SimpleSelector* selector = Cast<SimpleSelector>(node);
    std::cerr << ind << "SimpleSelector " << selector;
    std::cerr << " (" << pstate_source_position(node) << ")";

  } else if (Cast<Selector_Schema>(node)) {
    Selector_Schema* selector = Cast<Selector_Schema>(node);
    std::cerr << ind << "Selector_Schema " << selector;
    std::cerr << " (" << pstate_source_position(node) << ")"
      << (selector->connect_parent() ? " [connect-parent]": " -")
    << std::endl;

    debug_ast(selector->contents(), ind + " ");
    // for(auto i : selector->elements()) { debug_ast(i, ind + " ", env); }

  } else if (Cast<Selector>(node)) {
    Selector* selector = Cast<Selector>(node);
    std::cerr << ind << "Selector " << selector;
    std::cerr << " (" << pstate_source_position(node) << ")"
    << std::endl;

  } else if (Cast<Media_Query_Expression>(node)) {
    Media_Query_Expression* block = Cast<Media_Query_Expression>(node);
    std::cerr << ind << "Media_Query_Expression " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << (block->is_interpolated() ? " [is_interpolated]": " -")
    << std::endl;
    debug_ast(block->feature(), ind + " feature) ");
    debug_ast(block->value(), ind + " value) ");

  } else if (Cast<Media_Query>(node)) {
    Media_Query* block = Cast<Media_Query>(node);
    std::cerr << ind << "Media_Query " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << (block->is_negated() ? " [is_negated]": " -")
      << (block->is_restricted() ? " [is_restricted]": " -")
    << std::endl;
    debug_ast(block->media_type(), ind + " ");
    for(const auto& i : block->elements()) { debug_ast(i, ind + " ", env); }
  }
  else if (Cast<MediaRule>(node)) {
    MediaRule* rule = Cast<MediaRule>(node);
    std::cerr << ind << "MediaRule " << rule;
    std::cerr << " (" << pstate_source_position(rule) << ")";
    std::cerr << " " << rule->tabs() << std::endl;
    debug_ast(rule->schema(), ind + " =@ ");
    debug_ast(rule->block(), ind + " ");
  }
  else if (Cast<CssMediaRule>(node)) {
    CssMediaRule* rule = Cast<CssMediaRule>(node);
    std::cerr << ind << "CssMediaRule " << rule;
    std::cerr << " (" << pstate_source_position(rule) << ")";
    std::cerr << " " << rule->tabs() << std::endl;
    for (auto item : rule->elements()) {
      debug_ast(item, ind + " == ");
    }
    debug_ast(rule->block(), ind + " ");
  }
  else if (Cast<CssMediaQuery>(node)) {
    CssMediaQuery* query = Cast<CssMediaQuery>(node);
    std::cerr << ind << "CssMediaQuery " << query;
    std::cerr << " (" << pstate_source_position(query) << ")";
    std::cerr << " [" << (query->modifier()) << "] ";
    std::cerr << " [" << (query->type()) << "] ";
    std::cerr << " " << debug_vec(query->features());
    std::cerr << std::endl;
  } else if (Cast<SupportsRule>(node)) {
    SupportsRule* block = Cast<SupportsRule>(node);
    std::cerr << ind << "SupportsRule " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << block->tabs() << std::endl;
    debug_ast(block->condition(), ind + " =@ ");
    debug_ast(block->block(), ind + " <>");
  } else if (Cast<SupportsOperation>(node)) {
    SupportsOperation* block = Cast<SupportsOperation>(node);
    std::cerr << ind << "SupportsOperation " << block;
    std::cerr << " (" << pstate_source_position(node) << ")"
    << std::endl;
    debug_ast(block->left(), ind + " left) ");
    debug_ast(block->right(), ind + " right) ");
  } else if (Cast<SupportsNegation>(node)) {
    SupportsNegation* block = Cast<SupportsNegation>(node);
    std::cerr << ind << "SupportsNegation " << block;
    std::cerr << " (" << pstate_source_position(node) << ")"
    << std::endl;
    debug_ast(block->condition(), ind + " condition) ");
  } else if (Cast<At_Root_Query>(node)) {
    At_Root_Query* block = Cast<At_Root_Query>(node);
    std::cerr << ind << "At_Root_Query " << block;
    std::cerr << " (" << pstate_source_position(node) << ")"
    << std::endl;
    debug_ast(block->feature(), ind + " feature) ");
    debug_ast(block->value(), ind + " value) ");
  } else if (Cast<SupportsDeclaration>(node)) {
    SupportsDeclaration* block = Cast<SupportsDeclaration>(node);
    std::cerr << ind << "SupportsDeclaration " << block;
    std::cerr << " (" << pstate_source_position(node) << ")"
    << std::endl;
    debug_ast(block->feature(), ind + " feature) ");
    debug_ast(block->value(), ind + " value) ");
  } else if (Cast<Block>(node)) {
    Block* root_block = Cast<Block>(node);
    std::cerr << ind << "Block " << root_block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    if (root_block->is_root()) std::cerr << " [root]";
    if (root_block->isInvisible()) std::cerr << " [isInvisible]";
    std::cerr << " " << root_block->tabs() << std::endl;
    for(const Statement_Obj& i : root_block->elements()) { debug_ast(i, ind + " ", env); }
  } else if (Cast<WarningRule>(node)) {
    WarningRule* block = Cast<WarningRule>(node);
    std::cerr << ind << "WarningRule " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << block->tabs() << std::endl;
    debug_ast(block->message(), ind + " : ");
  } else if (Cast<ErrorRule>(node)) {
    ErrorRule* block = Cast<ErrorRule>(node);
    std::cerr << ind << "ErrorRule " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << block->tabs() << std::endl;
  } else if (Cast<DebugRule>(node)) {
    DebugRule* block = Cast<DebugRule>(node);
    std::cerr << ind << "DebugRule " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << block->tabs() << std::endl;
    debug_ast(block->value(), ind + " ");
  } else if (Cast<Comment>(node)) {
    Comment* block = Cast<Comment>(node);
    std::cerr << ind << "Comment " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << block->tabs() << std::endl;
    debug_ast(block->text(), ind + "// ", env);
  } else if (Cast<If>(node)) {
    If* block = Cast<If>(node);
    std::cerr << ind << "If " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << block->tabs() << std::endl;
    debug_ast(block->predicate(), ind + " = ");
    debug_ast(block->block(), ind + " <>");
    debug_ast(block->alternative(), ind + " ><");
  } else if (Cast<Return>(node)) {
    Return* block = Cast<Return>(node);
    std::cerr << ind << "Return " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << block->tabs();
    std::cerr << " [" << block->value()->to_string() << "]" << std::endl;
  } else if (Cast<ExtendRule>(node)) {
    ExtendRule* block = Cast<ExtendRule>(node);
    std::cerr << ind << "ExtendRule " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << block->tabs() << std::endl;
    debug_ast(block->selector(), ind + "-> ", env);
  } else if (Cast<Content>(node)) {
    Content* block = Cast<Content>(node);
    std::cerr << ind << "Content " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << block->tabs() << std::endl;
    debug_ast(block->arguments(), ind + " args: ", env);
  } else if (Cast<Import_Stub>(node)) {
    Import_Stub* block = Cast<Import_Stub>(node);
    std::cerr << ind << "Import_Stub " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [" << block->imp_path() << "] ";
    std::cerr << " " << block->tabs() << std::endl;
  } else if (Cast<Import>(node)) {
    Import* block = Cast<Import>(node);
    std::cerr << ind << "Import " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << block->tabs() << std::endl;
    // sass::vector<sass::string>         files_;
    for (auto imp : block->urls()) debug_ast(imp, ind + "@: ", env);
    debug_ast(block->import_queries(), ind + "@@ ");
  } else if (Cast<Assignment>(node)) {
    Assignment* block = Cast<Assignment>(node);
    std::cerr << ind << "Assignment " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " <<" << block->variable() << ">> " << block->tabs() << std::endl;
    debug_ast(block->value(), ind + "=", env);
  } else if (Cast<Declaration>(node)) {
    Declaration* block = Cast<Declaration>(node);
    std::cerr << ind << "Declaration " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [is_custom_property: " << block->is_custom_property() << "] ";
    std::cerr << " " << block->tabs() << std::endl;
    debug_ast(block->property(), ind + " prop: ", env);
    debug_ast(block->value(), ind + " value: ", env);
    debug_ast(block->block(), ind + " ", env);
  } else if (Cast<Keyframe_Rule>(node)) {
    Keyframe_Rule* ParentStatement = Cast<Keyframe_Rule>(node);
    std::cerr << ind << "Keyframe_Rule " << ParentStatement;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << ParentStatement->tabs() << std::endl;
    if (ParentStatement->name()) debug_ast(ParentStatement->name(), ind + "@");
    if (ParentStatement->block()) for(const Statement_Obj& i : ParentStatement->block()->elements()) { debug_ast(i, ind + " ", env); }
  } else if (Cast<AtRule>(node)) {
    AtRule* block = Cast<AtRule>(node);
    std::cerr << ind << "AtRule " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [" << block->keyword() << "] " << block->tabs() << std::endl;
    debug_ast(block->selector(), ind + "~", env);
    debug_ast(block->value(), ind + "+", env);
    if (block->block()) for(const Statement_Obj& i : block->block()->elements()) { debug_ast(i, ind + " ", env); }
  } else if (Cast<EachRule>(node)) {
    EachRule* block = Cast<EachRule>(node);
    std::cerr << ind << "EachRule " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << block->tabs() << std::endl;
    if (block->block()) for(const Statement_Obj& i : block->block()->elements()) { debug_ast(i, ind + " ", env); }
  } else if (Cast<ForRule>(node)) {
    ForRule* block = Cast<ForRule>(node);
    std::cerr << ind << "ForRule " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << block->tabs() << std::endl;
    if (block->block()) for(const Statement_Obj& i : block->block()->elements()) { debug_ast(i, ind + " ", env); }
  } else if (Cast<WhileRule>(node)) {
    WhileRule* block = Cast<WhileRule>(node);
    std::cerr << ind << "WhileRule " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << block->tabs() << std::endl;
    if (block->block()) for(const Statement_Obj& i : block->block()->elements()) { debug_ast(i, ind + " ", env); }
  } else if (Cast<Definition>(node)) {
    Definition* block = Cast<Definition>(node);
    std::cerr << ind << "Definition " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [name: " << block->name() << "] ";
    std::cerr << " [type: " << (block->type() == Sass::Definition::Type::MIXIN ? "Mixin " : "Function ") << "] ";
    // this seems to lead to segfaults some times?
    // std::cerr << " [signature: " << block->signature() << "] ";
    std::cerr << " [native: " << block->native_function() << "] ";
    std::cerr << " " << block->tabs() << std::endl;
    debug_ast(block->parameters(), ind + " params: ", env);
    if (block->block()) debug_ast(block->block(), ind + " ", env);
  } else if (Cast<Mixin_Call>(node)) {
    Mixin_Call* block = Cast<Mixin_Call>(node);
    std::cerr << ind << "Mixin_Call " << block << " " << block->tabs();
    std::cerr << " (" << pstate_source_position(block) << ")";
    std::cerr << " [" <<  block->name() << "]";
    std::cerr << " [has_content: " << block->has_content() << "] " << std::endl;
    debug_ast(block->arguments(), ind + " args: ", env);
    debug_ast(block->block_parameters(), ind + " block_params: ", env);
    if (block->block()) debug_ast(block->block(), ind + " ", env);
  } else if (StyleRule* ruleset = Cast<StyleRule>(node)) {
    std::cerr << ind << "StyleRule " << ruleset;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [indent: " << ruleset->tabs() << "]";
    std::cerr << (ruleset->is_invisible() ? " [INVISIBLE]" : "");
    std::cerr << (ruleset->is_root() ? " [root]" : "");
    std::cerr << std::endl;
    debug_ast(ruleset->selector(), ind + ">");
    debug_ast(ruleset->block(), ind + " ");
  } else if (Cast<Block>(node)) {
    Block* block = Cast<Block>(node);
    std::cerr << ind << "Block " << block;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << (block->is_invisible() ? " [INVISIBLE]" : "");
    std::cerr << " [indent: " << block->tabs() << "]" << std::endl;
    for(const Statement_Obj& i : block->elements()) { debug_ast(i, ind + " ", env); }
  } else if (Cast<Variable>(node)) {
    Variable* expression = Cast<Variable>(node);
    std::cerr << ind << "Variable " << expression;
    std::cerr << " [interpolant: " << expression->is_interpolant() << "] ";
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [" << expression->name() << "]" << std::endl;
    sass::string name(expression->name());
    if (env && env->has(name)) debug_ast(Cast<Expression>((*env)[name]), ind + " -> ", env);
  } else if (Cast<Function_Call>(node)) {
    Function_Call* expression = Cast<Function_Call>(node);
    std::cerr << ind << "Function_Call " << expression;
    std::cerr << " [interpolant: " << expression->is_interpolant() << "] ";
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [" << expression->name() << "]";
    if (expression->is_delayed()) std::cerr << " [delayed]";
    if (expression->is_interpolant()) std::cerr << " [interpolant]";
    if (expression->is_css()) std::cerr << " [css]";
    std::cerr << std::endl;
    debug_ast(expression->arguments(), ind + " args: ", env);
    debug_ast(expression->func(), ind + " func: ", env);
  } else if (Cast<Function>(node)) {
    Function* expression = Cast<Function>(node);
    std::cerr << ind << "Function " << expression;
    std::cerr << " (" << pstate_source_position(node) << ")";
    if (expression->is_css()) std::cerr << " [css]";
    std::cerr << std::endl;
    debug_ast(expression->definition(), ind + " definition: ", env);
  } else if (Cast<Arguments>(node)) {
    Arguments* expression = Cast<Arguments>(node);
    std::cerr << ind << "Arguments " << expression;
    if (expression->is_delayed()) std::cerr << " [delayed]";
    std::cerr << " (" << pstate_source_position(node) << ")";
    if (expression->has_named_arguments()) std::cerr << " [has_named_arguments]";
    if (expression->has_rest_argument()) std::cerr << " [has_rest_argument]";
    if (expression->has_keyword_argument()) std::cerr << " [has_keyword_argument]";
    std::cerr << std::endl;
    for(const Argument_Obj& i : expression->elements()) { debug_ast(i, ind + " ", env); }
  } else if (Cast<Argument>(node)) {
    Argument* expression = Cast<Argument>(node);
    std::cerr << ind << "Argument " << expression;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [" << expression->value().ptr() << "]";
    std::cerr << " [name: " << expression->name() << "] ";
    std::cerr << " [rest: " << expression->is_rest_argument() << "] ";
    std::cerr << " [keyword: " << expression->is_keyword_argument() << "] " << std::endl;
    debug_ast(expression->value(), ind + " value: ", env);
  } else if (Cast<Parameters>(node)) {
    Parameters* expression = Cast<Parameters>(node);
    std::cerr << ind << "Parameters " << expression;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [has_optional: " << expression->has_optional_parameters() << "] ";
    std::cerr << " [has_rest: " << expression->has_rest_parameter() << "] ";
    std::cerr << std::endl;
    for(const Parameter_Obj& i : expression->elements()) { debug_ast(i, ind + " ", env); }
  } else if (Cast<Parameter>(node)) {
    Parameter* expression = Cast<Parameter>(node);
    std::cerr << ind << "Parameter " << expression;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [name: " << expression->name() << "] ";
    std::cerr << " [default: " << expression->default_value().ptr() << "] ";
    std::cerr << " [rest: " << expression->is_rest_parameter() << "] " << std::endl;
  } else if (Cast<Unary_Expression>(node)) {
    Unary_Expression* expression = Cast<Unary_Expression>(node);
    std::cerr << ind << "Unary_Expression " << expression;
    std::cerr << " [interpolant: " << expression->is_interpolant() << "] ";
    std::cerr << " [delayed: " << expression->is_delayed() << "] ";
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [" << expression->type() << "]" << std::endl;
    debug_ast(expression->operand(), ind + " operand: ", env);
  } else if (Cast<Binary_Expression>(node)) {
    Binary_Expression* expression = Cast<Binary_Expression>(node);
    std::cerr << ind << "Binary_Expression " << expression;
    if (expression->is_interpolant()) std::cerr << " [is interpolant] ";
    if (expression->is_left_interpolant()) std::cerr << " [left interpolant] ";
    if (expression->is_right_interpolant()) std::cerr << " [right interpolant] ";
    std::cerr << " [delayed: " << expression->is_delayed() << "] ";
    std::cerr << " [ws_before: " << expression->op().ws_before << "] ";
    std::cerr << " [ws_after: " << expression->op().ws_after << "] ";
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [" << expression->type_name() << "]" << std::endl;
    debug_ast(expression->left(), ind + " left:  ", env);
    debug_ast(expression->right(), ind + " right: ", env);
  } else if (Cast<Map>(node)) {
    Map* expression = Cast<Map>(node);
    std::cerr << ind << "Map " << expression;
    std::cerr << " [interpolant: " << expression->is_interpolant() << "] ";
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [Hashed]" << std::endl;
    for (const auto& i : expression->elements()) {
      debug_ast(i.first, ind + " key: ");
      debug_ast(i.second, ind + " val: ");
    }
  } else if (Cast<List>(node)) {
    List* expression = Cast<List>(node);
    std::cerr << ind << "List " << expression;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " (" << expression->length() << ") " <<
      (expression->separator() == SASS_COMMA ? "Comma " : expression->separator() == SASS_HASH ? "Map " : "Space ") <<
      " [delayed: " << expression->is_delayed() << "] " <<
      " [interpolant: " << expression->is_interpolant() << "] " <<
      " [listized: " << expression->from_selector() << "] " <<
      " [arglist: " << expression->is_arglist() << "] " <<
      " [bracketed: " << expression->is_bracketed() << "] " <<
      " [expanded: " << expression->is_expanded() << "] " <<
      " [hash: " << expression->hash() << "] " <<
      std::endl;
    for(const auto& i : expression->elements()) { debug_ast(i, ind + " ", env); }
  } else if (Cast<Boolean>(node)) {
    Boolean* expression = Cast<Boolean>(node);
    std::cerr << ind << "Boolean " << expression;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [interpolant: " << expression->is_interpolant() << "] ";
    std::cerr << " [" << expression->value() << "]" << std::endl;
  } else if (Cast<Color_RGBA>(node)) {
    Color_RGBA* expression = Cast<Color_RGBA>(node);
    std::cerr << ind << "Color " << expression;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [name: " << expression->disp() << "] ";
    std::cerr << " [delayed: " << expression->is_delayed() << "] ";
    std::cerr << " [interpolant: " << expression->is_interpolant() << "] ";
    std::cerr << " rgba[" << expression->r() << ":"  << expression->g() << ":" << expression->b() << "@" << expression->a() << "]" << std::endl;
  } else if (Cast<Color_HSLA>(node)) {
    Color_HSLA* expression = Cast<Color_HSLA>(node);
    std::cerr << ind << "Color " << expression;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [name: " << expression->disp() << "] ";
    std::cerr << " [delayed: " << expression->is_delayed() << "] ";
    std::cerr << " [interpolant: " << expression->is_interpolant() << "] ";
    std::cerr << " hsla[" << expression->h() << ":"  << expression->s() << ":" << expression->l() << "@" << expression->a() << "]" << std::endl;
  } else if (Cast<Number>(node)) {
    Number* expression = Cast<Number>(node);
    std::cerr << ind << "Number " << expression;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [delayed: " << expression->is_delayed() << "] ";
    std::cerr << " [interpolant: " << expression->is_interpolant() << "] ";
    std::cerr << " [" << expression->value() << expression->unit() << "]" <<
      " [hash: " << expression->hash() << "] " <<
      std::endl;
  } else if (Cast<Null>(node)) {
    Null* expression = Cast<Null>(node);
    std::cerr << ind << "Null " << expression;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [interpolant: " << expression->is_interpolant() << "] "
      // " [hash: " << expression->hash() << "] "
      << std::endl;
  } else if (Cast<String_Quoted>(node)) {
    String_Quoted* expression = Cast<String_Quoted>(node);
    std::cerr << ind << "String_Quoted " << expression;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [" << prettyprint(expression->value()) << "]";
    if (expression->is_delayed()) std::cerr << " [delayed]";
    if (expression->is_interpolant()) std::cerr << " [interpolant]";
    if (expression->quote_mark()) std::cerr << " [quote_mark: " << expression->quote_mark() << "]";
    std::cerr << std::endl;
  } else if (Cast<String_Constant>(node)) {
    String_Constant* expression = Cast<String_Constant>(node);
    std::cerr << ind << "String_Constant " << expression;
    if (expression->concrete_type()) {
      std::cerr << " " << expression->concrete_type();
    }
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " [" << prettyprint(expression->value()) << "]";
    if (expression->is_delayed()) std::cerr << " [delayed]";
    if (expression->is_interpolant()) std::cerr << " [interpolant]";
    std::cerr << std::endl;
  } else if (Cast<String_Schema>(node)) {
    String_Schema* expression = Cast<String_Schema>(node);
    std::cerr << ind << "String_Schema " << expression;
    std::cerr << " (" << pstate_source_position(expression) << ")";
    std::cerr << " " << expression->concrete_type();
    std::cerr << " (" << pstate_source_position(node) << ")";
    if (expression->css()) std::cerr << " [css]";
    if (expression->is_delayed()) std::cerr << " [delayed]";
    if (expression->is_interpolant()) std::cerr << " [is interpolant]";
    if (expression->has_interpolant()) std::cerr << " [has interpolant]";
    if (expression->is_left_interpolant()) std::cerr << " [left interpolant] ";
    if (expression->is_right_interpolant()) std::cerr << " [right interpolant] ";
    std::cerr << std::endl;
    for(const auto& i : expression->elements()) { debug_ast(i, ind + " ", env); }
  } else if (Cast<String>(node)) {
    String* expression = Cast<String>(node);
    std::cerr << ind << "String " << expression;
    std::cerr << " " << expression->concrete_type();
    std::cerr << " (" << pstate_source_position(node) << ")";
    if (expression->is_interpolant()) std::cerr << " [interpolant]";
    std::cerr << std::endl;
  } else if (Cast<Expression>(node)) {
    Expression* expression = Cast<Expression>(node);
    std::cerr << ind << "Expression " << expression;
    std::cerr << " (" << pstate_source_position(node) << ")";
    switch (expression->concrete_type()) {
      case Expression::Type::NONE: std::cerr << " [NONE]"; break;
      case Expression::Type::BOOLEAN: std::cerr << " [BOOLEAN]"; break;
      case Expression::Type::NUMBER: std::cerr << " [NUMBER]"; break;
      case Expression::Type::COLOR: std::cerr << " [COLOR]"; break;
      case Expression::Type::STRING: std::cerr << " [STRING]"; break;
      case Expression::Type::LIST: std::cerr << " [LIST]"; break;
      case Expression::Type::MAP: std::cerr << " [MAP]"; break;
      case Expression::Type::SELECTOR: std::cerr << " [SELECTOR]"; break;
      case Expression::Type::NULL_VAL: std::cerr << " [NULL_VAL]"; break;
      case Expression::Type::C_WARNING: std::cerr << " [C_WARNING]"; break;
      case Expression::Type::C_ERROR: std::cerr << " [C_ERROR]"; break;
      case Expression::Type::FUNCTION: std::cerr << " [FUNCTION]"; break;
      case Expression::Type::NUM_TYPES: std::cerr << " [NUM_TYPES]"; break;
      case Expression::Type::VARIABLE: std::cerr << " [VARIABLE]"; break;
      case Expression::Type::FUNCTION_VAL: std::cerr << " [FUNCTION_VAL]"; break;
      case Expression::Type::PARENT: std::cerr << " [PARENT]"; break;
    }
    std::cerr << std::endl;
  } else if (Cast<ParentStatement>(node)) {
    ParentStatement* parent = Cast<ParentStatement>(node);
    std::cerr << ind << "ParentStatement " << parent;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << parent->tabs() << std::endl;
    if (parent->block()) for(const Statement_Obj& i : parent->block()->elements()) { debug_ast(i, ind + " ", env); }
  } else if (Cast<Statement>(node)) {
    Statement* statement = Cast<Statement>(node);
    std::cerr << ind << "Statement " << statement;
    std::cerr << " (" << pstate_source_position(node) << ")";
    std::cerr << " " << statement->tabs() << std::endl;
  }

  if (ind == "") std::cerr << "####################################################################\n";
}


/*
inline void debug_ast(const AST_Node* node, sass::string ind = "", Env* env = 0)
{
  debug_ast(const_cast<AST_Node*>(node), ind, env);
}
*/

#endif // SASS_DEBUGGER
