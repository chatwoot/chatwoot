package org.jruby.puma;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyModule;
import org.jruby.RubyNumeric;
import org.jruby.RubyObject;
import org.jruby.RubyString;

import org.jruby.anno.JRubyMethod;

import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

import org.jruby.exceptions.RaiseException;

import org.jruby.util.ByteList;

/**
 * @author <a href="mailto:ola.bini@ki.se">Ola Bini</a>
 * @author <a href="mailto:headius@headius.com">Charles Oliver Nutter</a>
 */
public class Http11 extends RubyObject {
    public final static int MAX_FIELD_NAME_LENGTH = 256;
    public final static String MAX_FIELD_NAME_LENGTH_ERR = "HTTP element FIELD_NAME is longer than the 256 allowed length.";
    public final static int MAX_FIELD_VALUE_LENGTH = 80 * 1024;
    public final static String MAX_FIELD_VALUE_LENGTH_ERR = "HTTP element FIELD_VALUE is longer than the 81920 allowed length.";
    public final static int MAX_REQUEST_URI_LENGTH = 1024 * 12;
    public final static String MAX_REQUEST_URI_LENGTH_ERR = "HTTP element REQUEST_URI is longer than the 12288 allowed length.";
    public final static int MAX_FRAGMENT_LENGTH = 1024;
    public final static String MAX_FRAGMENT_LENGTH_ERR = "HTTP element REQUEST_PATH is longer than the 1024 allowed length.";
    public final static int MAX_REQUEST_PATH_LENGTH = 8192;
    public final static String MAX_REQUEST_PATH_LENGTH_ERR = "HTTP element REQUEST_PATH is longer than the 8192 allowed length.";
    public final static int MAX_QUERY_STRING_LENGTH = 1024 * 10;
    public final static String MAX_QUERY_STRING_LENGTH_ERR = "HTTP element QUERY_STRING is longer than the 10240 allowed length.";
    public final static int MAX_HEADER_LENGTH = 1024 * (80 + 32);
    public final static String MAX_HEADER_LENGTH_ERR = "HTTP element HEADER is longer than the 114688 allowed length.";

    public static final ByteList CONTENT_TYPE_BYTELIST = new ByteList(ByteList.plain("CONTENT_TYPE"));
    public static final ByteList CONTENT_LENGTH_BYTELIST = new ByteList(ByteList.plain("CONTENT_LENGTH"));
    public static final ByteList HTTP_PREFIX_BYTELIST = new ByteList(ByteList.plain("HTTP_"));
    public static final ByteList COMMA_SPACE_BYTELIST = new ByteList(ByteList.plain(", "));
    public static final ByteList REQUEST_METHOD_BYTELIST = new ByteList(ByteList.plain("REQUEST_METHOD"));
    public static final ByteList REQUEST_URI_BYTELIST = new ByteList(ByteList.plain("REQUEST_URI"));
    public static final ByteList FRAGMENT_BYTELIST = new ByteList(ByteList.plain("FRAGMENT"));
    public static final ByteList REQUEST_PATH_BYTELIST = new ByteList(ByteList.plain("REQUEST_PATH"));
    public static final ByteList QUERY_STRING_BYTELIST = new ByteList(ByteList.plain("QUERY_STRING"));
    public static final ByteList SERVER_PROTOCOL_BYTELIST = new ByteList(ByteList.plain("SERVER_PROTOCOL"));

