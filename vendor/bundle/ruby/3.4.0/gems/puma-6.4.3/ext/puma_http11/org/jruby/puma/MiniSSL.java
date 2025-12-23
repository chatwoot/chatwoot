package org.jruby.puma;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.runtime.Block;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;

import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLEngine;
import javax.net.ssl.SSLEngineResult;
import javax.net.ssl.SSLException;
import javax.net.ssl.SSLPeerUnverifiedException;
import javax.net.ssl.SSLSession;
import javax.net.ssl.X509TrustManager;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.IOException;
import java.nio.Buffer;
import java.nio.ByteBuffer;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;
import java.security.cert.Certificate;
import java.security.cert.CertificateEncodingException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;
import java.util.function.Supplier;

import static javax.net.ssl.SSLEngineResult.Status;
import static javax.net.ssl.SSLEngineResult.HandshakeStatus;

public class MiniSSL extends RubyObject { // MiniSSL::Engine
  private static final long serialVersionUID = -6903439483039141234L;
  private static ObjectAllocator ALLOCATOR = new ObjectAllocator() {
    public IRubyObject allocate(Ruby runtime, RubyClass klass) {
      return new MiniSSL(runtime, klass);
    }
  };

  public static void createMiniSSL(Ruby runtime) {
    RubyModule mPuma = runtime.defineModule("Puma");
    RubyModule ssl = mPuma.defineModuleUnder("MiniSSL");

    // Puma::MiniSSL::SSLError
    ssl.defineClassUnder("SSLError", runtime.getStandardError(), runtime.getStandardError().getAllocator());

    RubyClass eng = ssl.defineClassUnder("Engine", runtime.getObject(), ALLOCATOR);
    eng.defineAnnotatedMethods(MiniSSL.class);
  }

  /**
   * Fairly transparent wrapper around {@link java.nio.ByteBuffer} which adds the enhancements we need
   */
  private static class MiniSSLBuffer {
    ByteBuffer buffer;

    private MiniSSLBuffer(int capacity) { buffer = ByteBuffer.allocate(capacity); }
    private MiniSSLBuffer(byte[] initialContents) { buffer = ByteBuffer.wrap(initialContents); }

    public void clear() { buffer.clear(); }
    public void compact() { buffer.compact(); }
    public void flip() { ((Buffer) buffer).flip(); }
    public boolean hasRemaining() { return buffer.hasRemaining(); }
    public int position() { return buffer.position(); }

    public ByteBuffer getRawBuffer() {
      return buffer;
    }

    /**
     * Writes bytes to the buffer after ensuring there's room
     */
    private void put(byte[] bytes, final int offset, final int length) {
      if (buffer.remaining() < length) {
        resize(buffer.limit() + length);
      }
      buffer.put(bytes, offset, length);
    }

    /**
     * Ensures that newCapacity bytes can be written to this buffer, only re-allocating if necessary
     */
    public void resize(int newCapacity) {
      if (newCapacity > buffer.capacity()) {
        ByteBuffer dstTmp = ByteBuffer.allocate(newCapacity);
        flip();
        dstTmp.put(buffer);
        buffer = dstTmp;
      } else {
        buffer.limit(newCapacity);
      }
    }

    /**
     * Drains the buffer to a ByteList, or returns null for an empty buffer
     */
    public ByteList asByteList() {
      flip();
      if (!buffer.hasRemaining()) {
        buffer.clear();
        return null;
      }

      byte[] bss = new byte[buffer.limit()];

      buffer.get(bss);
      buffer.clear();
      return new ByteList(bss, false);
    }

    @Override
    public String toString() { return buffer.toString(); }
  }

  private SSLEngine engine;
  private boolean closed;
  private boolean handshake;
  private MiniSSLBuffer inboundNetData;
  private MiniSSLBuffer outboundAppData;
  private MiniSSLBuffer outboundNetData;

  public MiniSSL(Ruby runtime, RubyClass klass) {
    super(runtime, klass);
  }

  private static Map<String, KeyManagerFactory> keyManagerFactoryMap = new ConcurrentHashMap<String, KeyManagerFactory>();
  private static Map<String, TrustManagerFactory> trustManagerFactoryMap = new ConcurrentHashMap<String, TrustManagerFactory>();

