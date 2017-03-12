# frozen_string_literal: true

require 'csv'
require 'thor'

module CompareCompressors
  #
  # Handle generic command line options and run the relevant command.
  #
  class CommandLineInterface < Thor
    desc \
      'version',
      'print version (also available as --version)'
    def version
      puts "compare_compressors-#{CompareCompressors::VERSION}"
    end
    map %w(--version -v) => :version

    desc \
      'compare <target files>',
      'Run compression tools on targets and write a CSV'
    def compare(*targets)
      CSV do |csv|
        csv << Result.members
        COMPRESSORS.each do |compressor|
          targets.each do |target|
            compressor.compress(target).each do |result|
              csv << result.to_a
            end
          end
        end
      end
    end

    desc \
      'plot [csv file]',
      'Read CSV from compare and write a gnuplot script'
    option \
      :gibyte_cost,
      type: :numeric,
      desc: 'storage cost per gigabyte of compressed output',
      default: Grouper::DEFAULT_GIBYTE_COST
    option \
      :hour_cost,
      type: :numeric,
      desc: 'compute cost per hour of CPU time for compression',
      default: Grouper::DEFAULT_HOUR_COST
    option \
      :scale,
      type: :numeric,
      desc: 'scale factor from sample targets to full dataset',
      default: 1.0
    def plot(csv_file = nil)
      results = Result.read_csv(csv_file ? File.read(csv_file) : STDIN)
      grouper = Grouper.new(
        gibyte_cost: options[:gibyte_cost],
        hour_cost: options[:hour_cost],
        scale: options[:scale]
      )
      group_results = grouper.group(results)
      group_results = grouper.find_non_dominated(group_results)
      plotter = Plotter.new(grouper)
      plotter.plot(group_results)
    end
  end
end
