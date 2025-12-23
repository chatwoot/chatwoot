# extracting the diff logic to it's own class for consistency. Currently handles
# an array of Brakeman::Warnings or plain hash representations.  
class Brakeman::Differ
  attr_reader :old_warnings, :new_warnings

  def initialize new_warnings, old_warnings
    @new_warnings = new_warnings
    @old_warnings = old_warnings
  end

  def diff
    warnings = {}
    warnings[:new] = @new_warnings - @old_warnings
    warnings[:fixed] = @old_warnings - @new_warnings

    second_pass(warnings)
  end

  # second pass to cleanup any vulns which have changed in line number only.
  # Given a list of new warnings, delete pairs of new/fixed vulns that differ
  # only by line number.
  def second_pass(warnings)
    new_fingerprints = Set.new(warnings[:new].map(&method(:fingerprint)))
    fixed_fingerprints = Set.new(warnings[:fixed].map(&method(:fingerprint)))

    # Remove warnings which fingerprints are both in :new and :fixed
    shared_fingerprints = new_fingerprints.intersection(fixed_fingerprints)

    unless shared_fingerprints.empty?
      warnings[:new].delete_if do |warning|
        shared_fingerprints.include?(fingerprint(warning))
      end

      warnings[:fixed].delete_if do |warning|
        shared_fingerprints.include?(fingerprint(warning))
      end
    end

    warnings
  end

  def fingerprint(warning)
    if warning.is_a?(Brakeman::Warning)
      warning.fingerprint
    else
      warning[:fingerprint]
    end
  end
end
