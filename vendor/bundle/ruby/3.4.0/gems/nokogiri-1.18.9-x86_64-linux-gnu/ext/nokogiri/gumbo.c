//
//  Copyright 2013-2021 Sam Ruby, Stephen Checkoway
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

//
// nokogumbo.c defines the following:
//
//   class Nokogumbo
//     def parse(utf8_string) # returns Nokogiri::HTML5::Document
//   end
//
// Processing starts by calling gumbo_parse_with_options. The resulting document tree
// is then walked, a parallel libxml2 tree is constructed, and the final document is
// then wrapped using noko_xml_document_wrap. This approach reduces memory and CPU
// requirements as Ruby objects are only built when necessary.
//

#include <nokogiri.h>

#include "nokogiri_gumbo.h"

VALUE cNokogiriHtml5Document;

// Interned symbols
static ID internal_subset;
static ID parent;

#include <nokogiri.h>
#include <libxml/tree.h>
#include <libxml/HTMLtree.h>

// URI = system id
// external id = public id
static xmlDocPtr
new_html_doc(const char *dtd_name, const char *system, const char *public)
{
  // These two libxml2 functions take the public and system ids in
  // opposite orders.
  htmlDocPtr doc = htmlNewDocNoDtD(/* URI */ NULL, /* ExternalID */NULL);
  assert(doc);
  if (dtd_name) {
    xmlCreateIntSubset(doc, (const xmlChar *)dtd_name, (const xmlChar *)public, (const xmlChar *)system);
  }
  return doc;
}

static xmlNodePtr
get_parent(xmlNodePtr node)
{
  return node->parent;
}

static GumboOutput *
perform_parse(const GumboOptions *options, VALUE input)
{
  assert(RTEST(input));
  Check_Type(input, T_STRING);
  GumboOutput *output = gumbo_parse_with_options(
                          options,
                          RSTRING_PTR(input),
                          (size_t)RSTRING_LEN(input)
                        );

  const char *status_string = gumbo_status_to_string(output->status);
  switch (output->status) {
    case GUMBO_STATUS_OK:
      break;
    case GUMBO_STATUS_TOO_MANY_ATTRIBUTES:
    case GUMBO_STATUS_TREE_TOO_DEEP:
      gumbo_destroy_output(output);
      rb_raise(rb_eArgError, "%s", status_string);
    case GUMBO_STATUS_OUT_OF_MEMORY:
      gumbo_destroy_output(output);
      rb_raise(rb_eNoMemError, "%s", status_string);
  }
  return output;
}

static xmlNsPtr
lookup_or_add_ns(
  xmlDocPtr doc,
  xmlNodePtr root,
  const char *href,
  const char *prefix
)
{
  xmlNsPtr ns = xmlSearchNs(doc, root, (const xmlChar *)prefix);
  if (ns) {
    return ns;
  }
  return xmlNewNs(root, (const xmlChar *)href, (const xmlChar *)prefix);
}

static void
set_line(xmlNodePtr node, size_t line)
{
  // libxml2 uses 65535 to mean look elsewhere for the line number on some
  // nodes.
  if (line < 65535) {
    node->line = (unsigned short)line;
  }
}