  @JRubyMethod(meta = true) // Engine.server
  public static synchronized IRubyObject server(ThreadContext context, IRubyObject recv, IRubyObject miniSSLContext)
      throws KeyStoreException, IOException, CertificateException, NoSuchAlgorithmException, UnrecoverableKeyException {
    // Create the KeyManagerFactory and TrustManagerFactory for this server
    String keystoreFile = asStringValue(miniSSLContext.callMethod(context, "keystore"), null);
    char[] keystorePass = asStringValue(miniSSLContext.callMethod(context, "keystore_pass"), null).toCharArray();
    String keystoreType = asStringValue(miniSSLContext.callMethod(context, "keystore_type"), KeyStore::getDefaultType);

    String truststoreFile;
    char[] truststorePass;
    String truststoreType;
    IRubyObject truststore = miniSSLContext.callMethod(context, "truststore");
    if (truststore.isNil()) {
      truststoreFile = keystoreFile;
      truststorePass = keystorePass;
      truststoreType = keystoreType;
    } else if (!isDefaultSymbol(context, truststore)) {
      truststoreFile = truststore.convertToString().asJavaString();
      IRubyObject pass = miniSSLContext.callMethod(context, "truststore_pass");
      if (pass.isNil()) {
        truststorePass = null;
      } else {
        truststorePass = asStringValue(pass, null).toCharArray();
      }
      truststoreType = asStringValue(miniSSLContext.callMethod(context, "truststore_type"), KeyStore::getDefaultType);
    } else { // self.truststore = :default
      truststoreFile = null;
      truststorePass = null;
      truststoreType = null;
    }

    KeyStore ks = KeyStore.getInstance(keystoreType);
    InputStream is = new FileInputStream(keystoreFile);
    try {
      ks.load(is, keystorePass);
    } finally {
      is.close();
    }
    KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
    kmf.init(ks, keystorePass);
    keyManagerFactoryMap.put(keystoreFile, kmf);

    if (truststoreFile != null) {
      KeyStore ts = KeyStore.getInstance(truststoreType);
      is = new FileInputStream(truststoreFile);
      try {
        ts.load(is, truststorePass);
      } finally {
        is.close();
      }
      TrustManagerFactory tmf = TrustManagerFactory.getInstance("SunX509");
      tmf.init(ts);
      trustManagerFactoryMap.put(truststoreFile, tmf);
    }

    RubyClass klass = (RubyClass) recv;
    return klass.newInstance(context, miniSSLContext, Block.NULL_BLOCK);
  }

  private static String asStringValue(IRubyObject value, Supplier<String> defaultValue) {
    if (defaultValue != null && value.isNil()) return defaultValue.get();
    return value.convertToString().asJavaString();
  }

  private static boolean isDefaultSymbol(ThreadContext context, IRubyObject truststore) {
    return context.runtime.newSymbol("default").equals(truststore);
  }

  @JRubyMethod
  public IRubyObject initialize(ThreadContext context, IRubyObject miniSSLContext)
      throws KeyStoreException, NoSuchAlgorithmException, KeyManagementException {

    String keystoreFile = miniSSLContext.callMethod(context, "keystore").convertToString().asJavaString();
    KeyManagerFactory kmf = keyManagerFactoryMap.get(keystoreFile);
    IRubyObject truststore = miniSSLContext.callMethod(context, "truststore");
    String truststoreFile = isDefaultSymbol(context, truststore) ? "" : asStringValue(truststore, () -> keystoreFile);
    TrustManagerFactory tmf = trustManagerFactoryMap.get(truststoreFile); // null if self.truststore = :default
    if (kmf == null) {
      throw new KeyStoreException("Could not find KeyManagerFactory for keystore: " + keystoreFile + " truststore: " + truststoreFile);
    }

    SSLContext sslCtx = SSLContext.getInstance("TLS");

    sslCtx.init(kmf.getKeyManagers(), getTrustManagers(tmf), null);
    closed = false;
    handshake = false;
    engine = sslCtx.createSSLEngine();

    String[] enabledProtocols;
    IRubyObject protocols = miniSSLContext.callMethod(context, "protocols");
    if (protocols.isNil()) {
      if (miniSSLContext.callMethod(context, "no_tlsv1").isTrue()) {
        enabledProtocols = new String[] { "TLSv1.1", "TLSv1.2", "TLSv1.3" };
      } else {
        enabledProtocols = new String[] { "TLSv1", "TLSv1.1", "TLSv1.2", "TLSv1.3" };
      }

      if (miniSSLContext.callMethod(context, "no_tlsv1_1").isTrue()) {
        enabledProtocols = new String[] { "TLSv1.2", "TLSv1.3" };
      }
    } else if (protocols instanceof RubyArray) {
      enabledProtocols = (String[]) ((RubyArray) protocols).toArray(new String[0]);
    } else {
      throw context.runtime.newTypeError(protocols, context.runtime.getArray());
    }
    engine.setEnabledProtocols(enabledProtocols);

    engine.setUseClientMode(false);

    long verify_mode = miniSSLContext.callMethod(context, "verify_mode").convertToInteger("to_i").getLongValue();
    if ((verify_mode & 0x1) != 0) { // 'peer'
        engine.setWantClientAuth(true);
    }
    if ((verify_mode & 0x2) != 0) { // 'force_peer'
        engine.setNeedClientAuth(true);
    }

    IRubyObject cipher_suites = miniSSLContext.callMethod(context, "cipher_suites");
    if (cipher_suites instanceof RubyArray) {
      engine.setEnabledCipherSuites((String[]) ((RubyArray) cipher_suites).toArray(new String[0]));
    } else if (!cipher_suites.isNil()) {
      throw context.runtime.newTypeError(cipher_suites, context.runtime.getArray());
    }

    SSLSession session = engine.getSession();
    inboundNetData = new MiniSSLBuffer(session.getPacketBufferSize());
    outboundAppData = new MiniSSLBuffer(session.getApplicationBufferSize());
    outboundAppData.flip();
    outboundNetData = new MiniSSLBuffer(session.getPacketBufferSize());

    return this;
  }

