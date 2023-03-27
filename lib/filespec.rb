# frozen_string_literal: true

require 'aws-sdk-s3'
require 'dotenv'
require 'pry'
# require 'net/smtp'

# Load Env file
Dotenv.load

# Create directory tmp
FileUtils.mkdir "tmp"

client = Aws::S3::Client.new(
  access_key_id: ENV['DO_SPACES_KEY'],
  secret_access_key: ENV['DO_SPACES_SECRET'],
  endpoint: ENV['DO_SPACES_END_POINT'],
  force_path_style: false,
  region: ENV['DO_SPACES_REGION']
)
resource = Aws::S3::Resource.new(client: client)
bucket = resource.bucket(ENV['DO_SPACES_BUCKET'])

folder = ENV['DO_SPACES_FOLDER']
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
  filename_orders = "pedidos_#{Time.now.strftime("%d%m%Y")}.xlsx"
  filename_products = "pedidos_produtos#{Time.now.strftime("%d%m%Y")}.xlsx"
  # extract zip file
  system("tar -xvzf #{local_path}/#{file}")

  # Access project rails and reset db
  system("cd #{project_path}; rails db:drop db:create")
  # Execute backup dump to local db
  system("psql -h localhost -p 5432 -U rafaelnaves -d invoice_web_development < db.sql")
  # Access project rails and exec migrate and download sheet
  system("cd #{project_path}; rails db:migrate db:download_orders")

  # Copy files to local project folder tmp
  FileUtils.cp("#{project_path}/#{filename_orders}", "./tmp/#{filename_orders}")
  FileUtils.cp("#{project_path}/#{filename_products}", "./tmp/#{filename_products}")

end