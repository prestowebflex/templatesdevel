require "csv"

module CsvHelpers
  def csv file
    CSV.new(open(file), headers: true, converters: :numeric, header_converters: :symbol)
  end
end