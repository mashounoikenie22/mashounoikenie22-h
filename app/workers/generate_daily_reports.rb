class GenerateDailyReports < GenerateReports
  @queue = :generate_reports_queue

  def self.yesterday
    (Time.now.midnight - 1.day)..(Time.now.midnight)
  end

  def self.perform
    reports = []

    reports << { :class   => ProvidersReport }
    reports << { :class   => ProvidersReport,
                 :options => { :date_range => yesterday } }
    reports << { :class   => OutsReport,
                 :options => { :date_range => yesterday } }
    reports << { :class   => ErrorsReport,
                 :options => { :date_range => yesterday } }

    super(reports, "Reports for #{yesterday.begin.strftime('%Y-%m-%d')}")
  end
end