    private static ObjectAllocator ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            return new Http11(runtime, klass);
        }
    };

    public static void createHttp11(Ruby runtime) {
        RubyModule mPuma = runtime.defineModule("Puma");
        mPuma.defineClassUnder("HttpParserError",runtime.getClass("IOError"),runtime.getClass("IOError").getAllocator());

        RubyClass cHttpParser = mPuma.defineClassUnder("HttpParser",runtime.getObject(),ALLOCATOR);
        cHttpParser.defineAnnotatedMethods(Http11.class);
    }

    private Ruby runtime;
    private Http11Parser hp;
    private RubyString body;

    public Http11(Ruby runtime, RubyClass clazz) {
        super(runtime,clazz);
        this.runtime = runtime;
        this.hp = new Http11Parser();
        this.hp.parser.init();
    }

    public static void validateMaxLength(Ruby runtime, int len, int max, String msg) {
        if(len>max) {
            throw newHTTPParserError(runtime, msg);
        }
    }

    private static RaiseException newHTTPParserError(Ruby runtime, String msg) {
        return runtime.newRaiseException(getHTTPParserError(runtime), msg);
    }

    private static RubyClass getHTTPParserError(Ruby runtime) {
        // Cheaper to look this up lazily than cache eagerly and consume a field, since it's rarely encountered
        return (RubyClass)runtime.getModule("Puma").getConstant("HttpParserError");
    }

    public static void http_field(Ruby runtime, RubyHash req, ByteList buffer, int field, int flen, int value, int vlen) {
        RubyString f;
        IRubyObject v;
        validateMaxLength(runtime, flen, MAX_FIELD_NAME_LENGTH, MAX_FIELD_NAME_LENGTH_ERR);
        validateMaxLength(runtime, vlen, MAX_FIELD_VALUE_LENGTH, MAX_FIELD_VALUE_LENGTH_ERR);

        ByteList b = new ByteList(buffer,field,flen);
        for(int i = 0,j = b.length();i<j;i++) {
            int bite = b.get(i) & 0xFF;
            if(bite == '-') {
                b.set(i, (byte)'_');
            } else if(bite == '_') {
                b.set(i, (byte)',');
            } else {
                b.set(i, (byte)Character.toUpperCase(bite));
            }
        }

        while (vlen > 0 && Character.isWhitespace(buffer.get(value + vlen - 1))) vlen--;

        if (b.equals(CONTENT_LENGTH_BYTELIST) || b.equals(CONTENT_TYPE_BYTELIST)) {
          f = RubyString.newString(runtime, b);
        } else {
          f = RubyString.newStringShared(runtime, HTTP_PREFIX_BYTELIST);
          f.cat(b);
        }

        b = new ByteList(buffer, value, vlen);
        v = req.fastARef(f);
        if (v == null || v.isNil()) {
            req.fastASet(f, RubyString.newString(runtime, b));
        } else {
            RubyString vs = v.convertToString();
            vs.cat(COMMA_SPACE_BYTELIST);
            vs.cat(b);
        }
    }

    public static void request_method(Ruby runtime, RubyHash req, ByteList buffer, int at, int length) {
        RubyString val = RubyString.newString(runtime,new ByteList(buffer,at,length));
        req.fastASet(RubyString.newStringShared(runtime, REQUEST_METHOD_BYTELIST),val);
    }

    public static void request_uri(Ruby runtime, RubyHash req, ByteList buffer, int at, int length) {
        validateMaxLength(runtime, length, MAX_REQUEST_URI_LENGTH, MAX_REQUEST_URI_LENGTH_ERR);
        RubyString val = RubyString.newString(runtime,new ByteList(buffer,at,length));
        req.fastASet(RubyString.newStringShared(runtime, REQUEST_URI_BYTELIST),val);
    }

    public static void fragment(Ruby runtime, RubyHash req, ByteList buffer, int at, int length) {
        validateMaxLength(runtime, length, MAX_FRAGMENT_LENGTH, MAX_FRAGMENT_LENGTH_ERR);
        RubyString val = RubyString.newString(runtime,new ByteList(buffer,at,length));
        req.fastASet(RubyString.newStringShared(runtime, FRAGMENT_BYTELIST),val);
    }

    public static void request_path(Ruby runtime, RubyHash req, ByteList buffer, int at, int length) {
        validateMaxLength(runtime, length, MAX_REQUEST_PATH_LENGTH, MAX_REQUEST_PATH_LENGTH_ERR);
        RubyString val = RubyString.newString(runtime,new ByteList(buffer,at,length));
        req.fastASet(RubyString.newStringShared(runtime, REQUEST_PATH_BYTELIST),val);
    }

    public static void query_string(Ruby runtime, RubyHash req, ByteList buffer, int at, int length) {
        validateMaxLength(runtime, length, MAX_QUERY_STRING_LENGTH, MAX_QUERY_STRING_LENGTH_ERR);
        RubyString val = RubyString.newString(runtime,new ByteList(buffer,at,length));
        req.fastASet(RubyString.newStringShared(runtime, QUERY_STRING_BYTELIST),val);
    }

    public static void server_protocol(Ruby runtime, RubyHash req, ByteList buffer, int at, int length) {
        RubyString val = RubyString.newString(runtime,new ByteList(buffer,at,length));
        req.fastASet(RubyString.newStringShared(runtime, SERVER_PROTOCOL_BYTELIST),val);
    }

    public void header_done(Ruby runtime, RubyHash req, ByteList buffer, int at, int length) {
        body = RubyString.newStringShared(runtime, new ByteList(buffer, at, length));
    }

    @JRubyMethod
    public IRubyObject initialize() {
        this.hp.parser.init();
        return this;
    }

    @JRubyMethod
    public IRubyObject reset() {
        this.hp.parser.init();
        return runtime.getNil();
    }

    @JRubyMethod
    public IRubyObject finish() {
        this.hp.finish();
        return this.hp.is_finished() ? runtime.getTrue() : runtime.getFalse();
    }

    @JRubyMethod
    public IRubyObject execute(IRubyObject req_hash, IRubyObject data, IRubyObject start) {
        int from = RubyNumeric.fix2int(start);
        ByteList d = ((RubyString)data).getByteList();
        if(from >= d.length()) {
            throw newHTTPParserError(runtime, "Requested start is after data buffer end.");
        } else {
            Http11Parser hp = this.hp;
            Http11Parser.HttpParser parser = hp.parser;

            parser.data = (RubyHash) req_hash;

            hp.execute(runtime, this, d,from);

            validateMaxLength(runtime, parser.nread,MAX_HEADER_LENGTH, MAX_HEADER_LENGTH_ERR);

            if(hp.has_error()) {
                throw newHTTPParserError(runtime, "Invalid HTTP format, parsing fails. Are you trying to open an SSL connection to a non-SSL Puma?");
            } else {
                return runtime.newFixnum(parser.nread);
            }
        }
    }

    @JRubyMethod(name = "error?")
    public IRubyObject has_error() {
        return this.hp.has_error() ? runtime.getTrue() : runtime.getFalse();
    }

    @JRubyMethod(name = "finished?")
    public IRubyObject is_finished() {
        return this.hp.is_finished() ? runtime.getTrue() : runtime.getFalse();
    }

    @JRubyMethod
    public IRubyObject nread() {
        return runtime.newFixnum(this.hp.parser.nread);
    }

    @JRubyMethod
    public IRubyObject body() {
        return body;
    }
}// Http11
