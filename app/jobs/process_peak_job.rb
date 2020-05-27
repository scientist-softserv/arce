class ProcessPeakJob < ApplicationJob
  queue_as :peaks

  def perform(id)
    puts "Processing peaks for: #{id}"
    ArceItem.find(id).generate_peaks
  end
end
