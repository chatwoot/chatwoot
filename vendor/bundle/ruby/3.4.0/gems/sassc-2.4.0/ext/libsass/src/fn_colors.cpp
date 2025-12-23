// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include <iomanip>
#include "ast.hpp"
#include "fn_utils.hpp"
#include "fn_colors.hpp"
#include "util.hpp"
#include "util_string.hpp"

namespace Sass {

  namespace Functions {

    bool string_argument(AST_Node_Obj obj) {
      String_Constant* s = Cast<String_Constant>(obj);
      if (s == nullptr) return false;
      const sass::string& str = s->value();
      return starts_with(str, "calc(") ||
             starts_with(str, "var(");
    }

    void hsla_alpha_percent_deprecation(const SourceSpan& pstate, const sass::string val)
    {

      sass::string msg("Passing a percentage as the alpha value to hsla() will be interpreted");
      sass::string tail("differently in future versions of Sass. For now, use " + val + " instead.");

      deprecated(msg, tail, false, pstate);

    }

    Signature rgb_sig = "rgb($red, $green, $blue)";
    BUILT_IN(rgb)
    {
      if (
        string_argument(env["$red"]) ||
        string_argument(env["$green"]) ||
        string_argument(env["$blue"])
      ) {
        return SASS_MEMORY_NEW(String_Constant, pstate, "rgb("
                                                        + env["$red"]->to_string()
                                                        + ", "
                                                        + env["$green"]->to_string()
                                                        + ", "
                                                        + env["$blue"]->to_string()
                                                        + ")"
        );
      }

      return SASS_MEMORY_NEW(Color_RGBA,
                             pstate,
                             COLOR_NUM("$red"),
                             COLOR_NUM("$green"),
                             COLOR_NUM("$blue"));
    }

    Signature rgba_4_sig = "rgba($red, $green, $blue, $alpha)";
    BUILT_IN(rgba_4)
    {
      if (
        string_argument(env["$red"]) ||
        string_argument(env["$green"]) ||
        string_argument(env["$blue"]) ||
        string_argument(env["$alpha"])
      ) {
        return SASS_MEMORY_NEW(String_Constant, pstate, "rgba("
                                                        + env["$red"]->to_string()
                                                        + ", "
                                                        + env["$green"]->to_string()
                                                        + ", "
                                                        + env["$blue"]->to_string()
                                                        + ", "
                                                        + env["$alpha"]->to_string()
                                                        + ")"
        );
      }

      return SASS_MEMORY_NEW(Color_RGBA,
                             pstate,
                             COLOR_NUM("$red"),
                             COLOR_NUM("$green"),
                             COLOR_NUM("$blue"),
                             ALPHA_NUM("$alpha"));
    }

    Signature rgba_2_sig = "rgba($color, $alpha)";
    BUILT_IN(rgba_2)
    {
      if (
        string_argument(env["$color"])
      ) {
        return SASS_MEMORY_NEW(String_Constant, pstate, "rgba("
                                                        + env["$color"]->to_string()
                                                        + ", "
                                                        + env["$alpha"]->to_string()
                                                        + ")"
        );
      }

      Color_RGBA_Obj c_arg = ARG("$color", Color)->toRGBA();

      if (
        string_argument(env["$alpha"])
      ) {
        sass::ostream strm;
        strm << "rgba("
                 << (int)c_arg->r() << ", "
                 << (int)c_arg->g() << ", "
                 << (int)c_arg->b() << ", "
                 << env["$alpha"]->to_string()
             << ")";
        return SASS_MEMORY_NEW(String_Constant, pstate, strm.str());
      }

      Color_RGBA_Obj new_c = SASS_MEMORY_COPY(c_arg);
      new_c->a(ALPHA_NUM("$alpha"));
      new_c->disp("");
      return new_c.detach();
    }

    ////////////////
    // RGB FUNCTIONS
    ////////////////