// Construct an XML tree rooted at xml_output_node from the Gumbo tree rooted
// at gumbo_node.
static void
build_tree(
  xmlDocPtr doc,
  xmlNodePtr xml_output_node,
  const GumboNode *gumbo_node
)
{
  xmlNodePtr xml_root = NULL;
  xmlNodePtr xml_node = xml_output_node;
  size_t child_index = 0;

  while (true) {
    assert(gumbo_node != NULL);
    const GumboVector *children = gumbo_node->type == GUMBO_NODE_DOCUMENT ?
                                  &gumbo_node->v.document.children : &gumbo_node->v.element.children;
    if (child_index >= children->length) {
      // Move up the tree and to the next child.
      if (xml_node == xml_output_node) {
        // We've built as much of the tree as we can.
        return;
      }
      child_index = gumbo_node->index_within_parent + 1;
      gumbo_node = gumbo_node->parent;
      xml_node = get_parent(xml_node);
      // Children of fragments don't share the same root, so reset it and
      // it'll be set below. In the non-fragment case, this will only happen
      // after the html element has been finished at which point there are no
      // further elements.
      if (xml_node == xml_output_node) {
        xml_root = NULL;
      }
      continue;
    }
    const GumboNode *gumbo_child = children->data[child_index++];
    xmlNodePtr xml_child;

    switch (gumbo_child->type) {
      case GUMBO_NODE_DOCUMENT:
        abort(); // Bug in Gumbo.

      case GUMBO_NODE_TEXT:
      case GUMBO_NODE_WHITESPACE:
        xml_child = xmlNewDocText(doc, (const xmlChar *)gumbo_child->v.text.text);
        set_line(xml_child, gumbo_child->v.text.start_pos.line);
        xmlAddChild(xml_node, xml_child);
        break;

      case GUMBO_NODE_CDATA:
        xml_child = xmlNewCDataBlock(doc, (const xmlChar *)gumbo_child->v.text.text,
                                     (int) strlen(gumbo_child->v.text.text));
        set_line(xml_child, gumbo_child->v.text.start_pos.line);
        xmlAddChild(xml_node, xml_child);
        break;

      case GUMBO_NODE_COMMENT:
        xml_child = xmlNewDocComment(doc, (const xmlChar *)gumbo_child->v.text.text);
        set_line(xml_child, gumbo_child->v.text.start_pos.line);
        xmlAddChild(xml_node, xml_child);
        break;

      case GUMBO_NODE_TEMPLATE:
      // XXX: Should create a template element and a new DocumentFragment
      case GUMBO_NODE_ELEMENT: {
        xml_child = xmlNewDocNode(doc, NULL, (const xmlChar *)gumbo_child->v.element.name, NULL);
        set_line(xml_child, gumbo_child->v.element.start_pos.line);
        if (xml_root == NULL) {
          xml_root = xml_child;
        }
        xmlNsPtr ns = NULL;
        switch (gumbo_child->v.element.tag_namespace) {
          case GUMBO_NAMESPACE_HTML:
            break;
          case GUMBO_NAMESPACE_SVG:
            ns = lookup_or_add_ns(doc, xml_root, "http://www.w3.org/2000/svg", "svg");
            break;
          case GUMBO_NAMESPACE_MATHML:
            ns = lookup_or_add_ns(doc, xml_root, "http://www.w3.org/1998/Math/MathML", "math");
            break;
        }
        if (ns != NULL) {
          xmlSetNs(xml_child, ns);
        }
        xmlAddChild(xml_node, xml_child);

        // Add the attributes.
        const GumboVector *attrs = &gumbo_child->v.element.attributes;
        for (size_t i = 0; i < attrs->length; i++) {
          const GumboAttribute *attr = attrs->data[i];

          switch (attr->attr_namespace) {
            case GUMBO_ATTR_NAMESPACE_XLINK:
              ns = lookup_or_add_ns(doc, xml_root, "http://www.w3.org/1999/xlink", "xlink");
              break;

            case GUMBO_ATTR_NAMESPACE_XML:
              ns = lookup_or_add_ns(doc, xml_root, "http://www.w3.org/XML/1998/namespace", "xml");
              break;

            case GUMBO_ATTR_NAMESPACE_XMLNS:
              ns = lookup_or_add_ns(doc, xml_root, "http://www.w3.org/2000/xmlns/", "xmlns");
              break;

            default:
              ns = NULL;
          }
          xmlNewNsProp(xml_child, ns, (const xmlChar *)attr->name, (const xmlChar *)attr->value);
        }

        // Add children for this element.
        child_index = 0;
        gumbo_node = gumbo_child;
        xml_node = xml_child;
      }
    }
  }
}

static void
add_errors(const GumboOutput *output, VALUE rdoc, VALUE input, VALUE url)
{
  const char *input_str = RSTRING_PTR(input);
  size_t input_len = (size_t)RSTRING_LEN(input);

  // Add parse errors to rdoc.
  if (output->errors.length) {
    const GumboVector *errors = &output->errors;
    VALUE rerrors = rb_ary_new2(errors->length);

    for (size_t i = 0; i < errors->length; i++) {
      GumboError *err = errors->data[i];
      GumboSourcePosition position = gumbo_error_position(err);
      char *msg;
      size_t size = gumbo_caret_diagnostic_to_string(err, input_str, input_len, &msg);
      VALUE err_str = rb_utf8_str_new(msg, (int)size);
      free(msg);
      VALUE syntax_error = rb_class_new_instance(1, &err_str, cNokogiriXmlSyntaxError);
      const char *error_code = gumbo_error_code(err);
      VALUE str1 = error_code ? rb_utf8_str_new_static(error_code, (int)strlen(error_code)) : Qnil;
      rb_iv_set(syntax_error, "@domain", INT2NUM(1)); // XML_FROM_PARSER
      rb_iv_set(syntax_error, "@code", INT2NUM(1));   // XML_ERR_INTERNAL_ERROR
      rb_iv_set(syntax_error, "@level", INT2NUM(2));  // XML_ERR_ERROR
      rb_iv_set(syntax_error, "@file", url);
      rb_iv_set(syntax_error, "@line", SIZET2NUM(position.line));
      rb_iv_set(syntax_error, "@str1", str1);
      rb_iv_set(syntax_error, "@str2", Qnil);
      rb_iv_set(syntax_error, "@str3", Qnil);
      rb_iv_set(syntax_error, "@int1", INT2NUM(0));
      rb_iv_set(syntax_error, "@column", SIZET2NUM(position.column));
      rb_ary_push(rerrors, syntax_error);
    }
    rb_iv_set(rdoc, "@errors", rerrors);
  }
}

