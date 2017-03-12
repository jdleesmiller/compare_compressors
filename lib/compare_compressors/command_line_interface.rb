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

    class <<self
      def grouper_options
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
      end
    end

    desc \
      'plot [csv file]',
      'Read CSV from compare and write a gnuplot script'
    grouper_options
    option \
      :terminal,
      desc: 'the terminal line for gnuplot',
      default: Plotter::DEFAULT_TERMINAL
    option \
      :output,
      desc: 'the output name for gnuplot',
      default: Plotter::DEFAULT_OUTPUT
    option \
      :logscale_y,
      desc: 'use a log10 scale for the size (lucky you if you need this)',
      type: :boolean,
      default: Plotter::DEFAULT_LOGSCALE_Y
    option \
      :autoscale_fix,
      desc: 'zoom axes to fit the points tightly',
      type: :boolean,
      default: Plotter::DEFAULT_AUTOSCALE_FIX
    option \
      :show_labels,
      desc: 'show compression level labels on the plot',
      type: :boolean,
      default: Plotter::DEFAULT_SHOW_LABELS
    option \
      :lmargin,
      desc: 'adjust lmargin (workaround if y label is cut off on png)',
      type: :numeric,
      default: Plotter::DEFAULT_LMARGIN

    def plot(csv_file = nil)
      results = read_results(csv_file)
      grouper = make_grouper(options)
      group_results = grouper.group(results)
      group_results = grouper.find_non_dominated(group_results)
      plotter = Plotter.new(
        grouper,
        terminal: options[:terminal],
        output: options[:output],
        logscale_y: options[:logscale_y],
        autoscale_fix: options[:autoscale_fix],
        show_labels: options[:show_labels],
        lmargin: options[:lmargin]
      )
      plotter.plot(group_results)
    end

    desc \
      'summarize [csv file]',
      'Read CSV from compare and write out a summary'
    grouper_options
    def summarize(csv_file = nil)
      results = read_results(csv_file)
      grouper = make_grouper(options)
      group_results = grouper.group(results)
      grouper.summarize(group_results)
    end

    private

    def make_grouper(options)
      Grouper.new(
        gibyte_cost: options[:gibyte_cost],
        hour_cost: options[:hour_cost],
        scale: options[:scale]
      )
    end

    def read_results(csv_file)
      Result.read_csv(csv_file ? File.read(csv_file) : STDIN)
    end
  end
end
