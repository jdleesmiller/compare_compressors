# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

module CompareCompressors
  #
  # Base class for compressors.
  #
  class Compressor
    def compress(target)
      remove_output target
      levels.map { |level| compress_level(target, level) }
    end

    def compress_level(target, level)
      status, time, max_rss, out, err = run(*command(target, level))
      raise "compress: #{name} failed:\n#{out}\n#{err}" unless status.zero?
      size = output_size(target)
      remove_output target
      Result.new(target, name, level, time, max_rss, size)
    end

    def display_name
      name
    end

    def output_size(target)
      File.stat(output_name(target)).size
    end

    def output_name(target)
      "#{target}.#{extension}"
    end

    def remove_output(target)
      FileUtils.rm output_name(target)
    rescue Errno::ENOENT
      nil # not a problem
    end

    private

    def run(*command, **options)
      Dir.mktmpdir do |tmp|
        out_pathname = File.join(tmp, 'out')
        err_pathname = File.join(tmp, 'err')
        options[:out] = out_pathname
        options[:err] = err_pathname

        # Note: this is not the shell builtin but rather /usr/bin/time; at least
        # on Ubuntu, the latter reports both time and max RSS (memory usage)
        # metrics, which is what we want here. Write the time output to a
        # temporary file to avoid conflicting with the child's stderr output.
        time_pathname = File.join(tmp, 'time')
        timed_command = [
          'time', '--format=%S %U %M', "--output=#{time_pathname}"
        ] + command

        Process.waitpid(Process.spawn(*timed_command, **options))

        return [
          $CHILD_STATUS.exitstatus,
          *parse_time(time_pathname),
          File.read(out_pathname),
          File.read(err_pathname)
        ]
      end
    end

    # Returns total (system plus user) CPU time in seconds, and maximum resident
    # set size (memory usage) in Kilobytes, which I think means KiB.
    def parse_time(time_pathname)
      sys, user, max_rss = File.read(time_pathname).split
      [sys.to_f + user.to_f, max_rss.to_i]
    end
  end
end
