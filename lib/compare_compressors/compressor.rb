# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

module CompareCompressors
  #
  # Base class for compressors. Subclasses provide compressor-specific
  # configuration and logic.
  #
  class Compressor
    #
    # Run the compressor at the given level on the given target and measure
    # its running time and memory usage.
    #
    # @param [String] target original pathname of the target (read only)
    # @param [String] work_target temporary path of the target (read/write)
    # @param [Numeric] level the compression level
    # @return [Result]
    #
    def evaluate(target, work_target, level)
      compression_times = time(compression_command(work_target, level))
      size = output_size(work_target)
      remove_if_exists(work_target)

      decompression_times = time(decompression_command(work_target))
      remove_if_exists(output_name(work_target))

      Result.new(
        target, name, level, *compression_times, size, *decompression_times
      )
    end

    #
    # @abstract
    # @return [String] name that can be a ruby symbol
    #
    def name
      raise NotImplementedError
    end

    #
    # @abstract
    # @return [String] extension added to the compressed file
    #
    def extension
      raise NotImplementedError
    end

    #
    # @abstract
    # @return [Array<Integer>] the levels supported by the compressor
    #
    def levels
      raise NotImplementedError
    end

    #
    # @abstract
    # @return [String?] version string (for information only)
    #
    def version
      nil
    end

    #
    # @return [String] display name (need not be safe to intern as a symbol)
    #
    def display_name
      name
    end

    #
    # @abstract
    # @return [Array<String>] command to run the compressor
    #
    def compression_command
      raise NotImplementedError
    end

    #
    # @abstract
    # @return [Array<String>] command to run the compressor in decompress mode
    #
    def decompression_command
      raise NotImplementedError
    end

    private

    def output_size(target)
      File.stat(output_name(target)).size
    end

    def output_name(target)
      "#{target}.#{extension}"
    end

    def time(command)
      status, times, out, err = run(*command)
      return times if status.zero?
      raise format(
        "%s: %s exited with %d:\n%s\n%s",
        name, command.join(' '), status, out, err
      )
    end

    def run(*command, **options)
      Dir.mktmpdir do |tmp|
        out_pathname = File.join(tmp, 'out')
        err_pathname = File.join(tmp, 'err')
        options[:out] = out_pathname
        options[:err] = err_pathname
        options[:in] = '/dev/null'

        # Note: this is not the shell builtin but rather /usr/bin/time; at least
        # on Ubuntu, the latter reports both time and max RSS (memory usage)
        # metrics, which is what we want here. Write the time output to a
        # temporary file to avoid conflicting with the child's stderr output.
        time_pathname = File.join(tmp, 'time')
        timed_command = [
          'time', '--format=%e %S %U %M', "--output=#{time_pathname}"
        ] + command

        Process.waitpid(Process.spawn(*timed_command, **options))

        [
          $CHILD_STATUS.exitstatus,
          parse_time(time_pathname),
          File.read(out_pathname),
          File.read(err_pathname)
        ]
      end
    end

    # Returns elapsed time in seconds, total (system plus user) CPU time in
    # seconds, and maximum resident set size (memory usage) in Kilobytes, which
    # I think means KiB.
    def parse_time(time_pathname)
      elapsed, sys, user, max_rss = File.read(time_pathname).split
      [elapsed.to_f, sys.to_f + user.to_f, max_rss.to_i]
    end

    def remove_if_exists(pathname)
      FileUtils.rm pathname
    rescue Errno::ENOENT
      nil # not a problem
    end
  end
end
