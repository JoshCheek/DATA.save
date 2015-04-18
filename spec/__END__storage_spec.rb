require '__END__storage'

RSpec.describe '__END__storage' do
  it 'loads data from the data segment' do
    result = run_file 'file.rb', <<-FILE
      require '__END__storage'
      p __END__storage(DATA).load
      __END__
      the data
    FILE
    expect(result.stdout).to eq '"the data\n"'
  end

  it 'saves data to the data segment' do
    result = run_file 'file.rb', <<-FILE
      require '__END__storage'
      __END__storage(DATA).save("new data")
      __END__
      old data
    FILE
    data = result.body.split("\n__END__\n").last
    expect(data).to eq 'new data'
  end
end
