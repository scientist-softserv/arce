# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Blacklight::Catalog
  layout 'blacklight'

  protect_from_forgery with: :exception
  before_action :set_raven_context
  helper_method :current_user, :logged_in?, :herd_user

  def herd_user
    redirect_to root_path, notice: "You do not have permission to access this page." if current_user.nil?
  end

  private

    def set_raven_context
      Raven.user_context(id: session[:current_user_id]) # or anything else in session
      Raven.extra_context(params: params.to_unsafe_h, url: request.url)
    end
end
