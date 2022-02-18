class ReportMailer < ActionMailer::Base
  default :from => "reports@mashoutable.com",
          :to => "mhhenterprises@aim.com",
          :cc => "nicholaspapillon@gmail.com"

  def report_email(reports, subject = "Reports for #{Date.today}")
    @reports = reports

    unless @reports.is_a?(Array)
      @reports = [@reports]
    end

    @reports.each do |report|
      attachments[report.csv_filename] = report.to_csv
    end
    mail(:subject => subject)
  end
end

