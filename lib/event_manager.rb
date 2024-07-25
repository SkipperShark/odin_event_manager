require "csv"
require "google/apis/civicinfo_v2"
require "colorize"

puts "Event Manager Initialized!"

filename = "event_attendees.csv"
api_key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def google_civicinfo_api_connection(api_key)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"
  civic_info
end

def legislator_names_by_zipcode(civic_info_api, zipcode)
  begin
    response = civic_info_api.representative_info_by_address(
      address: zipcode,
      levels: "country",
      roles: %w[legislatorUpperBody legislatorLowerBody]
    )
    response.officials.map(&:name).join(", ")
  rescue StandardError
    "Invalid response received from API"
  end
end

contents = CSV.open(
  filename,
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode row[:zipcode]
  civic_info_api = google_civicinfo_api_connection(api_key)
  legislator_names = legislator_names_by_zipcode(civic_info_api, zipcode)
  puts "#{name} - #{zipcode} - #{legislator_names} "
end