    Signature red_sig = "red($color)";
    BUILT_IN(red)
    {
      Color_RGBA_Obj color = ARG("$color", Color)->toRGBA();
      return SASS_MEMORY_NEW(Number, pstate, color->r());
    }

    Signature green_sig = "green($color)";
    BUILT_IN(green)
    {
      Color_RGBA_Obj color = ARG("$color", Color)->toRGBA();
      return SASS_MEMORY_NEW(Number, pstate, color->g());
    }

    Signature blue_sig = "blue($color)";
    BUILT_IN(blue)
    {
      Color_RGBA_Obj color = ARG("$color", Color)->toRGBA();
      return SASS_MEMORY_NEW(Number, pstate, color->b());
    }

    Color_RGBA* colormix(Context& ctx, SourceSpan& pstate, Color* color1, Color* color2, double weight) {
      Color_RGBA_Obj c1 = color1->toRGBA();
      Color_RGBA_Obj c2 = color2->toRGBA();
      double p = weight/100;
      double w = 2*p - 1;
      double a = c1->a() - c2->a();

      double w1 = (((w * a == -1) ? w : (w + a)/(1 + w*a)) + 1)/2.0;
      double w2 = 1 - w1;

      return SASS_MEMORY_NEW(Color_RGBA,
                             pstate,
                             Sass::round(w1*c1->r() + w2*c2->r(), ctx.c_options.precision),
                             Sass::round(w1*c1->g() + w2*c2->g(), ctx.c_options.precision),
                             Sass::round(w1*c1->b() + w2*c2->b(), ctx.c_options.precision),
                             c1->a()*p + c2->a()*(1-p));
    }

    Signature mix_sig = "mix($color1, $color2, $weight: 50%)";
    BUILT_IN(mix)
    {
      Color_Obj  color1 = ARG("$color1", Color);
      Color_Obj  color2 = ARG("$color2", Color);
      double weight = DARG_U_PRCT("$weight");
      return colormix(ctx, pstate, color1, color2, weight);

    }

    ////////////////
    // HSL FUNCTIONS
    ////////////////

    Signature hsl_sig = "hsl($hue, $saturation, $lightness)";
    BUILT_IN(hsl)
    {
      if (
        string_argument(env["$hue"]) ||
        string_argument(env["$saturation"]) ||
        string_argument(env["$lightness"])
      ) {
        return SASS_MEMORY_NEW(String_Constant, pstate, "hsl("
                                                        + env["$hue"]->to_string()
                                                        + ", "
                                                        + env["$saturation"]->to_string()
                                                        + ", "
                                                        + env["$lightness"]->to_string()
                                                        + ")"
        );
      }

      return SASS_MEMORY_NEW(Color_HSLA,
        pstate,
        ARGVAL("$hue"),
        ARGVAL("$saturation"),
        ARGVAL("$lightness"),
        1.0);

    }

    Signature hsla_sig = "hsla($hue, $saturation, $lightness, $alpha)";
    BUILT_IN(hsla)
    {
      if (
        string_argument(env["$hue"]) ||
        string_argument(env["$saturation"]) ||
        string_argument(env["$lightness"]) ||
        string_argument(env["$alpha"])
      ) {
        return SASS_MEMORY_NEW(String_Constant, pstate, "hsla("
                                                        + env["$hue"]->to_string()
                                                        + ", "
                                                        + env["$saturation"]->to_string()
                                                        + ", "
                                                        + env["$lightness"]->to_string()
                                                        + ", "
                                                        + env["$alpha"]->to_string()
                                                        + ")"
        );
      }

      Number* alpha = ARG("$alpha", Number);
      if (alpha && alpha->unit() == "%") {
        Number_Obj val = SASS_MEMORY_COPY(alpha);
        val->numerators.clear(); // convert
        val->value(val->value() / 100.0);
        sass::string nr(val->to_string(ctx.c_options));
        hsla_alpha_percent_deprecation(pstate, nr);
      }

      return SASS_MEMORY_NEW(Color_HSLA,
        pstate,
        ARGVAL("$hue"),
        ARGVAL("$saturation"),
        ARGVAL("$lightness"),
        ARGVAL("$alpha"));

    }

