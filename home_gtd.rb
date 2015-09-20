require 'rubygems'
require 'sinatra'
require 'data_mapper'

DataMapper::setup(:default,"sqlite3://#{Dir.pwd}/tasks.db")

DataMapper::Property::String.length(255)

class Task
  include DataMapper::Resource
  property :id,Serial
  property :description, String
  property :done, Boolean
  property :created_at, DateTime
  property :dotted, Boolean
end

# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# Automatically create the post table
Task.auto_upgrade!
#Use following command instead for now, to empty the DB
#Task.auto_migrate!

get '/' do
  # get all the tasks
  @tasks = Task.all(:order => [ :id.asc ])
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

delete '/task/:id' do
  @task=Task.get(params[:id])
  @task.done=true
  @task.save
  redirect '/'
end

put '/task/:id' do
  if (params[:action]=='donefornow')
    @task=Task.get(params[:id])
    @task.dotted=false
    attributes=@task.attributes
    attributes.delete(:id)
    @task.destroy
    Task.create(attributes)
  end
  redirect '/'
end
