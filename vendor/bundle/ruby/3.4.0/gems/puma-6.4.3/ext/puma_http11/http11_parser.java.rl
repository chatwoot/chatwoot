package org.jruby.puma;

import org.jruby.Ruby;
import org.jruby.RubyHash;
import org.jruby.util.ByteList;

public class Http11Parser {

/** Machine **/

%%{

  machine puma_parser;

  action mark {parser.mark = fpc; }

  action start_field { parser.field_start = fpc; }
  action snake_upcase_field { /* FIXME stub */ }
  action write_field { 
    parser.field_len = fpc-parser.field_start;
  }

  action start_value { parser.mark = fpc; }
  action write_value {
    Http11.http_field(runtime, parser.data, parser.buffer, parser.field_start, parser.field_len, parser.mark, fpc-parser.mark);
  }
  action request_method {
    Http11.request_method(runtime, parser.data, parser.buffer, parser.mark, fpc-parser.mark);
  }
  action request_uri {
    Http11.request_uri(runtime, parser.data, parser.buffer, parser.mark, fpc-parser.mark);
  }
  action fragment {
    Http11.fragment(runtime, parser.data, parser.buffer, parser.mark, fpc-parser.mark);
  }
  
  action start_query {parser.query_start = fpc; }
  action query_string {
    Http11.query_string(runtime, parser.data, parser.buffer, parser.query_start, fpc-parser.query_start);
  }

  action server_protocol {
    Http11.server_protocol(runtime, parser.data, parser.buffer, parser.mark, fpc-parser.mark);
  }

  action request_path {
    Http11.request_path(runtime, parser.data, parser.buffer, parser.mark, fpc-parser.mark);
  }

  action done { 
    parser.body_start = fpc + 1;
    http.header_done(runtime, parser.data, parser.buffer, fpc + 1, pe - fpc - 1);
    fbreak;
  }

  include puma_parser_common "http11_parser_common.rl";

}%%

/** Data **/
%% write data noentry;

   public static interface ElementCB {
     public void call(Ruby runtime, RubyHash data, ByteList buffer, int at, int length);
   }

   public static interface FieldCB {
     public void call(Ruby runtime, RubyHash data, ByteList buffer, int field, int flen, int value, int vlen);
   }

   public static class HttpParser {
      int cs;
      int body_start;
      int content_len;
      int nread;
      int mark;
      int field_start;
      int field_len;
      int query_start;

      RubyHash data;
      ByteList buffer;

      public void init() {
          cs = 0;

          %% write init;

          body_start = 0;
          content_len = 0;
          mark = 0;
          nread = 0;
          field_len = 0;
          field_start = 0;
      }
   }

   public final HttpParser parser = new HttpParser();

   public int execute(Ruby runtime, Http11 http, ByteList buffer, int off) {
     int p, pe;
     int cs = parser.cs;
     int len = buffer.length();
     assert off<=len : "offset past end of buffer";

     p = off;
     pe = len;
     // get a copy of the bytes, since it may not start at 0
     // FIXME: figure out how to just use the bytes in-place
     byte[] data = buffer.bytes();
     parser.buffer = buffer;

     %% write exec;

     parser.cs = cs;
     parser.nread += (p - off);
     
     assert p <= pe                  : "buffer overflow after parsing execute";
     assert parser.nread <= len      : "nread longer than length";
     assert parser.body_start <= len : "body starts after buffer end";
     assert parser.mark < len        : "mark is after buffer end";
     assert parser.field_len <= len  : "field has length longer than whole buffer";
     assert parser.field_start < len : "field starts after buffer end";

     return parser.nread;
   }

   public int finish() {
    if(has_error()) {
      return -1;
    } else if(is_finished()) {
      return 1;
    } else {
      return 0;
    }
  }

  public boolean has_error() {
    return parser.cs == puma_parser_error;
  }

  public boolean is_finished() {
    return parser.cs == puma_parser_first_final;
  }
}
