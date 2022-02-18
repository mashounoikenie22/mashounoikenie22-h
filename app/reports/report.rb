class Report
  @title = 'Report'

  attr_accessor :date_range, :end, :start, :table
  delegate :to_csv, :to_html, :to_s, :to => :table, :allow_nil => true

  def initialize(options = {})
    @end   = options[:end] if options[:end].present?
    @start = options[:start] if options[:start].present?

    if @start and @end
      @date_range = @start..@end
    elsif @start
      @date_range = @start..Time.now
    elsif options[:date_range].present?
      @date_range = options[:date_range]
    else
      @date_range = nil
    end

    @start_time = Time.now
    @table = self.to_table if self.respond_to?(:to_table)
  end

  def formatted_time(time)
    time.strftime('%Y%m%d%H%M%S')
  end

  def formatted_datetime(datetime)
    datetime.strftime('%m/%d/%Y')
  end

  def formatted_date_range
    "( #{formatted_datetime(@date_range.begin)} to #{formatted_datetime(@date_range.end)} )"
  end

  def csv_filename
    filename = formatted_time(@start_time) << '_'
    if @date_range.present?
      filename << time_period << '_'
    end
    filename << self.title.parameterize('_') << '.csv'
    filename
  end

  def title
    self.class.instance_variable_get(:@title)
  end

  def header
    title + ' ' + (@date_range.present? ? formatted_date_range : '( All Time )')
  end

  def time_period
    seconds = (@date_range.end - @date_range.begin).round
    days = seconds / (60 * 60 * 24)
    if days > 7
      'monthly'
    elsif days > 1
      'weekly'
    else
      'daily'
    end
  end
end