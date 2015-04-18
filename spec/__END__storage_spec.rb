require '__END__storage'

module SpecHelpers
  RunResult = Struct.new :status, :stdout, :stderr

  class RunResults
    attr_accessor :body

    def initialize
      self.body = ''
    end

    def add_run(status:, stdout:, stderr:)
      result = RunResult.new status, stdout, stderr
      results << result
    end

    def results
      @results ||= []
    end

    def stdouts
      results.map(&:stdout)
    end

    def stderrs
      results.map(&:stderr)
    end

    def statuses
      results.map(&:status)
    end

    def data_segment
      body.split("\n__END__\n").last
    end

    def assert_no_err!
      stderrs.each do |err|
        next if err.empty?
        raise RSpec::Expectations::ExpectationNotMetError,
          "Expectected no stderr, got:\n\n#{err}"
      end

      statuses.each do |status|
        next if status.success?
        raise RSpec::Expectations::ExpectationNotMetError,
          "Expected all success, got:\n\n#{status.inspect}"
      end
    end
  end


  def lib_dir
    File.expand_path '../lib', __dir__
  end

  def capture3(*command)
    read_stdout, write_stdout = IO.pipe
    read_stderr, write_stderr = IO.pipe

    pid = spawn *command,
                out: write_stdout,
                err: write_stderr

    write_stdout.close
    write_stderr.close

    Process.wait pid

    { status: $?,
      stdout: read_stdout.read,
      stderr: read_stderr.read,
    }
  ensure
    read_stdout.close unless read_stdout.closed?
    read_stderr.close unless read_stderr.closed?
  end

  require 'tempfile'
  def with_file(name, body)
    Tempfile.open name do |file|
      file.write body
      file.close
      yield file
    end
  end

  def run_file(name, body, num_times:1)
    indentation = body[/\A */]
    body        = body.gsub /^#{indentation}/, ''
    result      = RunResults.new
    with_file name, body do |file|
      num_times.times do
        run = capture3 'ruby', '-I', lib_dir, file.path
        result.add_run run
      end
      result.body = File.read file.path
    end
    result
  end
end

RSpec.configure do |config|
  config.include SpecHelpers
  config.disable_monkey_patching!
  config.fail_fast = true
end

RSpec.describe '__END__storage' do
  it 'loads data from the data segment' do
    result = run_file 'file.rb', <<-FILE
      require '__END__storage'
      p __END__storage(DATA).load
      __END__
      the data
    FILE
    result.assert_no_err!
    expect(result.stdouts).to eq [%'"the data\\n"\n']
  end

  it 'saves data to the data segment' do
    result = run_file 'file.rb', <<-FILE
      require '__END__storage'
      __END__storage(DATA).save("new data")
      __END__
      old data
    FILE
    result.assert_no_err!
    expect(result.data_segment).to eq 'new data'
  end

  it 'works with the example from the readme' do
    result = run_file 'count_runs.rb', <<-FILE, num_times: 3
      require '__END__storage'

      storage   = END__storage.new DATA
      run_count = storage.load.to_i + 1
      storage.save run_count

      puts "Run count: #{run_count}"

      __END__
      0
    FILE

    result.assert_no_err!
    expect(result.stdouts).to eq "Run count: 1\n"\
                                 "Run count: 2\n"\
                                 "Run count: 3\n"

    expect(result.body).to eq <<-FILE.gsub(/^ */, '')
      require '__END__storage'

      storage   = END__storage.new DATA
      run_count = storage.load.to_i + 1
      storage.save run_count

      puts "Run count: #{run_count}"

      __END__
      3
    FILE
  end

  it 'is a private method added to Object' do
    expect(method :__END__storage).to be
    expect { self.__END__storage }
      .to raise_error NoMethodError, /private/
  end

  it 'runs without warnings'

  it 'works when the written segment is shorter than the existing data segment'
  it 'works when the written segment is longer than the existing data segment'

  # File.open(name, "r+:UTF-8")
  it 'works when there are UTF8 characters in the body'
  it 'works when there are UTF8 characters in the DATA segment'
end
