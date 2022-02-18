class GenerateReports
  @queue = :generate_reports_queue

  def self.perform(reports_to_generate, email_subject)
    reports = []

    reports_to_generate.each do |report|
      klass   = report[:class].is_a?(Class) ? report[:class] : report[:class].safe_constantize
      options = report[:options]

      next if klass.nil?

      reports << (options.present? ? klass.send(:new, options) : klass.send(:new))
    end

    ReportMailer.report_email(reports, email_subject).deliver
  end
end

