# Wakes the history batches waiting for an import slot when nobody gave one back: a worker
# killed mid-import never runs its `ensure`, its slot comes back only when the lease runs
# out, and nothing is importing then to notice. Also what starts a waiting queue that a
# restart left behind. Every other wake happens the moment a slot is given back.
#
# It is also the backstop for the files of an imported history: a drain that could not be
# queued leaves its inbox's files with nobody to fetch them (HistoryMediaJob.resume_stranded).
class Whatsapp::Baileys::HistoryImportWakeJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Whatsapp::Session::Inbound::ImportSlots.top_up(into: Whatsapp::Baileys::HistoryImportJob.queue_name)
    Whatsapp::Session::HistoryMediaJob.resume_stranded
  end
end
