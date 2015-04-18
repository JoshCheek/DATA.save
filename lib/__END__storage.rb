class END_storage
  # File.open DATA, 'r+' do |file|
  #   file.seek DATA.pos
  #   file.puts build.as_json.to_json
  # end

  def initialize(data_segment)
    self.data_segment = data_segment.dup
    self.position     = data_segment.pos
  end

  def load
    ds = data_segment.dup
    ds.seek position
    ds.read
  end

  private

  attr_accessor :data_segment, :position
end

def __END__storage(data_segment)
  END_storage.new data_segment
end