typedef struct {
  GumboOutput *output;
  VALUE input;
  VALUE url_or_frag;
  VALUE klass;
  xmlDocPtr doc;
} ParseArgs;

static VALUE
parse_cleanup(VALUE parse_args)
{
  ParseArgs *args = (ParseArgs *)parse_args;
  gumbo_destroy_output(args->output);
  // Make sure garbage collection doesn't mark the objects as being live based
  // on references from the ParseArgs. This may be unnecessary.
  args->input = Qnil;
  args->url_or_frag = Qnil;
  if (args->doc != NULL) {
    xmlFreeDoc(args->doc);
  }
  return Qnil;
}

// Scan the keyword arguments for options common to the document and fragment
// parse.
static GumboOptions
common_options(VALUE kwargs)
{
  // The order of the keywords determines the order of the values below.
  // If this order is changed, then setting the options below must change as
  // well.
  ID keywords[] = {
    // Required keywords.
    rb_intern_const("max_attributes"),
    rb_intern_const("max_errors"),
    rb_intern_const("max_tree_depth"),

    // Optional keywords.
    rb_intern_const("parse_noscript_content_as_text"),
  };
  VALUE values[sizeof keywords / sizeof keywords[0]];

  // Extract the values coresponding to the required keywords. Raise an error
  // if required arguments are missing.
  rb_get_kwargs(kwargs, keywords, 3, 1, values);

  GumboOptions options = kGumboDefaultOptions;
  options.max_attributes = NUM2INT(values[0]);
  options.max_errors = NUM2INT(values[1]);

  // handle negative values
  int depth = NUM2INT(values[2]);
  options.max_tree_depth = depth < 0 ? UINT_MAX : (unsigned int)depth;

  options.parse_noscript_content_as_text = values[3] != Qundef && RTEST(values[3]);

  return options;
}

static VALUE parse_continue(VALUE parse_args);

/*
 *  @!visibility protected
 */
static VALUE
noko_gumbo_s_parse(int argc, VALUE *argv, VALUE _self)
{
  VALUE input, url, klass, kwargs;

  rb_scan_args(argc, argv, "3:", &input, &url, &klass, &kwargs);
  if (NIL_P(kwargs)) {
    kwargs = rb_hash_new();
  }

  GumboOptions options = common_options(kwargs);

  GumboOutput *output = perform_parse(&options, input);
  ParseArgs args = {
    .output = output,
    .input = input,
    .url_or_frag = url,
    .klass = klass,
    .doc = NULL,
  };

  return rb_ensure(parse_continue, (VALUE)(&args), parse_cleanup, (VALUE)(&args));
}

static VALUE
parse_continue(VALUE parse_args)
{
  ParseArgs *args = (ParseArgs *)parse_args;
  GumboOutput *output = args->output;
  xmlDocPtr doc;
  if (output->document->v.document.has_doctype) {
    const char *name   = output->document->v.document.name;
    const char *public = output->document->v.document.public_identifier;
    const char *system = output->document->v.document.system_identifier;
    public = public[0] ? public : NULL;
    system = system[0] ? system : NULL;
    doc = new_html_doc(name, system, public);
  } else {
    doc = new_html_doc(NULL, NULL, NULL);
  }
  args->doc = doc; // Make sure doc gets cleaned up if an error is thrown.
  build_tree(doc, (xmlNodePtr)doc, output->document);
  VALUE rdoc = noko_xml_document_wrap(args->klass, doc);
  rb_iv_set(rdoc, "@url", args->url_or_frag);
  rb_iv_set(rdoc, "@quirks_mode", INT2NUM(output->document->v.document.doc_type_quirks_mode));
  args->doc = NULL; // The Ruby runtime now owns doc so don't delete it.
  add_errors(output, rdoc, args->input, args->url_or_frag);
  return rdoc;
}

