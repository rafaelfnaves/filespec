# frozen_string_literal: true

require 'aws-sdk-s3'
require 'dotenv'
require 'pry'
# require 'net/smtp'

Dotenv.load

client = Aws::S3::Client.new(
  access_key_id: ENV['DO_SPACES_KEY'],
  secret_access_key: ENV['DO_SPACES_SECRET'],
  endpoint: ENV['DO_SPACES_END_POINT'],
  force_path_style: false,
  region: ENV['DO_SPACES_REGION']
)
resource = Aws::S3::Resource.new(client: client)
bucket = resource.bucket(ENV['DO_SPACES_BUCKET'])

folder = "invoice_web"
date = Time.now.strftime("%Y-%m-%d")
prefix = "#{folder}/#{date}"
file = ""

begin
  bucket.objects(prefix: prefix).each do |obj|
    file = obj.key.gsub("#{folder}/", "")
    client.get_object(
      bucket: ENV['DO_SPACES_BUCKET'],
      key: obj.key,
      response_target: "./tmp/#{file}"
    )
  end
rescue Exception => error
  puts "Error on sync spaces => #{error.message}"
end

unless file.nil?
  local_path = Dir.pwd + "/tmp"
  project_path = ENV['PROJECT_PATH']
  
  # extract zip file
  system("tar -xvzf #{local_path}/#{file}")

  # Access project rails and reset db
  system("cd #{project_path}; rails db:drop db:create")
  # Execute backup dump to local db
  system("psql -h localhost -p 5432 -U rafaelnaves -d invoice_web_development < db.sql")
  # Access project rails and exec migrate and download sheet
  system("cd #{project_path}; rails db:migrate db:download_orders")

end