    /////////////////////////////////////////////////////////////////////////
    // Query functions
    /////////////////////////////////////////////////////////////////////////

    Signature hue_sig = "hue($color)";
    BUILT_IN(hue)
    {
      Color_HSLA_Obj col = ARG("$color", Color)->toHSLA();
      return SASS_MEMORY_NEW(Number, pstate, col->h(), "deg");
    }

    Signature saturation_sig = "saturation($color)";
    BUILT_IN(saturation)
    {
      Color_HSLA_Obj col = ARG("$color", Color)->toHSLA();
      return SASS_MEMORY_NEW(Number, pstate, col->s(), "%");
    }

    Signature lightness_sig = "lightness($color)";
    BUILT_IN(lightness)
    {
      Color_HSLA_Obj col = ARG("$color", Color)->toHSLA();
      return SASS_MEMORY_NEW(Number, pstate, col->l(), "%");
    }

    /////////////////////////////////////////////////////////////////////////
    // HSL manipulation functions
    /////////////////////////////////////////////////////////////////////////

    Signature adjust_hue_sig = "adjust-hue($color, $degrees)";
    BUILT_IN(adjust_hue)
    {
      Color* col = ARG("$color", Color);
      double degrees = ARGVAL("$degrees");
      Color_HSLA_Obj copy = col->copyAsHSLA();
      copy->h(absmod(copy->h() + degrees, 360.0));
      return copy.detach();
    }

    Signature lighten_sig = "lighten($color, $amount)";
    BUILT_IN(lighten)
    {
      Color* col = ARG("$color", Color);
      double amount = DARG_U_PRCT("$amount");
      Color_HSLA_Obj copy = col->copyAsHSLA();
      copy->l(clip(copy->l() + amount, 0.0, 100.0));
      return copy.detach();

    }

    Signature darken_sig = "darken($color, $amount)";
    BUILT_IN(darken)
    {
      Color* col = ARG("$color", Color);
      double amount = DARG_U_PRCT("$amount");
      Color_HSLA_Obj copy = col->copyAsHSLA();
      copy->l(clip(copy->l() - amount, 0.0, 100.0));
      return copy.detach();
    }

    Signature saturate_sig = "saturate($color, $amount: false)";
    BUILT_IN(saturate)
    {
      // CSS3 filter function overload: pass literal through directly
      if (!Cast<Number>(env["$amount"])) {
        return SASS_MEMORY_NEW(String_Quoted, pstate, "saturate(" + env["$color"]->to_string(ctx.c_options) + ")");
      }

      Color* col = ARG("$color", Color);
      double amount = DARG_U_PRCT("$amount");
      Color_HSLA_Obj copy = col->copyAsHSLA();
      copy->s(clip(copy->s() + amount, 0.0, 100.0));
      return copy.detach();
    }

    Signature desaturate_sig = "desaturate($color, $amount)";
    BUILT_IN(desaturate)
    {
      Color* col = ARG("$color", Color);
      double amount = DARG_U_PRCT("$amount");
      Color_HSLA_Obj copy = col->copyAsHSLA();
      copy->s(clip(copy->s() - amount, 0.0, 100.0));
      return copy.detach();
    }

    Signature grayscale_sig = "grayscale($color)";
    BUILT_IN(grayscale)
    {
      // CSS3 filter function overload: pass literal through directly
      Number* amount = Cast<Number>(env["$color"]);
      if (amount) {
        return SASS_MEMORY_NEW(String_Quoted, pstate, "grayscale(" + amount->to_string(ctx.c_options) + ")");
      }

      Color* col = ARG("$color", Color);
      Color_HSLA_Obj copy = col->copyAsHSLA();
      copy->s(0.0); // just reset saturation
      return copy.detach();
    }

