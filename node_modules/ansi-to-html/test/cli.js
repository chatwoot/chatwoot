const childProcess = require('child_process');
const {EOL} = require('os');
const {expect} = require('chai');

function getColorCmd(cmd) {
    const cmds = {
        darwin: `CLICOLOR_FORCE="1" ${cmd} | node lib/cli`,
        linux: `CLICOLOR="1" ${cmd} | node lib/cli`,
        // for win32 compatibility, make sure there is no space between the cmd and the pipe
        win32: `${cmd}| node lib/cli`
    };

    return cmds[process.platform];
}

function echo(str) {
    if (process.platform === 'win32') {
        return `echo ${str}`;
    }
    return `echo "${str}"`;
}

describe('cli', function () {
    it('converts colors', function (done) {
        const data = echo('what\033[0;31m what?');
        const result = `what<span style="color:#A00"> what?${EOL}</span>`;

        childProcess.exec(getColorCmd(data), {
            timeout: 10000
        }, (err, stdout, stderr) => {
            if (err) {
                return done(err);
            }

            if (stderr) {
                return done(stderr);
            }

            expect(stdout).to.equal(result);

            done();
        });
    });
});
