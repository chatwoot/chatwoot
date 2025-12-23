# frozen_string_literal: true

require "spec_helper"

if String.method_defined?(:encoding)
  require "diff/lcs/hunk"

  describe Diff::LCS::Hunk do
    let(:old_data) { ["Tu a un carté avec {count} itéms".encode("UTF-16LE")] }
    let(:new_data) { ["Tu a un carte avec {count} items".encode("UTF-16LE")] }
    let(:pieces) { Diff::LCS.diff old_data, new_data }
    let(:hunk) { Diff::LCS::Hunk.new(old_data, new_data, pieces[0], 3, 0) }

    it "produces a unified diff from the two pieces" do
      expected = <<-EXPECTED.gsub(/^\s+/, "").encode("UTF-16LE").chomp
        @@ -1 +1 @@
        -Tu a un carté avec {count} itéms
        +Tu a un carte avec {count} items
      EXPECTED

      expect(hunk.diff(:unified)).to eq(expected)
    end

    it "produces a unified diff from the two pieces (last entry)" do
      expected = <<-EXPECTED.gsub(/^\s+/, "").encode("UTF-16LE").chomp
        @@ -1 +1 @@
        -Tu a un carté avec {count} itéms
        +Tu a un carte avec {count} items
        \\ No newline at end of file
      EXPECTED

      expect(hunk.diff(:unified, true)).to eq(expected)
    end

    it "produces a context diff from the two pieces" do
      expected = <<-EXPECTED.gsub(/^\s+/, "").encode("UTF-16LE").chomp
        ***************
        *** 1 ****
        ! Tu a un carté avec {count} itéms
        --- 1 ----
        ! Tu a un carte avec {count} items
      EXPECTED

      expect(hunk.diff(:context)).to eq(expected)
    end

    it "produces an old diff from the two pieces" do
      expected = <<-EXPECTED.gsub(/^ +/, "").encode("UTF-16LE").chomp
        1c1
        < Tu a un carté avec {count} itéms
        ---
        > Tu a un carte avec {count} items

      EXPECTED

      expect(hunk.diff(:old)).to eq(expected)
    end

    it "produces a reverse ed diff from the two pieces" do
      expected = <<-EXPECTED.gsub(/^ +/, "").encode("UTF-16LE").chomp
        c1
        Tu a un carte avec {count} items
        .

      EXPECTED

      expect(hunk.diff(:reverse_ed)).to eq(expected)
    end

    context "with empty first data set" do
      let(:old_data) { [] }

      it "produces a unified diff" do
        expected = <<-EXPECTED.gsub(/^\s+/, "").encode("UTF-16LE").chomp
          @@ -1 +1,2 @@
          +Tu a un carte avec {count} items
        EXPECTED

        expect(hunk.diff(:unified)).to eq(expected)
      end
    end
  end
end