  private TrustManager[] getTrustManagers(TrustManagerFactory factory) {
    if (factory == null) return null; // use JDK trust defaults
    final TrustManager[] tms = factory.getTrustManagers();
    if (tms != null) {
      for (int i=0; i<tms.length; i++) {
        final TrustManager tm = tms[i];
        if (tm instanceof X509TrustManager) {
          tms[i] = new TrustManagerWrapper((X509TrustManager) tm);
        }
      }
    }
    return tms;
  }

  private volatile transient X509Certificate lastCheckedCert0;

  private class TrustManagerWrapper implements X509TrustManager {

    private final X509TrustManager delegate;

    TrustManagerWrapper(X509TrustManager delegate) {
      this.delegate = delegate;
    }

    @Override
    public void checkClientTrusted(X509Certificate[] chain, String authType) throws CertificateException {
      lastCheckedCert0 = chain.length > 0 ? chain[0] : null;
      delegate.checkClientTrusted(chain, authType);
    }

    @Override
    public void checkServerTrusted(X509Certificate[] chain, String authType) throws CertificateException {
      delegate.checkServerTrusted(chain, authType);
    }

    @Override
    public X509Certificate[] getAcceptedIssuers() {
      return delegate.getAcceptedIssuers();
    }

  }

  @JRubyMethod
  public IRubyObject inject(IRubyObject arg) {
    ByteList bytes = arg.convertToString().getByteList();
    inboundNetData.put(bytes.unsafeBytes(), bytes.getBegin(), bytes.getRealSize());
    return this;
  }

  private enum SSLOperation {
    WRAP,
    UNWRAP
  }

  private SSLEngineResult doOp(SSLOperation sslOp, MiniSSLBuffer src, MiniSSLBuffer dst) throws SSLException {
    SSLEngineResult res = null;
    boolean retryOp = true;
    while (retryOp) {
      switch (sslOp) {
        case WRAP:
          res = engine.wrap(src.getRawBuffer(), dst.getRawBuffer());
          break;
        case UNWRAP:
          res = engine.unwrap(src.getRawBuffer(), dst.getRawBuffer());
          break;
        default:
          throw new AssertionError("Unknown SSLOperation: " + sslOp);
      }

      switch (res.getStatus()) {
        case BUFFER_OVERFLOW:
          // increase the buffer size to accommodate the overflowing data
          int newSize = Math.max(engine.getSession().getPacketBufferSize(), engine.getSession().getApplicationBufferSize());
          dst.resize(newSize + dst.position());
          // retry the operation
          retryOp = true;
          break;
        case BUFFER_UNDERFLOW:
          // need to wait for more data to come in before we retry
          retryOp = false;
          break;
        case CLOSED:
          closed = true;
          retryOp = false;
          break;
        default:
          // other case is OK.  We're done here.
          retryOp = false;
      }
      if (res.getHandshakeStatus() == HandshakeStatus.FINISHED) {
        handshake = true;
      }
    }

    return res;
  }