    /////////////////////////////////////////////////////////////////////////
    // Misc manipulation functions
    /////////////////////////////////////////////////////////////////////////

    Signature complement_sig = "complement($color)";
    BUILT_IN(complement)
    {
      Color* col = ARG("$color", Color);
      Color_HSLA_Obj copy = col->copyAsHSLA();
      copy->h(absmod(copy->h() - 180.0, 360.0));
      return copy.detach();
    }

    Signature invert_sig = "invert($color, $weight: 100%)";
    BUILT_IN(invert)
    {
      // CSS3 filter function overload: pass literal through directly
      Number* amount = Cast<Number>(env["$color"]);
      double weight = DARG_U_PRCT("$weight");
      if (amount) {
        // TODO: does not throw on 100% manually passed as value
        if (weight < 100.0) {
          error("Only one argument may be passed to the plain-CSS invert() function.", pstate, traces);
        }
        return SASS_MEMORY_NEW(String_Quoted, pstate, "invert(" + amount->to_string(ctx.c_options) + ")");
      }

      Color* col = ARG("$color", Color);
      Color_RGBA_Obj inv = col->copyAsRGBA();
      inv->r(clip(255.0 - inv->r(), 0.0, 255.0));
      inv->g(clip(255.0 - inv->g(), 0.0, 255.0));
      inv->b(clip(255.0 - inv->b(), 0.0, 255.0));
      return colormix(ctx, pstate, inv, col, weight);
    }

    /////////////////////////////////////////////////////////////////////////
    // Opacity functions
    /////////////////////////////////////////////////////////////////////////

    Signature alpha_sig = "alpha($color)";
    Signature opacity_sig = "opacity($color)";
    BUILT_IN(alpha)
    {
      String_Constant* ie_kwd = Cast<String_Constant>(env["$color"]);
      if (ie_kwd) {
        return SASS_MEMORY_NEW(String_Quoted, pstate, "alpha(" + ie_kwd->value() + ")");
      }

      // CSS3 filter function overload: pass literal through directly
      Number* amount = Cast<Number>(env["$color"]);
      if (amount) {
        return SASS_MEMORY_NEW(String_Quoted, pstate, "opacity(" + amount->to_string(ctx.c_options) + ")");
      }

      return SASS_MEMORY_NEW(Number, pstate, ARG("$color", Color)->a());
    }

    Signature opacify_sig = "opacify($color, $amount)";
    Signature fade_in_sig = "fade-in($color, $amount)";
    BUILT_IN(opacify)
    {
      Color* col = ARG("$color", Color);
      double amount = DARG_U_FACT("$amount");
      Color_Obj copy = SASS_MEMORY_COPY(col);
      copy->a(clip(col->a() + amount, 0.0, 1.0));
      return copy.detach();
    }

    Signature transparentize_sig = "transparentize($color, $amount)";
    Signature fade_out_sig = "fade-out($color, $amount)";
    BUILT_IN(transparentize)
    {
      Color* col = ARG("$color", Color);
      double amount = DARG_U_FACT("$amount");
      Color_Obj copy = SASS_MEMORY_COPY(col);
      copy->a(std::max(col->a() - amount, 0.0));
      return copy.detach();
    }

    ////////////////////////
    // OTHER COLOR FUNCTIONS
    ////////////////////////

