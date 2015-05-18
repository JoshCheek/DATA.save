class DataSave
  VERSION = '0.0.1'

  def self.for(data_segment)
    new data_segment.path, data_segment.pos
  end

  def self.on(data_segment)
    store = DataSave.for data_segment
    data_segment.define_singleton_method(:load) { store.load }
    data_segment.define_singleton_method(:save) { |data| store.save data }
    data_segment.define_singleton_method(:update) { |&block| store.update(&block) }
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

DataSave.on DATA if defined? DATA
