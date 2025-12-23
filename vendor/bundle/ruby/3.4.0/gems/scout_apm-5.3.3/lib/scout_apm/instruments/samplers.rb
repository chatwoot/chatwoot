module ScoutApm
  module Instruments
    class Samplers
      DEFAULT_SAMPLERS = [
        ScoutApm::Instruments::Process::ProcessCpu,
        ScoutApm::Instruments::Process::ProcessMemory,
        ScoutApm::Instruments::PercentileSampler,
      ]
    end
  end
end
