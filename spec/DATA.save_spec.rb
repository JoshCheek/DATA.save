require 'DATA.save'

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
  def with_file(name, body, closed: false)
    Tempfile.open name do |file|
      file.write body
      file.rewind
      file.close if closed
      yield file
    end
  end

  def run_file(name, body, num_times:1)
    indentation = body[/\A */]
    body        = body.gsub /^#{indentation}/, ''
    result      = RunResults.new
    with_file name, body, closed: true do |file|
      num_times.times do
        run = capture3 'ruby', '-w', '-I', lib_dir, file.path
        result.add_run run
      end
      result.body = File.read file.path
    end
    result
  end

  def segment_for(obj)
    body_after(body: '') { |storage| storage.save obj }
  end

  def body_after(body:, pos:0)
    with_file 'body_after.rb', body do |file|
      file.seek pos
      yield DataSave.for(file), file
      File.read file.path
    end
  end
end

RSpec.configure do |config|
  config.include SpecHelpers
  config.disable_monkey_patching!
  config.fail_fast = true
end

RSpec.describe 'DATA.save' do
  it 'loads data from the data segment' do
    result = run_file 'file.rb', <<-FILE
      require 'DATA.save'
      p DATA.load
      __END__
      the data
    FILE
    result.assert_no_err!
    expect(result.stdouts).to eq [%'"the data\\n"\n']
  end

  it 'saves data to the data segment' do
    result = run_file 'file.rb', <<-FILE
      require 'DATA.save'
      DATA.save("new data")
      __END__
      old data
    FILE
    result.assert_no_err!
    expect(result.data_segment).to eq "new data\n"
  end

  it 'works with the example from the readme' do
    result = run_file 'count_runs.rb', <<-FILE, num_times: 3
      require 'DATA.save'

      run_count = DATA.load.to_i
      run_count += 1
      DATA.save run_count

      puts "Run count: \#{run_count}"

      __END__
      0
    FILE

    result.assert_no_err!
    expect(result.stdouts).to eq [
      "Run count: 1\n",
      "Run count: 2\n",
      "Run count: 3\n",
    ]

    expect(result.body).to eq <<-FILE.gsub(/^ */, '')
      require 'DATA.save'

      run_count = DATA.load.to_i
      run_count += 1
      DATA.save run_count

      puts "Run count: \#{run_count}"

      __END__
      3
    FILE
  end


  describe '.for' do
    it 'creates a new instance every time, when a data segment is given' do
      with_file 'f.rb', 'zomg', closed: true do |file|
        segment1 = File.open file
        segment2 = File.open file
        segment2.getc

        storage1 = DataSave.for segment1
        storage2 = DataSave.for segment2

        expect(storage1.load).to eq 'zomg'
        expect(storage2.load).to eq 'omg'
      end
    end
  end


  describe '.on' do
    it 'is places the methods on the object' do
      with_file 'f.rb', '-----' do |file|
        file.seek 1
        DataSave.on file
        file.save 'a'
        expect(File.read file).to eq "-a\n"
        expect(file.load).to eq "a\n"
        file.update { |loaded| expect(loaded).to eq "a\n"; "C" }
        expect(File.read file).to eq "-C\n"
      end
    end
  end


  it 'calls #to_s when writing' do
    o = Object.new
    def o.inspect() "inspected\n" end
    def o.to_s()    "to_s'd\n"    end
    expect(segment_for o).to eq "to_s'd\n"
  end


  it 'appends a newline if the data doesn\'t have one (b/c this is a file)' do
    expect(segment_for "a\n").to eq "a\n"
    expect(segment_for "a"  ).to eq "a\n"
  end


  it 'works when the written segment is shorter than the existing data segment' do
    body = body_after(body: 'abcdefg', pos: 1) { |storage| storage.save "X\n" }
    expect(body).to eq "aX\n"
  end


  it 'works when the written segment is longer than the existing data segment' do
    body = body_after(body: 'ab', pos: 1) { |storage| storage.save "X\n" }
    expect(body).to eq "aX\n"
  end


  it 'works when there are UTF8 characters in the body' do
    body = body_after body: 'Ω1', pos: 'Ω'.bytesize do |storage|
      storage.save "X\n"
    end
    expect(body).to eq "ΩX\n"
  end


  it 'works when there are UTF8 characters in the old DATA segment' do
    body = body_after body: '1Ω', pos: 1 do |storage|
      storage.save "X\n"
    end
    expect(body).to eq "1X\n"
  end


  it 'works when there are UTF8 characters in the new DATA segment' do
    body = body_after body: '12', pos: 1 do |storage|
      storage.save "Ω\n"
    end
    expect(body).to eq "1Ω\n"
  end


  it 'can be reinvoked multiple times' do
    body = body_after body: "-0\n", pos: 1 do |storage, file|
      expect(storage.load).to eq "0\n"

      storage.save 1
      expect(File.read file).to eq "-1\n"
      expect(storage.load).to eq "1\n"

      storage.save 2
      expect(File.read file).to eq "-2\n"
      expect(storage.load).to eq "2\n"
    end
    expect(body).to eq "-2\n"
  end


  it 'reloads the data every time' do
    body = body_after body: "-0\n", pos: 1 do |storage, file|
      expect(storage.load).to eq "0\n"
      File.write file, 'zomg'
      expect(storage.load).to eq 'omg'
    end
    expect(body).to eq "zomg"
  end

  it 'allows for upddating, which gives the current value to a block, and saves whatever comes back' do
    body = body_after body: "-0\n", pos: 1 do |storage|
      storage.update do |current|
        expect(current).to eq "0\n"
        100
      end
    end
    expect(body).to eq "-100\n"
  end
end