  @JRubyMethod
  public IRubyObject read() {
    try {
      inboundNetData.flip();

      if(!inboundNetData.hasRemaining()) {
        return getRuntime().getNil();
      }

      MiniSSLBuffer inboundAppData = new MiniSSLBuffer(engine.getSession().getApplicationBufferSize());
      doOp(SSLOperation.UNWRAP, inboundNetData, inboundAppData);

      HandshakeStatus handshakeStatus = engine.getHandshakeStatus();
      boolean done = false;
      while (!done) {
        SSLEngineResult res;
        switch (handshakeStatus) {
          case NEED_WRAP:
            res = doOp(SSLOperation.WRAP, inboundAppData, outboundNetData);
            handshakeStatus = res.getHandshakeStatus();
            break;
          case NEED_UNWRAP:
            res = doOp(SSLOperation.UNWRAP, inboundNetData, inboundAppData);
            if (res.getStatus() == Status.BUFFER_UNDERFLOW) {
              // need more data before we can shake more hands
              done = true;
            }
            handshakeStatus = res.getHandshakeStatus();
            break;
          case NEED_TASK:
            Runnable runnable;
            while ((runnable = engine.getDelegatedTask()) != null) {
              runnable.run();
            }
            handshakeStatus = engine.getHandshakeStatus();
            break;
          default:
            done = true;
        }
      }

      if (inboundNetData.hasRemaining()) {
        inboundNetData.compact();
      } else {
        inboundNetData.clear();
      }

      ByteList appDataByteList = inboundAppData.asByteList();
      if (appDataByteList == null) {
        return getRuntime().getNil();
      }

      return RubyString.newString(getRuntime(), appDataByteList);
    } catch (SSLException e) {
      throw newSSLError(getRuntime(), e);
    }
  }

  @JRubyMethod
  public IRubyObject write(IRubyObject arg) {
    byte[] bls = arg.convertToString().getBytes();
    outboundAppData = new MiniSSLBuffer(bls);

    return getRuntime().newFixnum(bls.length);
  }

  @JRubyMethod
  public IRubyObject extract(ThreadContext context) {
    try {
      ByteList dataByteList = outboundNetData.asByteList();
      if (dataByteList != null) {
        return RubyString.newString(context.runtime, dataByteList);
      }

      if (!outboundAppData.hasRemaining()) {
        return context.nil;
      }

      outboundNetData.clear();
      doOp(SSLOperation.WRAP, outboundAppData, outboundNetData);
      dataByteList = outboundNetData.asByteList();
      if (dataByteList == null) {
        return context.nil;
      }

      return RubyString.newString(context.runtime, dataByteList);
    } catch (SSLException e) {
      throw newSSLError(getRuntime(), e);
    }
  }

  @JRubyMethod
  public IRubyObject peercert(ThreadContext context) throws CertificateEncodingException {
    Certificate peerCert;
    try {
      peerCert = engine.getSession().getPeerCertificates()[0];
    } catch (SSLPeerUnverifiedException e) {
      peerCert = lastCheckedCert0; // null if trust check did not happen
    }
    return peerCert == null ? context.nil : JavaEmbedUtils.javaToRuby(context.runtime, peerCert.getEncoded());
  }

  @JRubyMethod(name = "init?")
  public IRubyObject isInit(ThreadContext context) {
    return handshake ? getRuntime().getFalse() : getRuntime().getTrue();
  }

  @JRubyMethod
  public IRubyObject shutdown() {
    if (closed || engine.isInboundDone() && engine.isOutboundDone()) {
      if (engine.isOutboundDone()) {
        engine.closeOutbound();
      }
      return getRuntime().getTrue();
    } else {
      return getRuntime().getFalse();
    }
  }

  private static RubyClass getSSLError(Ruby runtime) {
    return (RubyClass) ((RubyModule) runtime.getModule("Puma").getConstantAt("MiniSSL")).getConstantAt("SSLError");
  }

  private static RaiseException newSSLError(Ruby runtime, SSLException cause) {
    return newError(runtime, getSSLError(runtime), cause.toString(), cause);
  }

  private static RaiseException newError(Ruby runtime, RubyClass errorClass, String message, Throwable cause) {
    RaiseException ex = RaiseException.from(runtime, errorClass, message);
    ex.initCause(cause);
    return ex;
  }

}
