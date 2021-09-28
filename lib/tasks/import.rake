desc 'clear solr of records'
task :clear => [:environment] do
  SolrService.remove_all
end

desc 'import all records via oai-pmh'
task :import, [:limit, :set, :progress] => [:environment] do |t, args|
  puts "import", args
  args ||= {}
  progress = args[:progress] || true
  set = args[:set] || 'arce_1'
  limit = args[:limit] || 20000000
  limit = limit.to_i
  ArceItem.import(limit: limit, set: set)
end