static int
lookup_namespace(VALUE node, bool require_known_ns)
{
  ID namespace, href;
  CONST_ID(namespace, "namespace");
  CONST_ID(href, "href");
  VALUE ns = rb_funcall(node, namespace, 0);

  if (NIL_P(ns)) {
    return GUMBO_NAMESPACE_HTML;
  }
  ns = rb_funcall(ns, href, 0);
  assert(RTEST(ns));
  Check_Type(ns, T_STRING);

  const char *href_ptr = RSTRING_PTR(ns);
  size_t href_len = (size_t)RSTRING_LEN(ns);
#define NAMESPACE_P(uri) (href_len == sizeof uri - 1 && !memcmp(href_ptr, uri, href_len))
  if (NAMESPACE_P("http://www.w3.org/1999/xhtml")) {
    return GUMBO_NAMESPACE_HTML;
  }
  if (NAMESPACE_P("http://www.w3.org/1998/Math/MathML")) {
    return GUMBO_NAMESPACE_MATHML;
  }
  if (NAMESPACE_P("http://www.w3.org/2000/svg")) {
    return GUMBO_NAMESPACE_SVG;
  }
#undef NAMESPACE_P
  if (require_known_ns) {
    rb_raise(rb_eArgError, "Unexpected namespace URI \"%*s\"", (int)href_len, href_ptr);
  }
  return -1;
}

static xmlNodePtr
extract_xml_node(VALUE node)
{
  xmlNodePtr xml_node;
  Noko_Node_Get_Struct(node, xmlNode, xml_node);
  return xml_node;
}

static VALUE fragment_continue(VALUE parse_args);

/*
 *  @!visibility protected
 */
static VALUE
noko_gumbo_s_fragment(int argc, VALUE *argv, VALUE _self)
{
  VALUE doc_fragment;
  VALUE tags;
  VALUE ctx;
  VALUE kwargs;
  ID name = rb_intern_const("name");
  const char *ctx_tag;
  GumboNamespaceEnum ctx_ns;
  GumboQuirksModeEnum quirks_mode;
  bool form = false;
  const char *encoding = NULL;

  rb_scan_args(argc, argv, "3:", &doc_fragment, &tags, &ctx, &kwargs);
  if (NIL_P(kwargs)) {
    kwargs = rb_hash_new();
  }

  GumboOptions options = common_options(kwargs);

  if (NIL_P(ctx)) {
    ctx_tag = "body";
    ctx_ns = GUMBO_NAMESPACE_HTML;
  } else if (TYPE(ctx) == T_STRING) {
    ctx_tag = StringValueCStr(ctx);
    ctx_ns = GUMBO_NAMESPACE_HTML;
    size_t len = (size_t)RSTRING_LEN(ctx);
    const char *colon = memchr(ctx_tag, ':', len);
    if (colon) {
      switch (colon - ctx_tag) {
        case 3:
          if (st_strncasecmp(ctx_tag, "svg", 3) != 0) {
            goto error;
          }
          ctx_ns = GUMBO_NAMESPACE_SVG;
          break;
        case 4:
          if (st_strncasecmp(ctx_tag, "html", 4) == 0) {
            ctx_ns = GUMBO_NAMESPACE_HTML;
          } else if (st_strncasecmp(ctx_tag, "math", 4) == 0) {
            ctx_ns = GUMBO_NAMESPACE_MATHML;
          } else {
            goto error;
          }
          break;
        default:
error:
          rb_raise(rb_eArgError, "Invalid context namespace '%*s'", (int)(colon - ctx_tag), ctx_tag);
      }
      ctx_tag = colon + 1;
    } else {
      // For convenience, put 'svg' and 'math' in their namespaces.
      if (len == 3 && st_strncasecmp(ctx_tag, "svg", 3) == 0) {
        ctx_ns = GUMBO_NAMESPACE_SVG;
      } else if (len == 4 && st_strncasecmp(ctx_tag, "math", 4) == 0) {
        ctx_ns = GUMBO_NAMESPACE_MATHML;
      }
    }

    // Check if it's a form.
    form = ctx_ns == GUMBO_NAMESPACE_HTML && st_strcasecmp(ctx_tag, "form") == 0;
  } else {
    ID element_ = rb_intern_const("element?");

    // Context fragment name.
    VALUE tag_name = rb_funcall(ctx, name, 0);
    assert(RTEST(tag_name));
    Check_Type(tag_name, T_STRING);
    ctx_tag = StringValueCStr(tag_name);

    // Context fragment namespace.
    ctx_ns = lookup_namespace(ctx, true);

    // Check for a form ancestor, including self.
    for (VALUE node = ctx;
         !NIL_P(node);
         node = rb_respond_to(node, parent) ? rb_funcall(node, parent, 0) : Qnil) {
      if (!RTEST(rb_funcall(node, element_, 0))) {
        continue;
      }
      VALUE element_name = rb_funcall(node, name, 0);
      if (RSTRING_LEN(element_name) == 4
          && !st_strcasecmp(RSTRING_PTR(element_name), "form")
          && lookup_namespace(node, false) == GUMBO_NAMESPACE_HTML) {
        form = true;
        break;
      }
    }

    // Encoding.
    if (ctx_ns == GUMBO_NAMESPACE_MATHML
        && RSTRING_LEN(tag_name) == 14
        && !st_strcasecmp(ctx_tag, "annotation-xml")) {
      VALUE enc = rb_funcall(ctx, rb_intern_const("[]"),
                             1,
                             rb_utf8_str_new_static("encoding", 8));
      if (RTEST(enc)) {
        Check_Type(enc, T_STRING);
        encoding = StringValueCStr(enc);
      }
    }
  }

  // Quirks mode.
  VALUE doc = rb_funcall(doc_fragment, rb_intern_const("document"), 0);
  VALUE dtd = rb_funcall(doc, internal_subset, 0);
  VALUE doc_quirks_mode = rb_iv_get(doc, "@quirks_mode");
  if (NIL_P(ctx) || (TYPE(ctx) == T_STRING) || NIL_P(doc_quirks_mode)) {
    quirks_mode = GUMBO_DOCTYPE_NO_QUIRKS;
  } else if (NIL_P(dtd)) {
    quirks_mode = GUMBO_DOCTYPE_QUIRKS;
  } else {
    VALUE dtd_name = rb_funcall(dtd, name, 0);
    VALUE pubid = rb_funcall(dtd, rb_intern_const("external_id"), 0);
    VALUE sysid = rb_funcall(dtd, rb_intern_const("system_id"), 0);
    quirks_mode = gumbo_compute_quirks_mode(
                    NIL_P(dtd_name) ? NULL : StringValueCStr(dtd_name),
                    NIL_P(pubid) ? NULL : StringValueCStr(pubid),
                    NIL_P(sysid) ? NULL : StringValueCStr(sysid)
                  );
  }

  // Perform a fragment parse.
  options.fragment_context = ctx_tag;
  options.fragment_namespace = ctx_ns;
  options.fragment_encoding = encoding;
  options.quirks_mode = quirks_mode;
  options.fragment_context_has_form_ancestor = form;

  // Add one to the max tree depth to account for the HTML element.
  if (options.max_tree_depth < UINT_MAX) { options.max_tree_depth++; }

  GumboOutput *output = perform_parse(&options, tags);
  ParseArgs args = {
    .output = output,
    .input = tags,
    .url_or_frag = doc_fragment,
    .doc = (xmlDocPtr)extract_xml_node(doc),
  };
  rb_ensure(fragment_continue, (VALUE)(&args), parse_cleanup, (VALUE)(&args));
  return Qnil;
}

