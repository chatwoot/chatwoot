# Encrypted HTTP Live Streaming
The [HLS spec](http://tools.ietf.org/html/draft-pantos-http-live-streaming-13#section-6.2.3) requires segments to be encrypted with AES-128 in CBC mode with PKCS7 padding. You can encrypt data to that specification with a combination of [OpenSSL](https://www.openssl.org/) and the [pkcs7 utility](https://github.com/brightcove/pkcs7). From the command-line:

```sh
# encrypt the text "hello" into a file
# since this is for testing, skip the key salting so the output is stable
# using -nosalt outside of testing is a terrible idea!
echo -n "hello" | pkcs7 | \
openssl enc -aes-128-cbc -nopad -nosalt -K $KEY -iv $IV > hello.encrypted

# xxd is a handy way of translating binary into a format easily consumed by
# javascript
xxd -i hello.encrypted
```

Later, you can decrypt it:

```sh
openssl enc -d -nopad -aes-128-cbc -K $KEY -iv $IV
```
