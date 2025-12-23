/*
  This software is licensed under the MPL-2.0 License.

  Copyright Bryan Powell, 2020.
*/

#include <stdlib.h>
#include <string.h>
#include "llhttp.h"

typedef struct rb_llhttp_callbacks_s rb_llhttp_callbacks_t;

typedef int (*rb_llhttp_data_cb)(const char *data, size_t length);
typedef int (*rb_llhttp_cb)();

struct rb_llhttp_callbacks_s {
  rb_llhttp_cb on_message_begin;
  rb_llhttp_data_cb on_url;
  rb_llhttp_data_cb on_status;
  rb_llhttp_data_cb on_header_field;
  rb_llhttp_data_cb on_header_value;
  rb_llhttp_cb on_headers_complete;
  rb_llhttp_data_cb on_body;
  rb_llhttp_cb on_message_complete;
  rb_llhttp_cb on_chunk_header;
  rb_llhttp_cb on_chunk_complete;
  rb_llhttp_cb on_url_complete;
  rb_llhttp_cb on_status_complete;
  rb_llhttp_cb on_header_field_complete;
  rb_llhttp_cb on_header_value_complete;
};

int rb_llhttp_on_message_begin(llhttp_t *parser) {
  rb_llhttp_callbacks_t* callbacks = parser->data;
  return callbacks->on_message_begin();
}

int rb_llhttp_on_url(llhttp_t *parser, char *data, size_t length) {
  rb_llhttp_callbacks_t* callbacks = parser->data;
  callbacks->on_url(data, length);
  return 0;
}

int rb_llhttp_on_status(llhttp_t *parser, char *data, size_t length) {
  rb_llhttp_callbacks_t* callbacks = parser->data;
  callbacks->on_status(data, length);
  return 0;
}

int rb_llhttp_on_header_field(llhttp_t *parser, char *data, size_t length) {
  rb_llhttp_callbacks_t* callbacks = parser->data;
  callbacks->on_header_field(data, length);
  return 0;
}

int rb_llhttp_on_header_value(llhttp_t *parser, char *data, size_t length) {
  rb_llhttp_callbacks_t* callbacks = parser->data;
  callbacks->on_header_value(data, length);
  return 0;
}

int rb_llhttp_on_headers_complete(llhttp_t *parser) {
  rb_llhttp_callbacks_t* callbacks = parser->data;
  return callbacks->on_headers_complete();
}

int rb_llhttp_on_body(llhttp_t *parser, char *data, size_t length) {
  rb_llhttp_callbacks_t* callbacks = parser->data;
  callbacks->on_body(data, length);
  return 0;
}

int rb_llhttp_on_message_complete(llhttp_t *parser) {
  rb_llhttp_callbacks_t* callbacks = parser->data;
  return callbacks->on_message_complete();
}

int rb_llhttp_on_chunk_header(llhttp_t *parser) {
  rb_llhttp_callbacks_t* callbacks = parser->data;
  return callbacks->on_chunk_header();
}

int rb_llhttp_on_chunk_complete(llhttp_t *parser) {
  rb_llhttp_callbacks_t* callbacks = parser->data;
  callbacks->on_chunk_complete();
  return 0;
}

int rb_llhttp_on_url_complete(llhttp_t *parser) {
  rb_llhttp_callbacks_t* callbacks = parser->data;
  callbacks->on_url_complete();
  return 0;
}

int rb_llhttp_on_status_complete(llhttp_t *parser) {
  rb_llhttp_callbacks_t* callbacks = parser->data;
  callbacks->on_status_complete();
  return 0;
}

int rb_llhttp_on_header_field_complete(llhttp_t *parser) {
  rb_llhttp_callbacks_t* callbacks = parser->data;
  callbacks->on_header_field_complete();
  return 0;
}

int rb_llhttp_on_header_value_complete(llhttp_t *parser) {
  rb_llhttp_callbacks_t* callbacks = parser->data;
  callbacks->on_header_value_complete();
  return 0;
}

llhttp_t* rb_llhttp_init(int type, rb_llhttp_callbacks_t* callbacks) {
  llhttp_t *parser = (llhttp_t *)malloc(sizeof(llhttp_t));
  llhttp_settings_t *settings = (llhttp_settings_t *)malloc(sizeof(llhttp_settings_t));

  llhttp_settings_init(settings);

  if (callbacks->on_message_begin) {
    settings->on_message_begin = (llhttp_cb)rb_llhttp_on_message_begin;
  }

  if (callbacks->on_url) {
    settings->on_url = (llhttp_data_cb)rb_llhttp_on_url;
  }

  if (callbacks->on_status) {
    settings->on_status = (llhttp_data_cb)rb_llhttp_on_status;
  }

  if (callbacks->on_header_field) {
    settings->on_header_field = (llhttp_data_cb)rb_llhttp_on_header_field;
  }

  if (callbacks->on_header_value) {
    settings->on_header_value = (llhttp_data_cb)rb_llhttp_on_header_value;
  }

  if (callbacks->on_headers_complete) {
    settings->on_headers_complete = (llhttp_cb)rb_llhttp_on_headers_complete;
  }

  if (callbacks->on_body) {
    settings->on_body = (llhttp_data_cb)rb_llhttp_on_body;
  }

  if (callbacks->on_message_complete) {
    settings->on_message_complete = (llhttp_cb)rb_llhttp_on_message_complete;
  }

  if (callbacks->on_chunk_header) {
    settings->on_chunk_header = (llhttp_cb)rb_llhttp_on_chunk_header;
  }

  if (callbacks->on_chunk_complete) {
    settings->on_chunk_complete = (llhttp_cb)rb_llhttp_on_chunk_complete;
  }

  if (callbacks->on_url_complete) {
    settings->on_url_complete = (llhttp_cb)rb_llhttp_on_url_complete;
  }

  if (callbacks->on_status_complete) {
    settings->on_status_complete = (llhttp_cb)rb_llhttp_on_status_complete;
  }

  if (callbacks->on_header_field_complete) {
    settings->on_header_field_complete = (llhttp_cb)rb_llhttp_on_header_field_complete;
  }

  if (callbacks->on_header_value_complete) {
    settings->on_header_value_complete = (llhttp_cb)rb_llhttp_on_header_value_complete;
  }

  llhttp_init(parser, type, settings);

  parser->data = callbacks;

  return parser;
}

void rb_llhttp_free(llhttp_t* parser) {
  if (parser) {
    free(parser->settings);
    free(parser);
  }
}

uint64_t rb_llhttp_content_length(llhttp_t* parser) {
  return parser->content_length;
}

const char* rb_llhttp_method_name(llhttp_t* parser) {
  return llhttp_method_name(parser->method);
}

uint16_t rb_llhttp_status_code(llhttp_t* parser) {
  return parser->status_code;
}

uint16_t rb_llhttp_http_major(llhttp_t* parser) {
  return parser->http_major;
}

uint16_t rb_llhttp_http_minor(llhttp_t* parser) {
  return parser->http_minor;
}

const char* rb_llhttp_errno_name(llhttp_errno_t errno) {
  return llhttp_errno_name(errno);
}

const char* rb_llhttp_error_reason(llhttp_t* parser) {
  return parser->reason;
}
