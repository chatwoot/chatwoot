# frozen_string_literal: true

module CustomExceptions::Report
  class InvalidIdentity < CustomExceptions::Base
    def message
      "Invalid type"
    end
  end

  class IdentityNotFound < CustomExceptions::Base
    def message
      "Type with the specified id not found"
    end
  end

  class MetricNotFound < CustomExceptions::Base
    def message
      "Metric for the specified type not found"
    end
  end

  class InvalidStartTime < CustomExceptions::Base
    def message
      "Invalid start_time"
    end
  end

  class InvalidEndTime < CustomExceptions::Base
    def message
      "Invalid end_time"
    end
  end
end