    Signature adjust_color_sig = "adjust-color($color, $red: false, $green: false, $blue: false, $hue: false, $saturation: false, $lightness: false, $alpha: false)";
    BUILT_IN(adjust_color)
    {
      Color* col = ARG("$color", Color);
      Number* r = Cast<Number>(env["$red"]);
      Number* g = Cast<Number>(env["$green"]);
      Number* b = Cast<Number>(env["$blue"]);
      Number* h = Cast<Number>(env["$hue"]);
      Number* s = Cast<Number>(env["$saturation"]);
      Number* l = Cast<Number>(env["$lightness"]);
      Number* a = Cast<Number>(env["$alpha"]);

      bool rgb = r || g || b;
      bool hsl = h || s || l;

      if (rgb && hsl) {
        error("Cannot specify HSL and RGB values for a color at the same time for `adjust-color'", pstate, traces);
      }
      else if (rgb) {
        Color_RGBA_Obj c = col->copyAsRGBA();
        if (r) c->r(c->r() + DARG_R_BYTE("$red"));
        if (g) c->g(c->g() + DARG_R_BYTE("$green"));
        if (b) c->b(c->b() + DARG_R_BYTE("$blue"));
        if (a) c->a(c->a() + DARG_R_FACT("$alpha"));
        return c.detach();
      }
      else if (hsl) {
        Color_HSLA_Obj c = col->copyAsHSLA();
        if (h) c->h(c->h() + absmod(h->value(), 360.0));
        if (s) c->s(c->s() + DARG_R_PRCT("$saturation"));
        if (l) c->l(c->l() + DARG_R_PRCT("$lightness"));
        if (a) c->a(c->a() + DARG_R_FACT("$alpha"));
        return c.detach();
      }
      else if (a) {
        Color_Obj c = SASS_MEMORY_COPY(col);
        c->a(c->a() + DARG_R_FACT("$alpha"));
        c->a(clip(c->a(), 0.0, 1.0));
        return c.detach();
      }
      error("not enough arguments for `adjust-color'", pstate, traces);
      // unreachable
      return col;
    }

    Signature scale_color_sig = "scale-color($color, $red: false, $green: false, $blue: false, $hue: false, $saturation: false, $lightness: false, $alpha: false)";
    BUILT_IN(scale_color)
    {
      Color* col = ARG("$color", Color);
      Number* r = Cast<Number>(env["$red"]);
      Number* g = Cast<Number>(env["$green"]);
      Number* b = Cast<Number>(env["$blue"]);
      Number* h = Cast<Number>(env["$hue"]);
      Number* s = Cast<Number>(env["$saturation"]);
      Number* l = Cast<Number>(env["$lightness"]);
      Number* a = Cast<Number>(env["$alpha"]);

      bool rgb = r || g || b;
      bool hsl = h || s || l;

      if (rgb && hsl) {
        error("Cannot specify HSL and RGB values for a color at the same time for `scale-color'", pstate, traces);
      }
      else if (rgb) {
        Color_RGBA_Obj c = col->copyAsRGBA();
        double rscale = (r ? DARG_R_PRCT("$red") : 0.0) / 100.0;
        double gscale = (g ? DARG_R_PRCT("$green") : 0.0) / 100.0;
        double bscale = (b ? DARG_R_PRCT("$blue") : 0.0) / 100.0;
        double ascale = (a ? DARG_R_PRCT("$alpha") : 0.0) / 100.0;
        if (rscale) c->r(c->r() + rscale * (rscale > 0.0 ? 255.0 - c->r() : c->r()));
        if (gscale) c->g(c->g() + gscale * (gscale > 0.0 ? 255.0 - c->g() : c->g()));
        if (bscale) c->b(c->b() + bscale * (bscale > 0.0 ? 255.0 - c->b() : c->b()));
        if (ascale) c->a(c->a() + ascale * (ascale > 0.0 ? 1.0 - c->a() : c->a()));
        return c.detach();
      }
      else if (hsl) {
        Color_HSLA_Obj c = col->copyAsHSLA();
        double hscale = (h ? DARG_R_PRCT("$hue") : 0.0) / 100.0;
        double sscale = (s ? DARG_R_PRCT("$saturation") : 0.0) / 100.0;
        double lscale = (l ? DARG_R_PRCT("$lightness") : 0.0) / 100.0;
        double ascale = (a ? DARG_R_PRCT("$alpha") : 0.0) / 100.0;
        if (hscale) c->h(c->h() + hscale * (hscale > 0.0 ? 360.0 - c->h() : c->h()));
        if (sscale) c->s(c->s() + sscale * (sscale > 0.0 ? 100.0 - c->s() : c->s()));
        if (lscale) c->l(c->l() + lscale * (lscale > 0.0 ? 100.0 - c->l() : c->l()));
        if (ascale) c->a(c->a() + ascale * (ascale > 0.0 ? 1.0 - c->a() : c->a()));
        return c.detach();
      }
      else if (a) {
        Color_Obj c = SASS_MEMORY_COPY(col);
        double ascale = DARG_R_PRCT("$alpha") / 100.0;
        c->a(c->a() + ascale * (ascale > 0.0 ? 1.0 - c->a() : c->a()));
        c->a(clip(c->a(), 0.0, 1.0));
        return c.detach();
      }
      error("not enough arguments for `scale-color'", pstate, traces);
      // unreachable
      return col;
    }