static VALUE
fragment_continue(VALUE parse_args)
{
  ParseArgs *args = (ParseArgs *)parse_args;
  GumboOutput *output = args->output;
  VALUE doc_fragment = args->url_or_frag;
  xmlDocPtr xml_doc = args->doc;

  args->doc = NULL; // The Ruby runtime owns doc so make sure we don't delete it.
  xmlNodePtr xml_frag = extract_xml_node(doc_fragment);
  build_tree(xml_doc, xml_frag, output->root);
  rb_iv_set(doc_fragment, "@quirks_mode", INT2NUM(output->document->v.document.doc_type_quirks_mode));
  add_errors(output, doc_fragment, args->input, rb_utf8_str_new_static("#fragment", 9));
  return Qnil;
}

// Initialize the Nokogumbo class and fetch constants we will use later.
void
noko_init_gumbo(void)
{
  // Class constants.
  cNokogiriHtml5Document = rb_define_class_under(mNokogiriHtml5, "Document", cNokogiriHtml4Document);
  rb_gc_register_mark_object(cNokogiriHtml5Document);

  // Interned symbols.
  internal_subset = rb_intern_const("internal_subset");
  parent = rb_intern_const("parent");

  // Define Nokogumbo module with parse and fragment methods.
  rb_define_singleton_method(mNokogiriGumbo, "parse", noko_gumbo_s_parse, -1);
  rb_define_singleton_method(mNokogiriGumbo, "fragment", noko_gumbo_s_fragment, -1);
}

// vim: set shiftwidth=2 softtabstop=2 tabstop=8 expandtab:
