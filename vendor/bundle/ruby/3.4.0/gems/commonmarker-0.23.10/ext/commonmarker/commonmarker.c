#include "commonmarker.h"
#include "cmark-gfm.h"
#include "houdini.h"
#include "node.h"
#include "registry.h"
#include "parser.h"
#include "syntax_extension.h"
#include "cmark-gfm-core-extensions.h"

static VALUE rb_eNodeError;
static VALUE rb_cNode;

static VALUE sym_document;
static VALUE sym_blockquote;
static VALUE sym_list;
static VALUE sym_list_item;
static VALUE sym_code_block;
static VALUE sym_html;
static VALUE sym_paragraph;
static VALUE sym_header;
static VALUE sym_hrule;
static VALUE sym_text;
static VALUE sym_softbreak;
static VALUE sym_linebreak;
static VALUE sym_code;
static VALUE sym_inline_html;
static VALUE sym_emph;
static VALUE sym_strong;
static VALUE sym_link;
static VALUE sym_image;
static VALUE sym_footnote_reference;
static VALUE sym_footnote_definition;

static VALUE sym_bullet_list;
static VALUE sym_ordered_list;

static VALUE sym_left;
static VALUE sym_right;
static VALUE sym_center;

static VALUE encode_utf8_string(const char *c_string) {
  VALUE string = rb_str_new2(c_string);
  int enc = rb_enc_find_index("UTF-8");
  rb_enc_associate_index(string, enc);
  return string;
}

/* Encode a C string using the encoding from Ruby string +source+. */
static VALUE encode_source_string(const char *c_string, VALUE source) {
  VALUE string = rb_str_new2(c_string);
  rb_enc_copy(string, source);
  return string;
}

static void rb_mark_c_struct(void *data) {
  cmark_node *node = data;
  cmark_node *child;

  /* Mark the parent to make sure that the tree won't be freed as
     long as a child node is referenced. */
  cmark_node *parent = cmark_node_parent(node);
  if (parent) {
    void *user_data = cmark_node_get_user_data(parent);
    if (!user_data) {
      /* This should never happen. Child can nodes can only
         be returned from parents that already are
         associated with a Ruby object. */
      fprintf(stderr, "parent without user_data\n");
      abort();
    }
    rb_gc_mark((VALUE)user_data);
  }

  /* Mark all children to make sure their cached Ruby objects won't
     be freed. */
  for (child = cmark_node_first_child(node); child != NULL;
       child = cmark_node_next(child)) {
    void *user_data = cmark_node_get_user_data(child);
    if (user_data)
      rb_gc_mark((VALUE)user_data);
  }
}

static void rb_free_c_struct(void *data) {
  /* It's important that the `free` function does not inspect the
     node data, as it may be part of a tree that was already freed. */
  cmark_node_free(data);
}

static VALUE rb_node_to_value(cmark_node *node) {
  void *user_data;
  RUBY_DATA_FUNC free_func;
  VALUE val;

  if (node == NULL)
    return Qnil;

  user_data = cmark_node_get_user_data(node);
  if (user_data)
    return (VALUE)user_data;

  /* Only free tree roots. */
  free_func = cmark_node_parent(node) ? NULL : rb_free_c_struct;
  val = Data_Wrap_Struct(rb_cNode, rb_mark_c_struct, free_func, node);
  cmark_node_set_user_data(node, (void *)val);

  return val;
}

/* If the node structure is changed, the finalizers must be updated. */

static void rb_parent_added(VALUE val) { RDATA(val)->dfree = NULL; }

static void rb_parent_removed(VALUE val) {
  RDATA(val)->dfree = rb_free_c_struct;
}

static cmark_parser *prepare_parser(VALUE rb_options, VALUE rb_extensions) {
  int options;
  VALUE rb_ext_name;
  int i;

  FIXNUM_P(rb_options);
  options = FIX2INT(rb_options);

  Check_Type(rb_extensions, T_ARRAY);

  cmark_parser *parser = cmark_parser_new(options);

  for (i = 0; i < RARRAY_LEN(rb_extensions); ++i) {
    rb_ext_name = rb_ary_entry(rb_extensions, i);

    if (!SYMBOL_P(rb_ext_name)) {
      cmark_parser_free(parser);
      rb_raise(rb_eTypeError, "extension names should be Symbols; got a %"PRIsVALUE"", rb_obj_class(rb_ext_name));
    }

    cmark_syntax_extension *syntax_extension =
      cmark_find_syntax_extension(rb_id2name(SYM2ID(rb_ext_name)));

    if (!syntax_extension) {
      cmark_parser_free(parser);
      rb_raise(rb_eArgError, "extension %s not found", rb_id2name(SYM2ID(rb_ext_name)));
    }

    cmark_parser_attach_syntax_extension(parser, syntax_extension);
  }

  return parser;
}

/*
 * Internal: Parses a Markdown string into an HTML string.
 *
 */
