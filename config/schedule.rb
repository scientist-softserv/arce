# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

env 'BASH_ENV', '/container.env'

every 12.hours do
  rake 'import'
end

every 1.day, at: ['12:30 am', '12:30 pm'] do
  rake 'import[10000,tom_1]'
end

every 1.day, at: ['1:00 am', '1:00 pm'] do
  rake 'import[10000,atp_1]'
end

# Delete blacklight saved searches
every :day, at: '11:55pm' do
  rake 'blacklight:delete_old_searches[1]'
end
