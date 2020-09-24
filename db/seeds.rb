# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

##################################################################
##### SEED FILE GETS RUN AUTOMATICALLY IN STAGING/PRODUCTION #####
##################################################################

# seed the database with users who can access the admin page
[
  { email: 'rob@notch8.com', password: 'testing123'},
  { email: 'akostopoulos@arce.org', password: 'arceadmin2020' },
  { email: 'nstanke@arce.org', password: 'arceadmin2020' },
  { email: 'tlitecky@arce.org', password: 'arceadmin2020' }
].each do |set|
  next if User.where(email: set[:email]).first
  user = User.create!(email: set[:email], password: set[:password])
end

