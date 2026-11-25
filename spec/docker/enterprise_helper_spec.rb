require 'spec_helper'
require 'digest'
require 'fileutils'
require 'open3'
require 'tmpdir'

# The image ships without enterprise/, and this helper is what brings it in at boot: from the
# official tag, checked against the hash pinned when the image was built, into the storage
# entry that the image's /app/enterprise link points at. What can go wrong here goes wrong on
# a paying installation, so each failure has to stop the boot with a message, and each
# success has to leave exactly the pinned tree where Rails looks for it.
#
# Run against a temporary directory shaped like the image, with the tarball served from disk
# (curl reads file:// URLs), so no example needs the network.
# rubocop:disable RSpec/DescribeClass -- the subject is a shell script, not a constant
RSpec.describe 'docker/entrypoints/helpers/enterprise.sh', type: :script do
  let(:work_dir) { Dir.mktmpdir }
  let(:app_dir) { File.join(work_dir, 'app') }
  let(:helper) { File.join(app_dir, 'docker/entrypoints/helpers/enterprise.sh') }
  let(:version) { '4.19.0' }
  let(:tree) { { 'app/models/enterprise/thing.rb' => "module Enterprise::Thing; end\n", 'config/premium.yml' => "a: 1\n" } }
  let(:tarball) { File.join(work_dir, 'source.tar.gz') }
  let(:unreachable) { 'http://127.0.0.1:9/unreachable.tar.gz' }
  # the tree hash as the helper defines it, computed here independently of the helper
  let(:pinned) do
    lines = tree.keys.map { |path| "enterprise/#{path}" }.sort.map do |path|
      "#{Digest::SHA256.hexdigest(tree.fetch(path.delete_prefix('enterprise/')))}  #{path}\n"
    end
    Digest::SHA256.hexdigest(lines.join)
  end
  let(:cache_root) { File.join(app_dir, 'storage/.cw-enterprise') }
  let(:entry) { File.join(cache_root, "#{version}-#{pinned}") }

  before do
    FileUtils.mkdir_p([File.dirname(helper), File.join(app_dir, 'storage')])
    FileUtils.cp(File.expand_path('../../docker/entrypoints/helpers/enterprise.sh', __dir__), helper)
    FileUtils.chmod(0o755, helper)
    File.write(File.join(app_dir, 'VERSION_CW'), "#{version}\n")
    write_lock(version, pinned)
    # what the image's Dockerfile leaves in place of the tree
    File.symlink('tmp/cw-enterprise', File.join(app_dir, 'enterprise'))
    build_tarball(tree)
  end

  after do
    FileUtils.chmod(0o755, app_dir)
    FileUtils.chmod(0o755, cache_root) if Dir.exist?(cache_root)
    FileUtils.remove_entry(work_dir)
  end

  def write_lock(locked_version, sha)
    File.write(File.join(app_dir, '.enterprise_lock'), "version=#{locked_version}\nsha256=#{sha}\n")
  end

  # A tarball laid out like GitHub's: one top directory named after the repository and the
  # tag, with the whole repository under it.
  def build_tarball(files, top: "chatwoot-#{version}")
    src = File.join(work_dir, 'src')
    FileUtils.rm_rf(src)
    files.each do |path, content|
      file = File.join(src, top, 'enterprise', path)
      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, content)
    end
    FileUtils.mkdir_p(File.join(src, top, 'app'))
    File.write(File.join(src, top, 'app/not_enterprise.rb'), "# outside enterprise/\n")
    _out, err, status = Open3.capture3('tar', '-czf', tarball, '-C', src, top)
    raise err unless status.success?
  end

  def ensure_enterprise(env = {}, umask = '022')
    defaults = { 'CW_EDITION' => 'ee', 'DISABLE_ENTERPRISE' => nil, 'CW_ENTERPRISE_SOURCE_URL' => "file://#{tarball}",
                 'CW_ENTERPRISE_FETCH_RETRIES' => '0' }
    Open3.capture3(defaults.merge(env), 'sh', '-c', "umask #{umask}; exec \"$0\" ensure", helper)
  end

  # what Rails sees through the link
  def installed
    root = File.join(app_dir, 'enterprise/')
    Dir.glob('**/*', base: root).select { |path| File.file?(File.join(root, path)) }.sort
  end

  it 'does nothing unless the edition asks for enterprise, and the dangling link reads as no enterprise/' do
    _out, err, status = ensure_enterprise('CW_EDITION' => nil)

    expect(status).to be_success
    expect(err).to include("edition 'unset'")
    expect(Pathname.new(app_dir).join('enterprise')).not_to exist
  end

  it 'does nothing when DISABLE_ENTERPRISE is set, since Rails would not load it anyway' do
    _out, _err, status = ensure_enterprise('DISABLE_ENTERPRISE' => 'true')

    expect(status).to be_success
    expect(Dir).not_to exist(cache_root)
  end

  it 'downloads, verifies and caches only enterprise/, where the link points' do
    _out, err, status = ensure_enterprise

    expect(status).to be_success
    expect(err).to include('downloaded, verified and installed')
    expect(installed).to eq(tree.keys.sort)
    expect(Dir.children(entry)).to eq(['enterprise'])
    expect(Dir.children(cache_root).grep(/incoming/)).to be_empty
  end

  it 'uses an intact cache without reaching the source' do
    ensure_enterprise

    _out, err, status = ensure_enterprise('CW_ENTERPRISE_SOURCE_URL' => unreachable)

    expect(status).to be_success
    expect(err).to include('in place from')
    expect(err).not_to include('downloading')
    expect(installed).to eq(tree.keys.sort)
  end

  # A published entry may be in use by other containers, so a damaged one is reported, not
  # replaced under them.
  it 'stops the boot, and leaves the entry alone, when the cached tree was tampered with' do
    ensure_enterprise
    File.write(File.join(entry, 'enterprise/config/premium.yml'), "a: 2\n")

    _out, err, status = ensure_enterprise

    expect(status).not_to be_success
    expect(err).to include('no longer matches the pinned hash', "rm -rf #{entry}")
    expect(err).not_to include('downloading')
    expect(File.read(File.join(entry, 'enterprise/config/premium.yml'))).to eq("a: 2\n")
  end

  it 'gives the way out for a tampered tree even on a volume it cannot write' do
    ensure_enterprise
    File.write(File.join(entry, 'enterprise/config/premium.yml'), "a: 2\n")
    FileUtils.chmod(0o444, File.join(cache_root, '.lock'))
    FileUtils.chmod(0o555, cache_root)

    _out, err, status = ensure_enterprise

    expect(status).not_to be_success
    expect(err).to include('no longer matches the pinned hash', "rm -rf #{entry}")
    expect(err).not_to include('cannot open')
  end

  it 'downloads anew once the damaged entry was removed' do
    ensure_enterprise
    File.write(File.join(entry, 'enterprise/config/premium.yml'), "a: 2\n")
    FileUtils.rm_rf(entry)

    _out, _err, status = ensure_enterprise

    expect(status).to be_success
    expect(File.read(File.join(app_dir, 'enterprise/config/premium.yml'))).to eq("a: 1\n")
  end

  it 'clears what a download killed halfway left behind' do
    FileUtils.mkdir_p(File.join(cache_root, '.incoming.killed/extract'))

    _out, _err, status = ensure_enterprise

    expect(status).to be_success
    expect(Dir.children(cache_root).grep(/incoming/)).to be_empty
  end

  it 'ignores a cache that holds another version and downloads this one' do
    other = File.join(cache_root, "4.18.0-#{'0' * 64}", 'enterprise')
    FileUtils.mkdir_p(other)
    File.write(File.join(other, 'old.rb'), "# 4.18.0\n")

    _out, err, status = ensure_enterprise

    expect(status).to be_success
    expect(err).to include('downloaded, verified and installed')
    expect(installed).to eq(tree.keys.sort)
    expect(File).to exist(File.join(other, 'old.rb'))
  end

  # Going back from CW_EDITION=ee to the default keeps the volume, and the tree in it.
  describe 'after an Enterprise boot left the tree in the volume' do
    before { ensure_enterprise }

    it 'turns enterprise/ off again for a container that does not ask for it' do
      _out, _err, status = ensure_enterprise('CW_EDITION' => nil)

      expect(status).to be_success
      expect(Pathname.new(app_dir).join('enterprise')).not_to exist
      expect(File).to exist(File.join(entry, 'enterprise/config/premium.yml'))
    end

    it 'turns enterprise/ off when DISABLE_ENTERPRISE is set' do
      _out, _err, status = ensure_enterprise('DISABLE_ENTERPRISE' => '1')

      expect(status).to be_success
      expect(Pathname.new(app_dir).join('enterprise')).not_to exist
    end

    it 'turns it back on from the cache, without the network, when the edition asks again' do
      ensure_enterprise('CW_EDITION' => 'ce')

      _out, _err, status = ensure_enterprise('CW_ENTERPRISE_SOURCE_URL' => unreachable)

      expect(status).to be_success
      expect(installed).to eq(tree.keys.sort)
    end
  end

  it 'leaves a checkout without a lock alone when the edition is not ee' do
    FileUtils.rm_f(File.join(app_dir, '.enterprise_lock'))

    _out, _err, status = ensure_enterprise('CW_EDITION' => nil)

    expect(status).to be_success
  end

  # A volume filled by one UID can be mounted later by another (root first, then an
  # unprivileged user, or the reverse). Switching UIDs needs root, so these hold the
  # conditions that UID would meet: modes another user can read, and files this one
  # cannot write.
  describe 'a volume shared across UIDs' do
    it 'publishes the tree readable by everyone, whatever the umask' do
      _out, _err, status = ensure_enterprise({}, '077')

      expect(status).to be_success
      modes = Dir.glob('**/*', base: entry).push('.').map do |path|
        full = File.join(entry, path)
        [File.directory?(full), File.stat(full).mode & 0o777]
      end
      expect(modes.select(&:first).map(&:last).uniq).to eq([0o755])
      expect(modes.reject(&:first).map(&:last).uniq).to eq([0o644])
      expect(File.stat(cache_root).mode & 0o777).to eq(0o755)
      expect(File.stat(File.join(cache_root, '.lock')).mode & 0o777).to eq(0o644)
    end

    it 'uses an intact entry without writing to the volume, which may be read-only' do
      ensure_enterprise
      FileUtils.chmod(0o444, File.join(cache_root, '.lock'))
      FileUtils.chmod(0o555, cache_root)

      _out, _err, status = ensure_enterprise('CW_ENTERPRISE_SOURCE_URL' => unreachable)

      expect(status).to be_success
      expect(installed).to eq(tree.keys.sort)
    end

    it 'says so when it has to download but cannot write the lock' do
      FileUtils.mkdir_p(cache_root)
      File.write(File.join(cache_root, '.lock'), '')
      FileUtils.chmod(0o444, File.join(cache_root, '.lock'))

      _out, err, status = ensure_enterprise

      expect(status).not_to be_success
      expect(err).to include('cannot open', 'for writing', 'holds no verified tree')
    end

    it 'says so when it has to download into a cache it cannot write' do
      FileUtils.mkdir_p(cache_root)
      FileUtils.chmod(0o555, cache_root)

      _out, err, status = ensure_enterprise

      expect(status).not_to be_success
      expect(err).to include('cannot open', 'holds no verified tree')
    end
  end

  # Each container decides its own edition. The web and worker containers share the cache,
  # and a container running Enterprise must keep its tree while another one on the same
  # volume boots without it, or with it.
  describe 'two containers on the same storage volume' do
    let(:other_app) { File.join(work_dir, 'other') }
    let(:other_helper) { File.join(other_app, 'docker/entrypoints/helpers/enterprise.sh') }

    before do
      FileUtils.mkdir_p(File.dirname(other_helper))
      FileUtils.cp(helper, other_helper)
      %w[VERSION_CW .enterprise_lock].each { |name| FileUtils.cp(File.join(app_dir, name), other_app) }
      File.symlink(File.join(app_dir, 'storage'), File.join(other_app, 'storage'))
      File.symlink('tmp/cw-enterprise', File.join(other_app, 'enterprise'))
    end

    def ensure_other(env)
      Open3.capture3({ 'DISABLE_ENTERPRISE' => nil, 'CW_ENTERPRISE_SOURCE_URL' => unreachable }.merge(env), other_helper, 'ensure')
    end

    it 'keeps enterprise/ for the running Enterprise container while another one boots as Community' do
      ensure_enterprise

      _out, _err, status = ensure_other('CW_EDITION' => 'ce')

      expect(status).to be_success
      expect(Pathname.new(other_app).join('enterprise')).not_to exist
      expect(installed).to eq(tree.keys.sort)
    end

    it 'keeps a Community container without enterprise/ while another one boots as Enterprise' do
      ensure_enterprise
      ensure_enterprise('CW_EDITION' => 'ce')

      _out, _err, status = ensure_other('CW_EDITION' => 'ee')

      expect(status).to be_success
      expect(Pathname.new(other_app).join('enterprise/config/premium.yml')).to exist
      expect(Pathname.new(app_dir).join('enterprise')).not_to exist
    end
  end

  # /app can be a read-only filesystem, or owned by another user than the one running
  # the container. tmp/ stays writable, as Rails needs it to be (a tmpfs on a read-only
  # root), and that is where the activation lives.
  describe 'with /app read-only' do
    before do
      FileUtils.mkdir_p(File.join(app_dir, 'tmp'))
      FileUtils.chmod(0o555, app_dir)
    end

    it 'downloads into storage and boots' do
      _out, _err, status = ensure_enterprise

      expect(status).to be_success
      expect(installed).to eq(tree.keys.sort)
    end

    it 'boots from an intact cache' do
      FileUtils.chmod(0o755, app_dir)
      ensure_enterprise
      FileUtils.chmod(0o555, app_dir)

      _out, _err, status = ensure_enterprise('CW_ENTERPRISE_SOURCE_URL' => unreachable)

      expect(status).to be_success
      expect(installed).to eq(tree.keys.sort)
    end
  end

  # The web and worker containers share the cache, and a `docker exec` of a rake can run the
  # helper next to the entrypoint's own run: they must not download twice or pull the tree
  # out from under each other.
  it 'lets concurrent runs share one download' do
    bin_dir = File.join(work_dir, 'bin')
    calls = File.join(work_dir, 'curl_calls')
    FileUtils.mkdir_p(bin_dir)
    File.write(File.join(bin_dir, 'curl'), <<~SH)
      #!/bin/sh
      echo call >> "#{calls}"
      sleep 1
      cat "#{tarball}"
    SH
    FileUtils.chmod(0o755, File.join(bin_dir, 'curl'))
    env = { 'PATH' => "#{bin_dir}:#{ENV.fetch('PATH')}" }

    results = Array.new(3) { Thread.new { ensure_enterprise(env) } }.map(&:value)

    expect(results.map { |_out, _err, status| status.success? }).to all(be(true))
    expect(File.readlines(calls).size).to eq(1)
    expect(installed).to eq(tree.keys.sort)
  end

  it 'refuses a download whose tree does not match the pinned hash, and caches nothing' do
    build_tarball(tree.merge('app/models/enterprise/thing.rb' => "module Enterprise::Thing; def x; end; end\n"))

    _out, err, status = ensure_enterprise

    expect(status).not_to be_success
    expect(err).to include("the image pins #{pinned}. Not starting")
    expect(Pathname.new(app_dir).join('enterprise')).not_to exist
    expect(Dir.children(cache_root).reject { |name| name == '.lock' }).to be_empty
  end

  it 'recovers from a transfer cut halfway, starting the archive over instead of appending to it' do
    bin = File.join(work_dir, 'bin')
    FileUtils.mkdir_p(bin)
    count = File.join(work_dir, 'curl_calls')
    # the first call sends half of the archive and fails, as a dropped connection does
    File.write(File.join(bin, 'curl'), <<~SH)
      #!/bin/sh
      n=$(cat "#{count}" 2>/dev/null || echo 0); n=$((n + 1)); echo "$n" > "#{count}"
      size=$(wc -c < "#{tarball}")
      if [ "$n" -eq 1 ]; then head -c $((size / 2)) "#{tarball}"; exit 18; fi
      cat "#{tarball}"
    SH
    FileUtils.chmod(0o755, File.join(bin, 'curl'))

    _out, err, status = ensure_enterprise('PATH' => "#{bin}:#{ENV.fetch('PATH')}", 'CW_ENTERPRISE_FETCH_RETRIES' => '1')

    expect(status).to be_success, err
    expect(File.read(count).strip).to eq('2')
    expect(installed).to eq(tree.keys.sort)
  end

  it 'stops the boot when the source cannot be reached and nothing is cached' do
    _out, err, status = ensure_enterprise('CW_ENTERPRISE_SOURCE_URL' => unreachable)

    expect(status).not_to be_success
    expect(err).to include('could not download enterprise/ for v4.19.0')
    expect(err).to include('remove CW_EDITION=ee')
    expect(Dir.children(cache_root).reject { |name| name == '.lock' }).to be_empty
  end

  it 'stops the boot when the tarball is not for the version in VERSION_CW' do
    build_tarball(tree, top: 'chatwoot-4.18.0')

    _out, err, status = ensure_enterprise

    expect(status).not_to be_success
    expect(err).to include('could not download enterprise/ for v4.19.0')
  end

  it 'stops the boot when the lock pins another version than the image carries' do
    write_lock('4.18.0', pinned)

    _out, err, status = ensure_enterprise

    expect(status).not_to be_success
    expect(err).to include('pins v4.18.0, but this image is v4.19.0')
  end

  it 'stops the boot when the image has no lock at all' do
    FileUtils.rm_f(File.join(app_dir, '.enterprise_lock'))

    _out, err, status = ensure_enterprise

    expect(status).not_to be_success
    expect(err).to include('no hash to check enterprise/ against')
  end

  it 'stops the boot when /app/enterprise does not lead to the verified tree' do
    File.unlink(File.join(app_dir, 'enterprise'))
    FileUtils.mkdir_p(File.join(app_dir, 'enterprise'))

    _out, err, status = ensure_enterprise

    expect(status).not_to be_success
    expect(err).to include('does not lead to the verified tree')
  end

  it 'refuses to hash a tree that holds a symlink, whose target the hash would not cover' do
    dir = File.join(work_dir, 'linked/enterprise')
    FileUtils.mkdir_p(dir)
    File.symlink('/etc/hosts', File.join(dir, 'hosts'))

    _out, _err, status = Open3.capture3(helper, 'tree-hash', dir)

    expect(status).not_to be_success
  end
end
# rubocop:enable RSpec/DescribeClass
