class GenerateMonthlyReports < GenerateReports
  @queue = :generate_reports_queue

  def self.last_month
    (Time.now.midnight - 1.month)..(Time.now.midnight)
  end

  def self.perform
    reports = []

    reports << { :class   => ProvidersReport,
                 :options => { :date_range => last_month } }
    reports << { :class   => OutsReport,
                 :options => { :date_range => last_month } }
    reports << { :class   => ErrorsReport,
                 :options => { :date_range => last_month } }

    super(reports, "Reports for Month Starting #{last_month.begin.strftime('%Y-%m-%d')}")
  end
end