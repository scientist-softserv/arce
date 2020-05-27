class ImportRecordsJob < ProgressJob::Base

  def perform
    update_stage('Importing Records')
    update_progress_max(ArceItem.total_records)
    ArceItem.import({ limit: 20000000, progress: false }) do |total|
      update_progress
    end
  end
end