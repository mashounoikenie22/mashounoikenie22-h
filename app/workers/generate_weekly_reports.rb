class GenerateWeeklyReports < GenerateReports
  @queue = :generate_reports_queue

  def self.last_week
    (Time.now.midnight - 1.week)..(Time.now.midnight)
  end

  def self.perform
    reports = []

    reports << { :class   => ProvidersReport,
                 :options => { :date_range => last_week } }
    reports << { :class   => OutsReport,
                 :options => { :date_range => last_week } }
    reports << { :class   => ErrorsReport,
                 :options => { :date_range => last_week } }

    super(reports, "Reports for Week Starting #{last_week.begin.strftime('%Y-%m-%d')}")
  end
end