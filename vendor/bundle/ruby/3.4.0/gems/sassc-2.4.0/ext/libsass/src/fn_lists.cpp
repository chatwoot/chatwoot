// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include "listize.hpp"
#include "operators.hpp"
#include "fn_utils.hpp"
#include "fn_lists.hpp"

namespace Sass {

  namespace Functions {

    /////////////////
    // LIST FUNCTIONS
    /////////////////

    Signature keywords_sig = "keywords($args)";
    BUILT_IN(keywords)
    {
      List_Obj arglist = SASS_MEMORY_COPY(ARG("$args", List)); // copy
      Map_Obj result = SASS_MEMORY_NEW(Map, pstate, 1);
      for (size_t i = arglist->size(), L = arglist->length(); i < L; ++i) {
        ExpressionObj obj = arglist->at(i);
        Argument_Obj arg = (Argument*) obj.ptr(); // XXX
        sass::string name = sass::string(arg->name());
        name = name.erase(0, 1); // sanitize name (remove dollar sign)
        *result << std::make_pair(SASS_MEMORY_NEW(String_Quoted,
                 pstate, name),
                 arg->value());
      }
      return result.detach();
    }

    Signature length_sig = "length($list)";
    BUILT_IN(length)
    {
      if (SelectorList * sl = Cast<SelectorList>(env["$list"])) {
        return SASS_MEMORY_NEW(Number, pstate, (double) sl->length());
      }
      Expression* v = ARG("$list", Expression);
      if (v->concrete_type() == Expression::MAP) {
        Map* map = Cast<Map>(env["$list"]);
        return SASS_MEMORY_NEW(Number, pstate, (double)(map ? map->length() : 1));
      }
      if (v->concrete_type() == Expression::SELECTOR) {
        if (CompoundSelector * h = Cast<CompoundSelector>(v)) {
          return SASS_MEMORY_NEW(Number, pstate, (double)h->length());
        } else if (SelectorList * ls = Cast<SelectorList>(v)) {
          return SASS_MEMORY_NEW(Number, pstate, (double)ls->length());
        } else {
          return SASS_MEMORY_NEW(Number, pstate, 1);
        }
      }

      List* list = Cast<List>(env["$list"]);
      return SASS_MEMORY_NEW(Number,
                             pstate,
                             (double)(list ? list->size() : 1));
    }

    Signature nth_sig = "nth($list, $n)";
    BUILT_IN(nth)
    {
      double nr = ARGVAL("$n");
      Map* m = Cast<Map>(env["$list"]);
      if (SelectorList * sl = Cast<SelectorList>(env["$list"])) {
        size_t len = m ? m->length() : sl->length();
        bool empty = m ? m->empty() : sl->empty();
        if (empty) error("argument `$list` of `" + sass::string(sig) + "` must not be empty", pstate, traces);
        double index = std::floor(nr < 0 ? len + nr : nr - 1);
        if (index < 0 || index > len - 1) error("index out of bounds for `" + sass::string(sig) + "`", pstate, traces);
        return Cast<Value>(Listize::perform(sl->get(static_cast<int>(index))));
      }
      List_Obj l = Cast<List>(env["$list"]);
      if (nr == 0) error("argument `$n` of `" + sass::string(sig) + "` must be non-zero", pstate, traces);
      // if the argument isn't a list, then wrap it in a singleton list
      if (!m && !l) {
        l = SASS_MEMORY_NEW(List, pstate, 1);
        l->append(ARG("$list", Expression));
      }
      size_t len = m ? m->length() : l->length();
      bool empty = m ? m->empty() : l->empty();
      if (empty) error("argument `$list` of `" + sass::string(sig) + "` must not be empty", pstate, traces);
      double index = std::floor(nr < 0 ? len + nr : nr - 1);
      if (index < 0 || index > len - 1) error("index out of bounds for `" + sass::string(sig) + "`", pstate, traces);

      if (m) {
        l = SASS_MEMORY_NEW(List, pstate, 2);
        l->append(m->keys()[static_cast<unsigned int>(index)]);
        l->append(m->at(m->keys()[static_cast<unsigned int>(index)]));
        return l.detach();
      }
      else {
        ValueObj rv = l->value_at_index(static_cast<int>(index));
        rv->set_delayed(false);
        return rv.detach();
      }
    }

