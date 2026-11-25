require 'rails_helper'

# `sync` writes the ref it was handed into CONTRACT_REF and copies the checkout's working
# tree, and those were unrelated facts. A checkout sitting on a branch from before the ref
# vendored the old contract under the new ref's name, and nothing said so: `verify` with no
# argument compares the files against the checksum `sync` had just computed from those same
# files, so it agreed about a pair that names a commit it does not correspond to.
RSpec.describe WhatsappContractSource do
  let(:source) { Pathname.new(Dir.mktmpdir) }

  def git(*arguments)
    out, status = Open3.capture2e('git', '-C', source.to_s, *arguments)
    raise "git #{arguments.join(' ')} failed: #{out}" unless status.success?

    out.strip
  end

  before do
    git('init', '--quiet', '--initial-branch', 'main')
    git('config', 'user.email', 'spec@fazer.ai')
    git('config', 'user.name', 'spec')
    source.join('contract').mkpath
    source.join('contract/PROTOCOL_VERSION').write("1\n")
    git('add', '-A')
    git('commit', '--quiet', '-m', 'first')
  end

  after { FileUtils.rm_rf(source) }

  describe '.commit_for' do
    it 'answers the checked out commit when no ref was named' do
      expect(described_class.commit_for(source, nil)).to eq(git('rev-parse', 'HEAD'))
    end

    it 'answers it when the ref names that same commit' do
      expect(described_class.commit_for(source, git('rev-parse', 'HEAD'))).to eq(git('rev-parse', 'HEAD'))
    end

    # The whole point: the copy would be the old contract and the stamp would be the new
    # ref, and every check downstream compares the copy against a checksum taken from it.
    it 'refuses a ref the checkout is not on, naming both commits' do
      behind = git('rev-parse', 'HEAD')
      source.join('contract/PROTOCOL_VERSION').write("2\n")
      git('commit', '--quiet', '-am', 'second')
      ahead = git('rev-parse', 'HEAD')
      git('checkout', '--quiet', behind)

      expect { described_class.commit_for(source, ahead) }
        .to raise_error(SystemExit).and output(/#{behind[0, 12]}.*#{ahead[0, 12]}/m).to_stderr
    end

    # A branch or a tag has to resolve the same way a sha does, or naming the ref a release
    # was cut from would be refused for being spelled differently.
    it 'accepts a tag that resolves to the checked out commit' do
      git('tag', 'v1.0.0')

      expect(described_class.commit_for(source, 'v1.0.0')).to eq(git('rev-parse', 'HEAD'))
    end

    it 'refuses a ref the checkout has never heard of' do
      expect { described_class.commit_for(source, 'no-such-ref') }
        .to raise_error(SystemExit).and output(/does not know no-such-ref/).to_stderr
    end

    it 'refuses a directory that is no checkout at all, rather than stamping an empty ref' do
      plain = Pathname.new(Dir.mktmpdir)

      expect { described_class.commit_for(plain, nil) }.to raise_error(SystemExit).and output(/not a git checkout/).to_stderr
    ensure
      FileUtils.rm_rf(plain)
    end
  end

  # Not a refusal: a contract change is tried from both sides before it is a commit. What it
  # must not do is let the line the task prints claim the copy is that commit.
  describe '.local_edits' do
    it 'says nothing about a clean checkout' do
      expect(described_class.local_edits(source)).to eq('')
    end

    it 'counts what the working tree carries on top of the commit' do
      source.join('contract/PROTOCOL_VERSION').write("2\n")

      expect(described_class.local_edits(source)).to eq(' plus 1 uncommitted change(s) to contract/')
    end

    it 'ignores changes outside the contract directory' do
      source.join('main.go').write("package main\n")

      expect(described_class.local_edits(source)).to eq('')
    end
  end
end
