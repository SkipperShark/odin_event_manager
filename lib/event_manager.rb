require "csv"
require "google/apis/civicinfo_v2"
require "colorize"
require "erb"

puts "Event Manager Initialized!"

filename = "event_attendees.csv"
api_key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

# def legislator_names_by_zipcode(zipcode)
def legislators_by_zipcode(zipcode)
  begin
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"
    response = civic_info.representative_info_by_address(
      address: zipcode,
      levels: "country",
      roles: %w[legislatorUpperBody legislatorLowerBody]
    )
    # response.officials.map(&:name).join(", ")
    response.officials
  rescue StandardError
    "Invalid response received from API"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist? "output"

  filename = "output/thanks_#{id}.html"
  File.open(filename, "w") do |file|
    file.write form_letter
  end
end

def clean_phone_number(phone_number)
  digits = Array(0..9).map(&:to_s)
  is_bad_number = false

  phone_number_digits = phone_number.chars.filter { |char| digits.include? char }
  num_digits = phone_number_digits.size

  if num_digits < 10 || num_digits > 11
    is_bad_number = true
  elsif num_digits == 11
    if phone_number_digits.first == "1"
      phone_number_digits = phone_number_digits.slice(1, num_digits)
    else
      is_bad_number = true
    end
  end

  is_bad_number = true if phone_number_digits.size < 10

  if is_bad_number
    "Bad"
  else
    phone_number_digits.join
  end
end

contents = CSV.open(
  filename,
  headers: true,
  header_converters: :symbol
)

template_letter = File.read("form_letter.erb")

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  reg_datetime = row[:regdate]

  zipcode = clean_zipcode row[:zipcode]
  phone_number = clean_phone_number row[:homephone]
  legislators = legislators_by_zipcode(zipcode)

  rhtml = ERB.new(template_letter)
  form_letter = rhtml.result(binding)

  puts "name : #{name}, raw regdatetime : #{row[:regdate]}"
  # puts "#{id}, #{legislators}, #{form_letter}"
  # puts "name : #{name}, phone number : #{phone_number}"

  # save_thank_you_letter(id, form_letter)
  # personal_letter = template_letter.gsub("FIRST_NAME", name)
  # personal_letter.gsub!("LEGISLATORS", legislator_names)
  # puts personal_letter
  #
end