    Signature set_nth_sig = "set-nth($list, $n, $value)";
    BUILT_IN(set_nth)
    {
      Map_Obj m = Cast<Map>(env["$list"]);
      List_Obj l = Cast<List>(env["$list"]);
      Number_Obj n = ARG("$n", Number);
      ExpressionObj v = ARG("$value", Expression);
      if (!l) {
        l = SASS_MEMORY_NEW(List, pstate, 1);
        l->append(ARG("$list", Expression));
      }
      if (m) {
        l = m->to_list(pstate);
      }
      if (l->empty()) error("argument `$list` of `" + sass::string(sig) + "` must not be empty", pstate, traces);
      double index = std::floor(n->value() < 0 ? l->length() + n->value() : n->value() - 1);
      if (index < 0 || index > l->length() - 1) error("index out of bounds for `" + sass::string(sig) + "`", pstate, traces);
      List* result = SASS_MEMORY_NEW(List, pstate, l->length(), l->separator(), false, l->is_bracketed());
      for (size_t i = 0, L = l->length(); i < L; ++i) {
        result->append(((i == index) ? v : (*l)[i]));
      }
      return result;
    }

    Signature index_sig = "index($list, $value)";
    BUILT_IN(index)
    {
      Map_Obj m = Cast<Map>(env["$list"]);
      List_Obj l = Cast<List>(env["$list"]);
      ExpressionObj v = ARG("$value", Expression);
      if (!l) {
        l = SASS_MEMORY_NEW(List, pstate, 1);
        l->append(ARG("$list", Expression));
      }
      if (m) {
        l = m->to_list(pstate);
      }
      for (size_t i = 0, L = l->length(); i < L; ++i) {
        if (Operators::eq(l->value_at_index(i), v)) return SASS_MEMORY_NEW(Number, pstate, (double)(i+1));
      }
      return SASS_MEMORY_NEW(Null, pstate);
    }

    Signature join_sig = "join($list1, $list2, $separator: auto, $bracketed: auto)";
    BUILT_IN(join)
    {
      Map_Obj m1 = Cast<Map>(env["$list1"]);
      Map_Obj m2 = Cast<Map>(env["$list2"]);
      List_Obj l1 = Cast<List>(env["$list1"]);
      List_Obj l2 = Cast<List>(env["$list2"]);
      String_Constant_Obj sep = ARG("$separator", String_Constant);
      enum Sass_Separator sep_val = (l1 ? l1->separator() : SASS_SPACE);
      Value* bracketed = ARG("$bracketed", Value);
      bool is_bracketed = (l1 ? l1->is_bracketed() : false);
      if (!l1) {
        l1 = SASS_MEMORY_NEW(List, pstate, 1);
        l1->append(ARG("$list1", Expression));
        sep_val = (l2 ? l2->separator() : SASS_SPACE);
        is_bracketed = (l2 ? l2->is_bracketed() : false);
      }
      if (!l2) {
        l2 = SASS_MEMORY_NEW(List, pstate, 1);
        l2->append(ARG("$list2", Expression));
      }
      if (m1) {
        l1 = m1->to_list(pstate);
        sep_val = SASS_COMMA;
      }
      if (m2) {
        l2 = m2->to_list(pstate);
      }
      size_t len = l1->length() + l2->length();
      sass::string sep_str = unquote(sep->value());
      if (sep_str == "space") sep_val = SASS_SPACE;
      else if (sep_str == "comma") sep_val = SASS_COMMA;
      else if (sep_str != "auto") error("argument `$separator` of `" + sass::string(sig) + "` must be `space`, `comma`, or `auto`", pstate, traces);
      String_Constant_Obj bracketed_as_str = Cast<String_Constant>(bracketed);
      bool bracketed_is_auto = bracketed_as_str && unquote(bracketed_as_str->value()) == "auto";
      if (!bracketed_is_auto) {
        is_bracketed = !bracketed->is_false();
      }
      List_Obj result = SASS_MEMORY_NEW(List, pstate, len, sep_val, false, is_bracketed);
      result->concat(l1);
      result->concat(l2);
      return result.detach();
    }

