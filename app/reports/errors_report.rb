class ErrorsReport < Report
  @title = 'Errors Report'

  def to_table
    table = Table(%w(Source Error Count Percent))

    if @date_range
      error_sources = OutError.where(:created_at => @date_range).count(:all, :group => :source)
    else
      error_sources = OutError.count(:all, :group => :source)
    end

    error_sources = error_sources.sort_by { |source, count| count }.reverse

    error_sources.each do |source, count|
      table << { 'Source'  => source.titleize,
                 'Error'   => nil,
                 'Count'   => nil,
                 'Percent' => nil }

      source_error_counts = OutError.where(:source => source)
      if @date_range
        source_error_counts = source_error_counts.where(:created_at => @date_range)
      end
      source_error_counts = source_error_counts.count(:all, :group => :error)
      source_error_counts = source_error_counts.sort_by { |error, count| count}.reverse

      source_error_counts.each do |error, count|
        table << { 'Source'  => nil,
                   'Error'   => error,
                   'Count'   => count,
                   'Percent' => '%.2f%' % ((count.to_f / (source_error_counts.map { |error, count| count }.inject(:+)).to_f) * 100) }
      end
    end

    table << { 'Source'  => 'Total',
               'Error'   => nil,
               'Count'   => table.sum('Count'),
               'Percent' => nil }

    table
  end
end