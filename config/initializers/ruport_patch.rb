module Ruport
  module Data
    class Table
      def to_csv
        csv_string = CSV.generate(:headers => column_names) do |csv|
          csv << column_names
          data.each do |record|
            # Data
            csv << record.data if record.data
          end
        end
        return csv_string
      end
    end
  end
end

