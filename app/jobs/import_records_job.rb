# frozen_string_literal: true

class ImportRecordsJob < ProgressJob::Base
  def initialize(args = {})
    @args = args
  end

  def perform
    update_stage('Importing Records')
    update_progress_max(ArceItem.total_records)
    ArceItem.import({ limit: 20_000_000, progress: false }.merge(@args)) do |_total|
      update_progress
    end
  end
end
