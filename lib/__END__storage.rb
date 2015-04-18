def __END__storage(data_segment=:default)
  if data_segment == :default
    END_storage.default ||= __END__storage DATA
  else
    END_storage.from_segment(data_segment)
  end
end

class END_storage
  class << self
    attr_accessor :default
    def from_segment(data_segment)
      new data_segment.path, data_segment.pos
    end
  end

  def initialize(path, offset)
    self.path   = path
    self.offset = offset
  end

  def load
    open_segment { |ds| ds.read }
  end

  def save(data)
    open_segment do |ds|
      ds.puts data
      ds.truncate ds.pos
    end
  end

  def update
    save yield load
  end

  protected

  attr_accessor :path, :offset

  def open_segment
    File.open path, 'r+' do |file|
      file.seek offset
      yield file
    end
  end
end