    Signature append_sig = "append($list, $val, $separator: auto)";
    BUILT_IN(append)
    {
      Map_Obj m = Cast<Map>(env["$list"]);
      List_Obj l = Cast<List>(env["$list"]);
      ExpressionObj v = ARG("$val", Expression);
      if (SelectorList * sl = Cast<SelectorList>(env["$list"])) {
        l = Cast<List>(Listize::perform(sl));
      }
      String_Constant_Obj sep = ARG("$separator", String_Constant);
      if (!l) {
        l = SASS_MEMORY_NEW(List, pstate, 1);
        l->append(ARG("$list", Expression));
      }
      if (m) {
        l = m->to_list(pstate);
      }
      List* result = SASS_MEMORY_COPY(l);
      sass::string sep_str(unquote(sep->value()));
      if (sep_str != "auto") { // check default first
        if (sep_str == "space") result->separator(SASS_SPACE);
        else if (sep_str == "comma") result->separator(SASS_COMMA);
        else error("argument `$separator` of `" + sass::string(sig) + "` must be `space`, `comma`, or `auto`", pstate, traces);
      }
      if (l->is_arglist()) {
        result->append(SASS_MEMORY_NEW(Argument,
                                       v->pstate(),
                                       v,
                                       "",
                                       false,
                                       false));

      } else {
        result->append(v);
      }
      return result;
    }

    Signature zip_sig = "zip($lists...)";
    BUILT_IN(zip)
    {
      List_Obj arglist = SASS_MEMORY_COPY(ARG("$lists", List));
      size_t shortest = 0;
      for (size_t i = 0, L = arglist->length(); i < L; ++i) {
        List_Obj ith = Cast<List>(arglist->value_at_index(i));
        Map_Obj mith = Cast<Map>(arglist->value_at_index(i));
        if (!ith) {
          if (mith) {
            ith = mith->to_list(pstate);
          } else {
            ith = SASS_MEMORY_NEW(List, pstate, 1);
            ith->append(arglist->value_at_index(i));
          }
          if (arglist->is_arglist()) {
            Argument_Obj arg = (Argument*)(arglist->at(i).ptr()); // XXX
            arg->value(ith);
          } else {
            (*arglist)[i] = ith;
          }
        }
        shortest = (i ? std::min(shortest, ith->length()) : ith->length());
      }
      List* zippers = SASS_MEMORY_NEW(List, pstate, shortest, SASS_COMMA);
      size_t L = arglist->length();
      for (size_t i = 0; i < shortest; ++i) {
        List* zipper = SASS_MEMORY_NEW(List, pstate, L);
        for (size_t j = 0; j < L; ++j) {
          zipper->append(Cast<List>(arglist->value_at_index(j))->at(i));
        }
        zippers->append(zipper);
      }
      return zippers;
    }

    Signature list_separator_sig = "list_separator($list)";
    BUILT_IN(list_separator)
    {
      List_Obj l = Cast<List>(env["$list"]);
      if (!l) {
        l = SASS_MEMORY_NEW(List, pstate, 1);
        l->append(ARG("$list", Expression));
      }
      return SASS_MEMORY_NEW(String_Quoted,
                               pstate,
                               l->separator() == SASS_COMMA ? "comma" : "space");
    }

    Signature is_bracketed_sig = "is-bracketed($list)";
    BUILT_IN(is_bracketed)
    {
      ValueObj value = ARG("$list", Value);
      List_Obj list = Cast<List>(value);
      return SASS_MEMORY_NEW(Boolean, pstate, list && list->is_bracketed());
    }

  }

}