static VALUE rb_markdown_to_html(VALUE self, VALUE rb_text, VALUE rb_options, VALUE rb_extensions) {
  char *html;
  cmark_parser *parser;
  cmark_node *doc;

  Check_Type(rb_text, T_STRING);

  parser = prepare_parser(rb_options, rb_extensions);

  cmark_parser_feed(parser, StringValuePtr(rb_text), RSTRING_LEN(rb_text));
  doc = cmark_parser_finish(parser);

  if (doc == NULL) {
    cmark_parser_free(parser);
    rb_raise(rb_eNodeError, "error parsing document");
  }

  html = cmark_render_html(doc, parser->options, parser->syntax_extensions);

  cmark_parser_free(parser);
  cmark_node_free(doc);

  return rb_utf8_str_new_cstr(html);
}

/*
 * Internal: Parses a Markdown string into an HTML string.
 *
 */
static VALUE rb_markdown_to_xml(VALUE self, VALUE rb_text, VALUE rb_options, VALUE rb_extensions) {
  char *xml;
  cmark_parser *parser;
  cmark_node *doc;

  Check_Type(rb_text, T_STRING);

  parser = prepare_parser(rb_options, rb_extensions);

  cmark_parser_feed(parser, StringValuePtr(rb_text), RSTRING_LEN(rb_text));
  doc = cmark_parser_finish(parser);

  if (doc == NULL) {
    cmark_parser_free(parser);
    rb_raise(rb_eNodeError, "error parsing document");
  }

  xml = cmark_render_xml(doc, parser->options);

  cmark_parser_free(parser);
  cmark_node_free(doc);

  return rb_utf8_str_new_cstr(xml);
}

/*
 * Internal: Creates a node based on a node type.
 *
 * type -  A {Symbol} representing the node to be created. Must be one of the
 * following:
 * - `:document`
 * - `:blockquote`
 * - `:list`
 * - `:list_item`
 * - `:code_block`
 * - `:html`
 * - `:paragraph`
 * - `:header`
 * - `:hrule`
 * - `:text`
 * - `:softbreak`
 * - `:linebreak`
 * - `:code`
 * - `:inline_html`
 * - `:emph`
 * - `:strong`
 * - `:link`
 * - `:image`
 */
static VALUE rb_node_new(VALUE self, VALUE type) {
  cmark_node_type node_type = 0;
  cmark_node *node;

  Check_Type(type, T_SYMBOL);

  if (type == sym_document)
    node_type = CMARK_NODE_DOCUMENT;
  else if (type == sym_blockquote)
    node_type = CMARK_NODE_BLOCK_QUOTE;
  else if (type == sym_list)
    node_type = CMARK_NODE_LIST;
  else if (type == sym_list_item)
    node_type = CMARK_NODE_ITEM;
  else if (type == sym_code_block)
    node_type = CMARK_NODE_CODE_BLOCK;
  else if (type == sym_html)
    node_type = CMARK_NODE_HTML;
  else if (type == sym_paragraph)
    node_type = CMARK_NODE_PARAGRAPH;
  else if (type == sym_header)
    node_type = CMARK_NODE_HEADER;
  else if (type == sym_hrule)
    node_type = CMARK_NODE_HRULE;
  else if (type == sym_text)
    node_type = CMARK_NODE_TEXT;
  else if (type == sym_softbreak)
    node_type = CMARK_NODE_SOFTBREAK;
  else if (type == sym_linebreak)
    node_type = CMARK_NODE_LINEBREAK;
  else if (type == sym_code)
    node_type = CMARK_NODE_CODE;
  else if (type == sym_inline_html)
    node_type = CMARK_NODE_INLINE_HTML;
  else if (type == sym_emph)
    node_type = CMARK_NODE_EMPH;
  else if (type == sym_strong)
    node_type = CMARK_NODE_STRONG;
  else if (type == sym_link)
    node_type = CMARK_NODE_LINK;
  else if (type == sym_image)
    node_type = CMARK_NODE_IMAGE;
  else if (type == sym_footnote_reference)
    node_type = CMARK_NODE_FOOTNOTE_REFERENCE;
  else if (type == sym_footnote_definition)
    node_type = CMARK_NODE_FOOTNOTE_DEFINITION;
  else
    rb_raise(rb_eNodeError, "invalid node of type %d", node_type);

  node = cmark_node_new(node_type);
  if (node == NULL) {
    rb_raise(rb_eNodeError, "could not create node of type %d", node_type);
  }

  return rb_node_to_value(node);
}

/*
 * Internal: Parses a Markdown string into a document.
 *
 */
static VALUE rb_parse_document(VALUE self, VALUE rb_text, VALUE rb_len,
                               VALUE rb_options, VALUE rb_extensions) {
  char *text;
  int len;
  cmark_parser *parser;
  cmark_node *doc;
  Check_Type(rb_text, T_STRING);
  Check_Type(rb_len, T_FIXNUM);
  Check_Type(rb_options, T_FIXNUM);

  parser = prepare_parser(rb_options, rb_extensions);

  text = (char *)RSTRING_PTR(rb_text);
  len = FIX2INT(rb_len);

  cmark_parser_feed(parser, text, len);
  doc = cmark_parser_finish(parser);
  if (doc == NULL) {
    rb_raise(rb_eNodeError, "error parsing document");
  }
  cmark_parser_free(parser);

  return rb_node_to_value(doc);
}

/*
 * Public: Fetch the string contents of the node.
 *
 * Returns a {String}.
 */
static VALUE rb_node_get_string_content(VALUE self) {
  const char *text;
  cmark_node *node;
  Data_Get_Struct(self, cmark_node, node);

  text = cmark_node_get_literal(node);
  if (text == NULL) {
    rb_raise(rb_eNodeError, "could not get string content");
  }

  return encode_utf8_string(text);
}

/*
 * Public: Sets the string content of the node.
 *
 * string - A {String} containing new content.
 *
 * Raises NodeError if the string content can't be set.
 */
static VALUE rb_node_set_string_content(VALUE self, VALUE s) {
  char *text;
  cmark_node *node;
  Check_Type(s, T_STRING);

  Data_Get_Struct(self, cmark_node, node);
  text = StringValueCStr(s);

  if (!cmark_node_set_literal(node, text)) {
    rb_raise(rb_eNodeError, "could not set string content");
  }

  return Qnil;
}

/*
 * Public: Fetches the list type of the node.
 *
 * Returns a {Symbol} representing the node's type.
 */
static VALUE rb_node_get_type(VALUE self) {
  int node_type;
  cmark_node *node;
  VALUE symbol;
  const char *s;

  Data_Get_Struct(self, cmark_node, node);

  node_type = cmark_node_get_type(node);
  symbol = Qnil;

  switch (node_type) {
  case CMARK_NODE_DOCUMENT:
    symbol = sym_document;
    break;
  case CMARK_NODE_BLOCK_QUOTE:
    symbol = sym_blockquote;
    break;
  case CMARK_NODE_LIST:
    symbol = sym_list;
    break;
  case CMARK_NODE_ITEM:
    symbol = sym_list_item;
    break;
  case CMARK_NODE_CODE_BLOCK:
    symbol = sym_code_block;
    break;
  case CMARK_NODE_HTML:
    symbol = sym_html;
    break;
  case CMARK_NODE_PARAGRAPH:
    symbol = sym_paragraph;
    break;
  case CMARK_NODE_HEADER:
    symbol = sym_header;
    break;
  case CMARK_NODE_HRULE:
    symbol = sym_hrule;
    break;
  case CMARK_NODE_TEXT:
    symbol = sym_text;
    break;
  case CMARK_NODE_SOFTBREAK:
    symbol = sym_softbreak;
    break;
  case CMARK_NODE_LINEBREAK:
    symbol = sym_linebreak;
    break;
  case CMARK_NODE_CODE:
    symbol = sym_code;
    break;
  case CMARK_NODE_INLINE_HTML:
    symbol = sym_inline_html;
    break;
  case CMARK_NODE_EMPH:
    symbol = sym_emph;
    break;
  case CMARK_NODE_STRONG:
    symbol = sym_strong;
    break;
  case CMARK_NODE_LINK:
    symbol = sym_link;
    break;
  case CMARK_NODE_IMAGE:
    symbol = sym_image;
    break;
  case CMARK_NODE_FOOTNOTE_REFERENCE:
    symbol = sym_footnote_reference;
    break;
  case CMARK_NODE_FOOTNOTE_DEFINITION:
    symbol = sym_footnote_definition;
    break;
  default:
    if (node->extension) {
      s = node->extension->get_type_string_func(node->extension, node);
      return ID2SYM(rb_intern(s));
    }
    rb_raise(rb_eNodeError, "invalid node type %d", node_type);
  }

  return symbol;
}

/*
 * Public: Fetches the sourcepos of the node.
 *
 * Returns a {Hash} containing {Symbol} keys of the positions.
 */
static VALUE rb_node_get_sourcepos(VALUE self) {
  int start_line, start_column, end_line, end_column;
  VALUE result;

  cmark_node *node;
  Data_Get_Struct(self, cmark_node, node);

  start_line = cmark_node_get_start_line(node);
  start_column = cmark_node_get_start_column(node);
  end_line = cmark_node_get_end_line(node);
  end_column = cmark_node_get_end_column(node);

  result = rb_hash_new();
  rb_hash_aset(result, CSTR2SYM("start_line"), INT2NUM(start_line));
  rb_hash_aset(result, CSTR2SYM("start_column"), INT2NUM(start_column));
  rb_hash_aset(result, CSTR2SYM("end_line"), INT2NUM(end_line));
  rb_hash_aset(result, CSTR2SYM("end_column"), INT2NUM(end_column));

  return result;
}

/*
 * Public: Returns the type of the current pointer as a string.
 *
 * Returns a {String}.
 */
static VALUE rb_node_get_type_string(VALUE self) {
  cmark_node *node;
  Data_Get_Struct(self, cmark_node, node);

  return rb_str_new2(cmark_node_get_type_string(node));
}

/*
 * Internal: Unlinks the node from the tree (fixing pointers in
 * parents and siblings appropriately).
 */
static VALUE rb_node_unlink(VALUE self) {
  cmark_node *node;
  Data_Get_Struct(self, cmark_node, node);

  cmark_node_unlink(node);

  rb_parent_removed(self);

  return Qnil;
}

/* Public: Fetches the first child of the node.
 *
 * Returns a {Node} if a child exists, `nil` otherise.
 */
static VALUE rb_node_first_child(VALUE self) {
  cmark_node *node, *child;
  Data_Get_Struct(self, cmark_node, node);

  child = cmark_node_first_child(node);

  return rb_node_to_value(child);
}

/* Public: Fetches the next sibling of the node.
 *
 * Returns a {Node} if a sibling exists, `nil` otherwise.
 */
static VALUE rb_node_next(VALUE self) {
  cmark_node *node, *next;
  Data_Get_Struct(self, cmark_node, node);

  next = cmark_node_next(node);

  return rb_node_to_value(next);
}

/*
 * Public: Inserts a node as a sibling before the current node.
 *
 * sibling - A sibling {Node} to insert.
 *
 * Returns `true` if successful.
 * Raises NodeError if the node can't be inserted.
 */
static VALUE rb_node_insert_before(VALUE self, VALUE sibling) {
  cmark_node *node1, *node2;
  Data_Get_Struct(self, cmark_node, node1);

  Data_Get_Struct(sibling, cmark_node, node2);

  if (!cmark_node_insert_before(node1, node2)) {
    rb_raise(rb_eNodeError, "could not insert before");
  }

  rb_parent_added(sibling);

  return Qtrue;
}

/* Internal: Convert the node to an HTML string.
 *
 * Returns a {String}.
 */
static VALUE rb_render_html(VALUE self, VALUE rb_options, VALUE rb_extensions) {
  int options, extensions_len;
  VALUE rb_ext_name;
  int i;
  cmark_node *node;
  cmark_llist *extensions = NULL;
  cmark_mem *mem = cmark_get_default_mem_allocator();
  Check_Type(rb_options, T_FIXNUM);
  Check_Type(rb_extensions, T_ARRAY);

  options = FIX2INT(rb_options);
  extensions_len = RARRAY_LEN(rb_extensions);

  Data_Get_Struct(self, cmark_node, node);

  for (i = 0; i < extensions_len; ++i) {
    rb_ext_name = RARRAY_PTR(rb_extensions)[i];

    if (!SYMBOL_P(rb_ext_name)) {
      cmark_llist_free(mem, extensions);
      rb_raise(rb_eTypeError, "extension names should be Symbols; got a %"PRIsVALUE"", rb_obj_class(rb_ext_name));
    }

    cmark_syntax_extension *syntax_extension =
      cmark_find_syntax_extension(rb_id2name(SYM2ID(rb_ext_name)));

    if (!syntax_extension) {
      cmark_llist_free(mem, extensions);
      rb_raise(rb_eArgError, "extension %s not found\n", rb_id2name(SYM2ID(rb_ext_name)));
    }

    extensions = cmark_llist_append(mem, extensions, syntax_extension);
  }

  char *html = cmark_render_html(node, options, extensions);
  VALUE ruby_html = rb_str_new2(html);

  cmark_llist_free(mem, extensions);
  free(html);

  return ruby_html;
}

/* Internal: Convert the node to an XML string.
 *
 * Returns a {String}.
 */
static VALUE rb_render_xml(VALUE self, VALUE rb_options) {
  int options;
  cmark_node *node;
  Check_Type(rb_options, T_FIXNUM);

  options = FIX2INT(rb_options);

  Data_Get_Struct(self, cmark_node, node);

  char *xml = cmark_render_xml(node, options);
  VALUE ruby_xml = rb_str_new2(xml);

  free(xml);

  return ruby_xml;
}

/* Internal: Convert the node to a CommonMark string.
 *
 * Returns a {String}.
 */
static VALUE rb_render_commonmark(int argc, VALUE *argv, VALUE self) {
  VALUE rb_options, rb_width;
  rb_scan_args(argc, argv, "11", &rb_options, &rb_width);

  int width = 120;
  if (!NIL_P(rb_width)) {
    Check_Type(rb_width, T_FIXNUM);
    width = FIX2INT(rb_width);
  }

  int options;
  cmark_node *node;
  Check_Type(rb_options, T_FIXNUM);

  options = FIX2INT(rb_options);
  Data_Get_Struct(self, cmark_node, node);

  char *cmark = cmark_render_commonmark(node, options, width);
  VALUE ruby_cmark = rb_str_new2(cmark);
  free(cmark);

  return ruby_cmark;
}

/* Internal: Convert the node to a plain textstring.
 *
 * Returns a {String}.
 */
static VALUE rb_render_plaintext(int argc, VALUE *argv, VALUE self) {
  VALUE rb_options, rb_width;
  rb_scan_args(argc, argv, "11", &rb_options, &rb_width);

  int width = 120;
  if (!NIL_P(rb_width)) {
    Check_Type(rb_width, T_FIXNUM);
    width = FIX2INT(rb_width);
  }

  int options;
  cmark_node *node;
  Check_Type(rb_options, T_FIXNUM);

  options = FIX2INT(rb_options);
  Data_Get_Struct(self, cmark_node, node);

  char *text = cmark_render_plaintext(node, options, width);
  VALUE ruby_text = rb_str_new2(text);
  free(text);

  return ruby_text;
}

/*
 * Public: Inserts a node as a sibling after the current node.
 *
 * sibling - A sibling {Node} to insert.
 *
 * Returns `true` if successful.
 * Raises NodeError if the node can't be inserted.
 */
static VALUE rb_node_insert_after(VALUE self, VALUE sibling) {
  cmark_node *node1, *node2;
  Data_Get_Struct(self, cmark_node, node1);

  Data_Get_Struct(sibling, cmark_node, node2);

  if (!cmark_node_insert_after(node1, node2)) {
    rb_raise(rb_eNodeError, "could not insert after");
  }

  rb_parent_added(sibling);

  return Qtrue;
}

/*
 * Public: Inserts a node as the first child of the current node.
 *
 * child - A child {Node} to insert.
 *
 * Returns `true` if successful.
 * Raises NodeError if the node can't be inserted.
 */
static VALUE rb_node_prepend_child(VALUE self, VALUE child) {
  cmark_node *node1, *node2;
  Data_Get_Struct(self, cmark_node, node1);

  Data_Get_Struct(child, cmark_node, node2);

  if (!cmark_node_prepend_child(node1, node2)) {
    rb_raise(rb_eNodeError, "could not prepend child");
  }

  rb_parent_added(child);

  return Qtrue;
}

/*
 * Public: Inserts a node as the last child of the current node.
 *
 * child - A child {Node} to insert.
 *
 * Returns `true` if successful.
 * Raises NodeError if the node can't be inserted.
 */
static VALUE rb_node_append_child(VALUE self, VALUE child) {
  cmark_node *node1, *node2;
  Data_Get_Struct(self, cmark_node, node1);

  Data_Get_Struct(child, cmark_node, node2);

  if (!cmark_node_append_child(node1, node2)) {
    rb_raise(rb_eNodeError, "could not append child");
  }

  rb_parent_added(child);

  return Qtrue;
}

/* Public: Fetches the first child of the current node.
 *
 * Returns a {Node} if a child exists, `nil` otherise.
 */
static VALUE rb_node_last_child(VALUE self) {
  cmark_node *node, *child;
  Data_Get_Struct(self, cmark_node, node);

  child = cmark_node_last_child(node);

  return rb_node_to_value(child);
}

/* Public: Fetches the parent of the current node.
 *
 * Returns a {Node} if a parent exists, `nil` otherise.
 */
static VALUE rb_node_parent(VALUE self) {
  cmark_node *node, *parent;
  Data_Get_Struct(self, cmark_node, node);

  parent = cmark_node_parent(node);

  return rb_node_to_value(parent);
}

/* Public: Fetches the previous sibling of the current node.
 *
 * Returns a {Node} if a parent exists, `nil` otherise.
 */
static VALUE rb_node_previous(VALUE self) {
  cmark_node *node, *previous;
  Data_Get_Struct(self, cmark_node, node);

  previous = cmark_node_previous(node);

  return rb_node_to_value(previous);
}

/*
 * Public: Gets the URL of the current node (must be a `:link` or `:image`).
 *
 * Returns a {String}.
 * Raises a NodeError if the URL can't be retrieved.
 */
static VALUE rb_node_get_url(VALUE self) {
  const char *text;
  cmark_node *node;
  Data_Get_Struct(self, cmark_node, node);

  text = cmark_node_get_url(node);
  if (text == NULL) {
    rb_raise(rb_eNodeError, "could not get url");
  }

  return rb_str_new2(text);
}

/*
 * Public: Sets the URL of the current node (must be a `:link` or `:image`).
 *
 * url - A {String} representing the new URL
 *
 * Raises a NodeError if the URL can't be set.
 */
static VALUE rb_node_set_url(VALUE self, VALUE url) {
  cmark_node *node;
  char *text;
  Check_Type(url, T_STRING);

  Data_Get_Struct(self, cmark_node, node);
  text = StringValueCStr(url);

  if (!cmark_node_set_url(node, text)) {
    rb_raise(rb_eNodeError, "could not set url");
  }

  return Qnil;
}

/*
 * Public: Gets the title of the current node (must be a `:link` or `:image`).
 *
 * Returns a {String}.
 * Raises a NodeError if the title can't be retrieved.
 */
static VALUE rb_node_get_title(VALUE self) {
  const char *text;
  cmark_node *node;
  Data_Get_Struct(self, cmark_node, node);

  text = cmark_node_get_title(node);
  if (text == NULL) {
    rb_raise(rb_eNodeError, "could not get title");
  }

  return rb_str_new2(text);
}

/*
 * Public: Sets the title of the current node (must be a `:link` or `:image`).
 *
 * title - A {String} representing the new title
 *
 * Raises a NodeError if the title can't be set.
 */
static VALUE rb_node_set_title(VALUE self, VALUE title) {
  char *text;
  cmark_node *node;
  Check_Type(title, T_STRING);

  Data_Get_Struct(self, cmark_node, node);
  text = StringValueCStr(title);

  if (!cmark_node_set_title(node, text)) {
    rb_raise(rb_eNodeError, "could not set title");
  }

  return Qnil;
}

/*
 * Public: Gets the header level of the current node (must be a `:header`).
 *
 * Returns a {Number} representing the header level.
 * Raises a NodeError if the header level can't be retrieved.
 */
static VALUE rb_node_get_header_level(VALUE self) {
  int header_level;
  cmark_node *node;
  Data_Get_Struct(self, cmark_node, node);

  header_level = cmark_node_get_header_level(node);

  if (header_level == 0) {
    rb_raise(rb_eNodeError, "could not get header_level");
  }

  return INT2NUM(header_level);
}

/*
 * Public: Sets the header level of the current node (must be a `:header`).
 *
 * level - A {Number} representing the new header level
 *
 * Raises a NodeError if the header level can't be set.
 */
static VALUE rb_node_set_header_level(VALUE self, VALUE level) {
  int l;
  cmark_node *node;
  Check_Type(level, T_FIXNUM);

  Data_Get_Struct(self, cmark_node, node);
  l = FIX2INT(level);

  if (!cmark_node_set_header_level(node, l)) {
    rb_raise(rb_eNodeError, "could not set header_level");
  }

  return Qnil;
}

/*
 * Public: Gets the list type of the current node (must be a `:list`).
 *
 * Returns a {Symbol}.
 * Raises a NodeError if the title can't be retrieved.
 */
static VALUE rb_node_get_list_type(VALUE self) {
  int list_type;
  cmark_node *node;
  VALUE symbol;
  Data_Get_Struct(self, cmark_node, node);

  list_type = cmark_node_get_list_type(node);

  if (list_type == CMARK_BULLET_LIST) {
    symbol = sym_bullet_list;
  } else if (list_type == CMARK_ORDERED_LIST) {
    symbol = sym_ordered_list;
  } else {
    rb_raise(rb_eNodeError, "could not get list_type");
  }

  return symbol;
}

/*
 * Public: Sets the list type of the current node (must be a `:list`).
 *
 * level - A {Symbol} representing the new list type
 *
 * Raises a NodeError if the list type can't be set.
 */
static VALUE rb_node_set_list_type(VALUE self, VALUE list_type) {
  int type = 0;
  cmark_node *node;
  Check_Type(list_type, T_SYMBOL);

  Data_Get_Struct(self, cmark_node, node);

  if (list_type == sym_bullet_list) {
    type = CMARK_BULLET_LIST;
  } else if (list_type == sym_ordered_list) {
    type = CMARK_ORDERED_LIST;
  } else {
    rb_raise(rb_eNodeError, "invalid list_type");
  }

  if (!cmark_node_set_list_type(node, type)) {
    rb_raise(rb_eNodeError, "could not set list_type");
  }

  return Qnil;
}

/*
 * Public: Gets the starting number the current node (must be an
 * `:ordered_list`).
 *
 * Returns a {Number} representing the starting number.
 * Raises a NodeError if the starting number can't be retrieved.
 */
static VALUE rb_node_get_list_start(VALUE self) {
  cmark_node *node;
  Data_Get_Struct(self, cmark_node, node);

  if (cmark_node_get_type(node) != CMARK_NODE_LIST ||
      cmark_node_get_list_type(node) != CMARK_ORDERED_LIST) {
    rb_raise(rb_eNodeError, "can't get list_start for non-ordered list %d",
             cmark_node_get_list_type(node));
  }

  return INT2NUM(cmark_node_get_list_start(node));
}

/*
 * Public: Sets the starting number of the current node (must be an
 * `:ordered_list`).
 *
 * level - A {Number} representing the new starting number
 *
 * Raises a NodeError if the starting number can't be set.
 */
static VALUE rb_node_set_list_start(VALUE self, VALUE start) {
  int s;
  cmark_node *node;
  Check_Type(start, T_FIXNUM);

  Data_Get_Struct(self, cmark_node, node);
  s = FIX2INT(start);

  if (!cmark_node_set_list_start(node, s)) {
    rb_raise(rb_eNodeError, "could not set list_start");
  }

  return Qnil;
}

/*
 * Public: Gets the tight status the current node (must be a `:list`).
 *
 * Returns a `true` if the list is tight, `false` otherwise.
 * Raises a NodeError if the starting number can't be retrieved.
 */
static VALUE rb_node_get_list_tight(VALUE self) {
  int flag;
  cmark_node *node;
  Data_Get_Struct(self, cmark_node, node);

  if (cmark_node_get_type(node) != CMARK_NODE_LIST) {
    rb_raise(rb_eNodeError, "can't get list_tight for non-list");
  }

  flag = cmark_node_get_list_tight(node);

  return flag ? Qtrue : Qfalse;
}

/*
 * Public: Sets the tight status of the current node (must be a `:list`).
 *
 * tight - A {Boolean} representing the new tightness
 *
 * Raises a NodeError if the tightness can't be set.
 */
static VALUE rb_node_set_list_tight(VALUE self, VALUE tight) {
  int t;
  cmark_node *node;
  Data_Get_Struct(self, cmark_node, node);
  t = RTEST(tight);

  if (!cmark_node_set_list_tight(node, t)) {
    rb_raise(rb_eNodeError, "could not set list_tight");
  }

  return Qnil;
}

/*
 * Public: Gets the fence info of the current node (must be a `:code_block`).
 *
 * Returns a {String} representing the fence info.
 * Raises a NodeError if the fence info can't be retrieved.
 */
static VALUE rb_node_get_fence_info(VALUE self) {
  const char *fence_info;
  cmark_node *node;
  Data_Get_Struct(self, cmark_node, node);

  fence_info = cmark_node_get_fence_info(node);

  if (fence_info == NULL) {
    rb_raise(rb_eNodeError, "could not get fence_info");
  }

  return rb_str_new2(fence_info);
}

/*
 * Public: Sets the fence info of the current node (must be a `:code_block`).
 *
 * info - A {String} representing the new fence info
 *
 * Raises a NodeError if the fence info can't be set.
 */
