require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'active_support/all'

DataMapper::setup(:default,"sqlite3://#{Dir.pwd}/tasks.db")

DataMapper::Property::String.length(255)

class Task
  include DataMapper::Resource
  property :id,Serial
  property :description, String
  property :done, Boolean
  property :created_at, DateTime
  property :dotted, Boolean
  property :deferred_until, DateTime, :default=>Time.now
end

# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# Automatically create the post table
Task.auto_upgrade!
#Only use following command if there are existing records which don't have the
#default value;
#Task.update(:deferred_until=>Time.now)
#Use following command instead for now, to empty the DB:
#Task.auto_migrate!

get '/' do
  # get all the tasks
  @tasks = Task.all(:deferred_until.lt=>Time.now, :order => [ :id.asc ])
  erb :index
end

post '/task/:id' do
  @task=Task.get(params[:id])
  params.each do |key,value|
    if @task.attributes.key?(key.to_sym)
      #value=true if value=="true"
      #value=false if value=="false"
      @task.update(key => value)
    end
  end
  redirect '/'
end

post '/task' do
  @description=params[:description]
  Task.create(
    :description => @description,
    :done => false,
    :created_at => Time.now,
    :dotted => false
  )
  redirect '/'
end

post '/job/cleardots' do
  Task.each() do |task|
    task.dotted=false
    task.save
  end
  redirect '/'
end

post '/job/clearpostponements' do
  Task.each() do |task|
    task.deferred_until=Time.now
    task.save
  end
  redirect '/'
end

delete '/task/:id' do
  @task=Task.get(params[:id])
  @task.done=true
  @task.save
  redirect '/'
end

put '/task/:id' do
  puts params[:action]
  if (params[:action]=='donefornow')
    @task=Task.get(params[:id])
    @task.dotted=false
    attributes=@task.attributes
    attributes.delete(:id)
    @task.destroy
    Task.create(attributes)
  elsif (params[:action]=='defertomorrow')
    puts 'deferring'
    puts params[:id]
    @task=Task.get(params[:id])
    # If it's before 4am, defer until 4am same day, otherwise 4am next day
    t=Time.now
    @task.deferred_until=t+4.hours-t.hour.hours-t.min.minutes-t.sec
    if t.hour>=4
      @task.deferred_until+=1.day
    end
    @task.dotted=false
    attributes=@task.attributes
    attributes.delete(:id)
    @task.destroy
    Task.create(attributes)
    puts @task.deferred_until
  end
  redirect '/'
end
