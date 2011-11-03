group :test do
  guard 'minitest' do
    watch('echo_service.rb') { "test" }
    watch(%r|^test/test_(.*)\.rb|)
    watch(%r|^lib/(.*)([^/]+)\.rb|)     { |m| "test/#{m[1]}test_#{m[2]}.rb" }
    watch(%r|^test/test_helper\.rb|)    { "test" }
  end
end

group :run do
  guard 'process', :name => 'EchoService', :command => 'ruby echo_service.rb', :stop_signal => "KILL"  do
    watch('echo_service.rb')
    watch('Gemfile.lock')
  end
end
