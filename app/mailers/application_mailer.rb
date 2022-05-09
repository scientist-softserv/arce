# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'archives@arce.org'
  layout 'mailer'
end
