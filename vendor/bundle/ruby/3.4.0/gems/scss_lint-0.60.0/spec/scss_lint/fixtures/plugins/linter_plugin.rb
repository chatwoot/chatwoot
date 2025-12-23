module SCSSLint
  class Linter
    class LinterPlugin < Linter
      include LinterRegistry
    end
  end
end
