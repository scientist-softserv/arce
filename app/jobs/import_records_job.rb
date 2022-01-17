class ImportRecordsJob < ProgressJob::Base

  def initialize(args = {})
    @args = args
  end

  def perform
    update_stage('Importing Records')
    update_progress_max(ArceItem.total_records)
    ArceItem.import({ limit: 20000000, progress: false }.merge(@args)) do |total|
      update_progress
    end
  end
end