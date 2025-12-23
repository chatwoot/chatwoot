// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include <cstdint>
#include <cstdlib>
#include <cmath>
#include <random>
#include <sstream>
#include <iomanip>
#include <algorithm>

#include "ast.hpp"
#include "units.hpp"
#include "fn_utils.hpp"
#include "fn_numbers.hpp"

#ifdef __MINGW32__
#include "windows.h"
#include "wincrypt.h"
#endif

namespace Sass {

  namespace Functions {

    #ifdef __MINGW32__
      uint64_t GetSeed()
      {
        HCRYPTPROV hp = 0;
        BYTE rb[8];
        CryptAcquireContext(&hp, 0, 0, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT);
        CryptGenRandom(hp, sizeof(rb), rb);
        CryptReleaseContext(hp, 0);

        uint64_t seed;
        memcpy(&seed, &rb[0], sizeof(seed));

        return seed;
      }
    #else
      uint64_t GetSeed()
      {
        std::random_device rd;
        return rd();
      }
    #endif

    // note: the performance of many implementations of
    // random_device degrades sharply once the entropy pool
    // is exhausted. For practical use, random_device is
    // generally only used to seed a PRNG such as mt19937.
    static std::mt19937 rand(static_cast<unsigned int>(GetSeed()));

    ///////////////////
    // NUMBER FUNCTIONS
    ///////////////////

    Signature percentage_sig = "percentage($number)";
    BUILT_IN(percentage)
    {
      Number_Obj n = ARGN("$number");
      if (!n->is_unitless()) error("argument $number of `" + sass::string(sig) + "` must be unitless", pstate, traces);
      return SASS_MEMORY_NEW(Number, pstate, n->value() * 100, "%");
    }

    Signature round_sig = "round($number)";
    BUILT_IN(round)
    {
      Number_Obj r = ARGN("$number");
      r->value(Sass::round(r->value(), ctx.c_options.precision));
      r->pstate(pstate);
      return r.detach();
    }

    Signature ceil_sig = "ceil($number)";
    BUILT_IN(ceil)
    {
      Number_Obj r = ARGN("$number");
      r->value(std::ceil(r->value()));
      r->pstate(pstate);
      return r.detach();
    }

    Signature floor_sig = "floor($number)";
    BUILT_IN(floor)
    {
      Number_Obj r = ARGN("$number");
      r->value(std::floor(r->value()));
      r->pstate(pstate);
      return r.detach();
    }

    Signature abs_sig = "abs($number)";
    BUILT_IN(abs)
    {
      Number_Obj r = ARGN("$number");
      r->value(std::abs(r->value()));
      r->pstate(pstate);
      return r.detach();
    }

    Signature min_sig = "min($numbers...)";
    BUILT_IN(min)
    {
      List* arglist = ARG("$numbers", List);
      Number_Obj least;
      size_t L = arglist->length();
      if (L == 0) {
        error("At least one argument must be passed.", pstate, traces);
      }
      for (size_t i = 0; i < L; ++i) {
        ExpressionObj val = arglist->value_at_index(i);
        Number_Obj xi = Cast<Number>(val);
        if (!xi) {
          error("\"" + val->to_string(ctx.c_options) + "\" is not a number for `min'", pstate, traces);
        }
        if (least) {
          if (*xi < *least) least = xi;
        } else least = xi;
      }
      return least.detach();
    }

    Signature max_sig = "max($numbers...)";
    BUILT_IN(max)
    {
      List* arglist = ARG("$numbers", List);
      Number_Obj greatest;
      size_t L = arglist->length();
      if (L == 0) {
        error("At least one argument must be passed.", pstate, traces);
      }
      for (size_t i = 0; i < L; ++i) {
        ExpressionObj val = arglist->value_at_index(i);
        Number_Obj xi = Cast<Number>(val);
        if (!xi) {
          error("\"" + val->to_string(ctx.c_options) + "\" is not a number for `max'", pstate, traces);
        }
        if (greatest) {
          if (*greatest < *xi) greatest = xi;
        } else greatest = xi;
      }
      return greatest.detach();
    }

    Signature random_sig = "random($limit:false)";
    BUILT_IN(random)
    {
      AST_Node_Obj arg = env["$limit"];
      Value* v = Cast<Value>(arg);
      Number* l = Cast<Number>(arg);
      Boolean* b = Cast<Boolean>(arg);
      if (l) {
        double lv = l->value();
        if (lv < 1) {
          sass::ostream err;
          err << "$limit " << lv << " must be greater than or equal to 1 for `random'";
          error(err.str(), pstate, traces);
        }
        bool eq_int = std::fabs(trunc(lv) - lv) < NUMBER_EPSILON;
        if (!eq_int) {
          sass::ostream err;
          err << "Expected $limit to be an integer but got " << lv << " for `random'";
          error(err.str(), pstate, traces);
        }
        std::uniform_real_distribution<> distributor(1, lv + 1);
        uint_fast32_t distributed = static_cast<uint_fast32_t>(distributor(rand));
        return SASS_MEMORY_NEW(Number, pstate, (double)distributed);
      }
      else if (b) {
        std::uniform_real_distribution<> distributor(0, 1);
        double distributed = static_cast<double>(distributor(rand));
        return SASS_MEMORY_NEW(Number, pstate, distributed);
      } else if (v) {
        traces.push_back(Backtrace(pstate));
        throw Exception::InvalidArgumentType(pstate, traces, "random", "$limit", "number", v);
      } else {
        traces.push_back(Backtrace(pstate));
        throw Exception::InvalidArgumentType(pstate, traces, "random", "$limit", "number");
      }
    }

    Signature unique_id_sig = "unique-id()";
    BUILT_IN(unique_id)
    {
      sass::ostream ss;
      std::uniform_real_distribution<> distributor(0, 4294967296); // 16^8
      uint_fast32_t distributed = static_cast<uint_fast32_t>(distributor(rand));
      ss << "u" << std::setfill('0') << std::setw(8) << std::hex << distributed;
      return SASS_MEMORY_NEW(String_Quoted, pstate, ss.str());
    }

    Signature unit_sig = "unit($number)";
    BUILT_IN(unit)
    {
      Number_Obj arg = ARGN("$number");
      sass::string str(quote(arg->unit(), '"'));
      return SASS_MEMORY_NEW(String_Quoted, pstate, str);
    }

    Signature unitless_sig = "unitless($number)";
    BUILT_IN(unitless)
    {
      Number_Obj arg = ARGN("$number");
      bool unitless = arg->is_unitless();
      return SASS_MEMORY_NEW(Boolean, pstate, unitless);
    }

    Signature comparable_sig = "comparable($number1, $number2)";
    BUILT_IN(comparable)
    {
      Number_Obj n1 = ARGN("$number1");
      Number_Obj n2 = ARGN("$number2");
      if (n1->is_unitless() || n2->is_unitless()) {
        return SASS_MEMORY_NEW(Boolean, pstate, true);
      }
      // normalize into main units
      n1->normalize(); n2->normalize();
      Units &lhs_unit = *n1, &rhs_unit = *n2;
      bool is_comparable = (lhs_unit == rhs_unit);
      return SASS_MEMORY_NEW(Boolean, pstate, is_comparable);
    }

  }

}
