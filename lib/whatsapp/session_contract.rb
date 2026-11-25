# Access to the vendored copy of the WhatsApp session protocol contract, shared by the
# specs (which validate every canonical payload against it) and by the rake tasks that
# sync it and check it for drift.
#
# The contract itself lives in fazer-ai/whatsapp-connector: the connector is what
# produces events, so it owns the schema. This copy is pinned by CONTRACT_REF.
module Whatsapp::SessionContract
  ROOT = 'spec/fixtures/whatsapp/session/contract'.freeze
  REFERENCE_FILE = 'CONTRACT_REF'.freeze
  # Not part of the contract. CONTRACT_REF stores the result of hashing it, and the
  # connector's README describes the directory to somebody reading it there -- `sync` drops
  # it, so counting it would make every comparison against the connector report drift.
  UNVENDORED = [REFERENCE_FILE, 'README.md'].freeze

  class << self
    def root
      Rails.root.join(ROOT)
    end

    def protocol_version
      root.join('PROTOCOL_VERSION').read.strip.to_i
    end

    def schema
      @schema ||= JSON.parse(root.join('schema/protocol.schema.json').read)
    end

    def event_validator
      @event_validator ||= validator_for('event')
    end

    def command_validator
      @command_validator ||= validator_for('command')
    end

    def fixtures(kind)
      Dir[root.join("fixtures/#{kind}/*.json")]
    end

    def fixture(kind, name)
      JSON.parse(root.join("fixtures/#{kind}/#{name}.json").read)
    end

    # Content hash of every vendored file, so a drift check does not depend on git.
    #
    # The formula is load-bearing: every CONTRACT_REF ever written records its output, so
    # concatenating each path with the file's raw bytes is not a detail to tidy up. Hashing
    # the files individually first and folding those digests together produces a different
    # answer and unpins every copy in the fleet.
    def checksum(directory = root)
      digest = contract_files(directory).sum('') do |path|
        "#{Pathname.new(path).relative_path_from(Pathname.new(directory))}\0#{File.read(path)}\0"
      end
      Digest::SHA256.hexdigest(digest)
    end

    # Every contract file with the hash of its contents, keyed by its path inside the
    # contract directory, so two copies can be compared file by file rather than only
    # judged equal or not.
    def manifest(directory = root)
      contract_files(directory).to_h do |path|
        [Pathname.new(path).relative_path_from(Pathname.new(directory)).to_s, Digest::SHA256.hexdigest(File.read(path))]
      end
    end

    # What this copy is missing, carrying or holding a stale version of, against another
    # checkout of the contract. `behind` is the one that matters: a type the connector has
    # added and this side has no model for is dispatched as Unknown and logged as an unknown
    # payload, which is the same shape as a type we deliberately ignore -- so the IGNORED
    # list, which exists so a dropped type is a decision on the record, is bypassed entirely.
    def diff(other)
      ours = manifest
      theirs = manifest(other)
      shared = ours.keys & theirs.keys

      { stale: shared.reject { |path| ours[path] == theirs[path] }.sort,
        behind: (theirs.keys - ours.keys).sort,
        ahead: (ours.keys - theirs.keys).sort }
    end

    # Parsed CONTRACT_REF: which connector commit this copy came from, and the checksum
    # it had at that point.
    def reference
      root.join(REFERENCE_FILE).read.lines.to_h do |line|
        key, value = line.strip.split('=', 2)
        [key, value]
      end
    end

    def drifted?
      reference['checksum'] != checksum
    end

    def write_reference(repo:, ref:)
      root.join(REFERENCE_FILE).write("repo=#{repo}\nref=#{ref}\nchecksum=#{checksum}\n")
    end

    private

    def contract_files(directory)
      Dir.glob("#{directory}/**/*").select { |path| File.file?(path) && UNVENDORED.exclude?(File.basename(path)) }.sort
    end

    # json_schemer resolves $ref against the document root, so a sub-schema is validated
    # by pointing a tiny wrapper document at it.
    def validator_for(definition)
      JSONSchemer.schema({ '$ref' => "#/definitions/#{definition}", 'definitions' => schema['definitions'] })
    end
  end
end
