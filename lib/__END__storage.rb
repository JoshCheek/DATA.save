def __END__storage(data_segment)
  END_storage.new data_segment
end

class END_storage
  def initialize(data_segment)
    self.data_segment = data_segment.dup
    self.position     = data_segment.pos
  end

  def load
    open_segment { |ds| ds.read }
  end

  def save(data)
    open_segment do |ds|
      ds.print data
      ds.truncate ds.pos
    end
  end

  private

  attr_accessor :data_segment, :position

  def open_segment
    File.open data_segment, 'r+' do |file|
      file.seek position
      yield file
    end
  end
end
