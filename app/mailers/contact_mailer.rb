class ContactMailer < ActionMailer::Base
  default :from => "contact@mashoutable.info"
  default :to   => "contact@mashoutable.info"

  def new_message(message)
    mail(:from => message.email, 
         :body => message.body, 
         :subject => "Mashoutable.com message: #{message.name} #{message.subject}")
  end
end