    Signature change_color_sig = "change-color($color, $red: false, $green: false, $blue: false, $hue: false, $saturation: false, $lightness: false, $alpha: false)";
    BUILT_IN(change_color)
    {
      Color* col = ARG("$color", Color);
      Number* r = Cast<Number>(env["$red"]);
      Number* g = Cast<Number>(env["$green"]);
      Number* b = Cast<Number>(env["$blue"]);
      Number* h = Cast<Number>(env["$hue"]);
      Number* s = Cast<Number>(env["$saturation"]);
      Number* l = Cast<Number>(env["$lightness"]);
      Number* a = Cast<Number>(env["$alpha"]);

      bool rgb = r || g || b;
      bool hsl = h || s || l;

      if (rgb && hsl) {
        error("Cannot specify HSL and RGB values for a color at the same time for `change-color'", pstate, traces);
      }
      else if (rgb) {
        Color_RGBA_Obj c = col->copyAsRGBA();
        if (r) c->r(DARG_U_BYTE("$red"));
        if (g) c->g(DARG_U_BYTE("$green"));
        if (b) c->b(DARG_U_BYTE("$blue"));
        if (a) c->a(DARG_U_FACT("$alpha"));
        return c.detach();
      }
      else if (hsl) {
        Color_HSLA_Obj c = col->copyAsHSLA();
        if (h) c->h(absmod(h->value(), 360.0));
        if (s) c->s(DARG_U_PRCT("$saturation"));
        if (l) c->l(DARG_U_PRCT("$lightness"));
        if (a) c->a(DARG_U_FACT("$alpha"));
        return c.detach();
      }
      else if (a) {
        Color_Obj c = SASS_MEMORY_COPY(col);
        c->a(clip(DARG_U_FACT("$alpha"), 0.0, 1.0));
        return c.detach();
      }
      error("not enough arguments for `change-color'", pstate, traces);
      // unreachable
      return col;
    }

    Signature ie_hex_str_sig = "ie-hex-str($color)";
    BUILT_IN(ie_hex_str)
    {
      Color* col = ARG("$color", Color);
      Color_RGBA_Obj c = col->toRGBA();
      double r = clip(c->r(), 0.0, 255.0);
      double g = clip(c->g(), 0.0, 255.0);
      double b = clip(c->b(), 0.0, 255.0);
      double a = clip(c->a(), 0.0, 1.0) * 255.0;

      sass::ostream ss;
      ss << '#' << std::setw(2) << std::setfill('0');
      ss << std::hex << std::setw(2) << static_cast<unsigned long>(Sass::round(a, ctx.c_options.precision));
      ss << std::hex << std::setw(2) << static_cast<unsigned long>(Sass::round(r, ctx.c_options.precision));
      ss << std::hex << std::setw(2) << static_cast<unsigned long>(Sass::round(g, ctx.c_options.precision));
      ss << std::hex << std::setw(2) << static_cast<unsigned long>(Sass::round(b, ctx.c_options.precision));

      sass::string result = ss.str();
      Util::ascii_str_toupper(&result);
      return SASS_MEMORY_NEW(String_Quoted, pstate, result);
    }

  }

}
