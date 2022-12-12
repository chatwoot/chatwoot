var assert = require('assert')
var detect = require('rewire')('../lib/detect-linux');

var execResponse = {
    code: 0,
    stdout: "",
    stderr: ""
};

var execStub = function(cmd, cb) {
    cb(execResponse.code, execResponse.stdout, execResponse.stderr);
};

detect.__set__('exec', execStub);

describe("Ubuntu 14.04 tests", function () {
    beforeEach(function() {
        execResponse.code = 0;
        execResponse.stdout = "";
        execResponse.stderr = "";
    });

    it('detects chrome', function (done) {
        execResponse.stdout = 'google-chrome.desktop';

        detect(function(err, res){
            assert.equal(res.isChrome, true);
            assert.equal(res.isChromium, false);
            assert.equal(res.isWebkit, true);
            assert.equal(res.commonName, 'chrome');
            assert.equal(res.identity, execResponse.stdout);
            done(err);
        });
    });

    it('detects chromium', function (done) {
        execResponse.stdout = 'chromium-browser.desktop';

        detect(function(err, res){
            assert.equal(res.isChrome, false);
            assert.equal(res.isChromium, true);
            assert.equal(res.isWebkit, true);
            assert.equal(res.commonName, 'chromium');
            assert.equal(res.identity, execResponse.stdout);
            done(err);
        });
    });

    it('detects opera', function (done) {
        execResponse.stdout = 'opera.desktop';

        detect(function(err, res){
            assert.equal(res.isChrome, false);
            assert.equal(res.isChromium, false);
            assert.equal(res.isOpera, true);
            assert.equal(res.isWebkit, true);
            assert.equal(res.commonName, 'opera');
            assert.equal(res.identity, execResponse.stdout);
            done(err);
        });
    });

    it('detects firefox', function (done) {
        execResponse.stdout = 'firefox.desktop';

        detect(function(err, res){
            assert.equal(res.isFirefox, true);
            assert.equal(res.isWebkit, false);
            assert.equal(res.commonName, 'firefox');
            assert.equal(res.identity, execResponse.stdout);
            done(err);
        });
    });
});