static VALUE rb_node_set_fence_info(VALUE self, VALUE info) {
  char *text;
  cmark_node *node;
  Check_Type(info, T_STRING);

  Data_Get_Struct(self, cmark_node, node);
  text = StringValueCStr(info);

  if (!cmark_node_set_fence_info(node, text)) {
    rb_raise(rb_eNodeError, "could not set fence_info");
  }

  return Qnil;
}

static VALUE rb_node_get_tasklist_item_checked(VALUE self) {
  int tasklist_state;
  cmark_node *node;
  Data_Get_Struct(self, cmark_node, node);

  tasklist_state = cmark_gfm_extensions_get_tasklist_item_checked(node);

  if (tasklist_state == 1) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

/*
 * Public: Sets the checkbox state of the current node (must be a `:tasklist`).
 *
 * item_checked - A {Boolean} representing the new checkbox state
 *
 * Returns a {Boolean} representing the new checkbox state.
 * Raises a NodeError if the checkbox state can't be set.
 */
static VALUE rb_node_set_tasklist_item_checked(VALUE self, VALUE item_checked) {
  int tasklist_state;
  cmark_node *node;
  Data_Get_Struct(self, cmark_node, node);
  tasklist_state = RTEST(item_checked);

  if (!cmark_gfm_extensions_set_tasklist_item_checked(node, tasklist_state)) {
    rb_raise(rb_eNodeError, "could not set tasklist_item_checked");
  };

  if (tasklist_state) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

// TODO: remove this, superseded by the above method
static VALUE rb_node_get_tasklist_state(VALUE self) {
  int tasklist_state;
  cmark_node *node;
  Data_Get_Struct(self, cmark_node, node);

  tasklist_state = cmark_gfm_extensions_get_tasklist_item_checked(node);

  if (tasklist_state == 1) {
    return rb_str_new2("checked");
  } else {
    return rb_str_new2("unchecked");
  }
}

static VALUE rb_node_get_table_alignments(VALUE self) {
  uint16_t column_count, i;
  uint8_t *alignments;
  cmark_node *node;
  VALUE ary;
  Data_Get_Struct(self, cmark_node, node);

  column_count = cmark_gfm_extensions_get_table_columns(node);
  alignments = cmark_gfm_extensions_get_table_alignments(node);

  if (!column_count || !alignments) {
    rb_raise(rb_eNodeError, "could not get column_count or alignments");
  }

  ary = rb_ary_new();
  for (i = 0; i < column_count; ++i) {
    if (alignments[i] == 'l')
      rb_ary_push(ary, sym_left);
    else if (alignments[i] == 'c')
      rb_ary_push(ary, sym_center);
    else if (alignments[i] == 'r')
      rb_ary_push(ary, sym_right);
    else
      rb_ary_push(ary, Qnil);
  }
  return ary;
}

/* Internal: Escapes href URLs safely. */
static VALUE rb_html_escape_href(VALUE self, VALUE rb_text) {
  char *result;
  cmark_node *node;
  Check_Type(rb_text, T_STRING);

  Data_Get_Struct(self, cmark_node, node);

  cmark_mem *mem = cmark_node_mem(node);
  cmark_strbuf buf = CMARK_BUF_INIT(mem);

  if (houdini_escape_href(&buf, (const uint8_t *)RSTRING_PTR(rb_text),
                          RSTRING_LEN(rb_text))) {
    result = (char *)cmark_strbuf_detach(&buf);
    return encode_source_string(result, rb_text);

  }

  return rb_text;
}

/* Internal: Escapes HTML content safely. */
static VALUE rb_html_escape_html(VALUE self, VALUE rb_text) {
  char *result;
  cmark_node *node;
  Check_Type(rb_text, T_STRING);

  Data_Get_Struct(self, cmark_node, node);

  cmark_mem *mem = cmark_node_mem(node);
  cmark_strbuf buf = CMARK_BUF_INIT(mem);

  if (houdini_escape_html0(&buf, (const uint8_t *)RSTRING_PTR(rb_text),
                           RSTRING_LEN(rb_text), 0)) {
    result = (char *)cmark_strbuf_detach(&buf);
    return encode_source_string(result, rb_text);
  }

  return rb_text;
}

VALUE rb_extensions(VALUE self) {
  cmark_llist *exts, *it;
  cmark_syntax_extension *ext;
  VALUE ary = rb_ary_new();

  cmark_mem *mem = cmark_get_default_mem_allocator();
  exts = cmark_list_syntax_extensions(mem);
  for (it = exts; it; it = it->next) {
    ext = it->data;
    rb_ary_push(ary, rb_str_new2(ext->name));
  }
  cmark_llist_free(mem, exts);

  return ary;
}

__attribute__((visibility("default"))) void Init_commonmarker() {
  VALUE module;
  sym_document = ID2SYM(rb_intern("document"));
  sym_blockquote = ID2SYM(rb_intern("blockquote"));
  sym_list = ID2SYM(rb_intern("list"));
  sym_list_item = ID2SYM(rb_intern("list_item"));
  sym_code_block = ID2SYM(rb_intern("code_block"));
  sym_html = ID2SYM(rb_intern("html"));
  sym_paragraph = ID2SYM(rb_intern("paragraph"));
  sym_header = ID2SYM(rb_intern("header"));
  sym_hrule = ID2SYM(rb_intern("hrule"));
  sym_text = ID2SYM(rb_intern("text"));
  sym_softbreak = ID2SYM(rb_intern("softbreak"));
  sym_linebreak = ID2SYM(rb_intern("linebreak"));
  sym_code = ID2SYM(rb_intern("code"));
  sym_inline_html = ID2SYM(rb_intern("inline_html"));
  sym_emph = ID2SYM(rb_intern("emph"));
  sym_strong = ID2SYM(rb_intern("strong"));
  sym_link = ID2SYM(rb_intern("link"));
  sym_image = ID2SYM(rb_intern("image"));
  sym_footnote_reference = ID2SYM(rb_intern("footnote_reference"));
  sym_footnote_definition = ID2SYM(rb_intern("footnote_definition"));

  sym_bullet_list = ID2SYM(rb_intern("bullet_list"));
  sym_ordered_list = ID2SYM(rb_intern("ordered_list"));

  sym_left = ID2SYM(rb_intern("left"));
  sym_right = ID2SYM(rb_intern("right"));
  sym_center = ID2SYM(rb_intern("center"));

  module = rb_define_module("CommonMarker");
  rb_define_singleton_method(module, "extensions", rb_extensions, 0);
  rb_eNodeError = rb_define_class_under(module, "NodeError", rb_eStandardError);
  rb_cNode = rb_define_class_under(module, "Node", rb_cObject);
  rb_undef_alloc_func(rb_cNode);
  rb_define_singleton_method(rb_cNode, "markdown_to_html", rb_markdown_to_html,
                             3);
  rb_define_singleton_method(rb_cNode, "markdown_to_xml", rb_markdown_to_xml,
                             3);
  rb_define_singleton_method(rb_cNode, "new", rb_node_new, 1);
  rb_define_singleton_method(rb_cNode, "parse_document", rb_parse_document, 4);
  rb_define_method(rb_cNode, "string_content", rb_node_get_string_content, 0);
  rb_define_method(rb_cNode, "string_content=", rb_node_set_string_content, 1);
  rb_define_method(rb_cNode, "type", rb_node_get_type, 0);
  rb_define_method(rb_cNode, "type_string", rb_node_get_type_string, 0);
  rb_define_method(rb_cNode, "sourcepos", rb_node_get_sourcepos, 0);
  rb_define_method(rb_cNode, "delete", rb_node_unlink, 0);
  rb_define_method(rb_cNode, "first_child", rb_node_first_child, 0);
  rb_define_method(rb_cNode, "next", rb_node_next, 0);
  rb_define_method(rb_cNode, "insert_before", rb_node_insert_before, 1);
  rb_define_method(rb_cNode, "_render_html", rb_render_html, 2);
  rb_define_method(rb_cNode, "_render_xml", rb_render_xml, 1);
  rb_define_method(rb_cNode, "_render_commonmark", rb_render_commonmark, -1);
  rb_define_method(rb_cNode, "_render_plaintext", rb_render_plaintext, -1);
  rb_define_method(rb_cNode, "insert_after", rb_node_insert_after, 1);
  rb_define_method(rb_cNode, "prepend_child", rb_node_prepend_child, 1);
  rb_define_method(rb_cNode, "append_child", rb_node_append_child, 1);
  rb_define_method(rb_cNode, "last_child", rb_node_last_child, 0);
  rb_define_method(rb_cNode, "parent", rb_node_parent, 0);
  rb_define_method(rb_cNode, "previous", rb_node_previous, 0);
  rb_define_method(rb_cNode, "url", rb_node_get_url, 0);
  rb_define_method(rb_cNode, "url=", rb_node_set_url, 1);
  rb_define_method(rb_cNode, "title", rb_node_get_title, 0);
  rb_define_method(rb_cNode, "title=", rb_node_set_title, 1);
  rb_define_method(rb_cNode, "header_level", rb_node_get_header_level, 0);
  rb_define_method(rb_cNode, "header_level=", rb_node_set_header_level, 1);
  rb_define_method(rb_cNode, "list_type", rb_node_get_list_type, 0);
  rb_define_method(rb_cNode, "list_type=", rb_node_set_list_type, 1);
  rb_define_method(rb_cNode, "list_start", rb_node_get_list_start, 0);
  rb_define_method(rb_cNode, "list_start=", rb_node_set_list_start, 1);
  rb_define_method(rb_cNode, "list_tight", rb_node_get_list_tight, 0);
  rb_define_method(rb_cNode, "list_tight=", rb_node_set_list_tight, 1);
  rb_define_method(rb_cNode, "fence_info", rb_node_get_fence_info, 0);
  rb_define_method(rb_cNode, "fence_info=", rb_node_set_fence_info, 1);
  rb_define_method(rb_cNode, "table_alignments", rb_node_get_table_alignments, 0);
  rb_define_method(rb_cNode, "tasklist_state", rb_node_get_tasklist_state, 0);
  rb_define_method(rb_cNode, "tasklist_item_checked?", rb_node_get_tasklist_item_checked, 0);
  rb_define_method(rb_cNode, "tasklist_item_checked=", rb_node_set_tasklist_item_checked, 1);

  rb_define_method(rb_cNode, "html_escape_href", rb_html_escape_href, 1);
  rb_define_method(rb_cNode, "html_escape_html", rb_html_escape_html, 1);

  cmark_gfm_core_extensions_ensure_registered();
  cmark_init_standard_node_flags();
}
