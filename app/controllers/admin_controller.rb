# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :authenticate_user!

  def index
    @job_running = ArceItem.check_for_tmp_file
    @collections = Collection.all
  end

  def run_import
    @job = Delayed::Job.enqueue ImportRecordsJob.new(delete: params[:delete])
  end
end
