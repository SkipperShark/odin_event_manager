require "csv"
require "google/apis/civicinfo_v2"
require "colorize"
require "erb"
require "time"

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

# tracks what hours of the day has the most registration
class HotRegHourTracker
  attr_accessor :hot_hours, :regs_by_hour

  def initialize
    @regs_by_hour = {}
    @hot_hours = []
  end

  def add_registration(registration_datetime)
    datetime = Time.strptime(registration_datetime, "%M/%d/%y %H:%M")
    hour = datetime.strftime("%H")

    increment_regs_by_hour hour

    max_num_regs = regs_by_hour.values.max
    self.hot_hours = regs_by_hour.keys.select { |ele| regs_by_hour[ele] == max_num_regs }
  end

  def increment_regs_by_hour(hour)
    if regs_by_hour[hour].nil?
      regs_by_hour[hour] = 1
    else
      regs_by_hour[hour] += 1
    end
  end
end

# tracks what weekday of the day has the most registration
class HotRegDayTracker
  attr_accessor :hot_days, :regs_by_day

  def initialize
    @regs_by_day = {}
    @hot_days = []
  end

  def add_registration(registration_datetime)
    datetime = Time.strptime(registration_datetime, "%M/%d/%y %H:%M")
    day = datetime.strftime("%A")
    # puts "day : #{day}"

    increment_regs_by_day day

    max_num_regs = regs_by_day.values.max
    self.hot_days = regs_by_day.keys.select { |ele| regs_by_day[ele] == max_num_regs }
  end

  def increment_regs_by_day(day)
    if regs_by_day[day].nil?
      regs_by_day[day] = 1
    else
      regs_by_day[day] += 1
    end
  end
end

contents = CSV.open(
  filename,
  headers: true,
  header_converters: :symbol
)

template_letter = File.read("form_letter.erb")
hot_reg_hour_tracker = HotRegHourTracker.new
hot_reg_day_tracker = HotRegDayTracker.new

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

  hot_reg_hour_tracker.add_registration(reg_datetime)
  hot_reg_day_tracker.add_registration(reg_datetime)

  hot_hours = hot_reg_hour_tracker.hot_hours
  hot_days = hot_reg_day_tracker.hot_days
  puts "reg_hours : #{hot_reg_hour_tracker.regs_by_hour}"
  puts "hot_hours : #{hot_hours}"
  puts "reg_days : #{hot_reg_day_tracker.regs_by_day}"
  puts "hot_days : #{hot_days}"
  puts "---------------------"
  # puts datetime
  # puts datetime.class

  # puts "#{id}, #{legislators}, #{form_letter}"
  # puts "name : #{name}, phone number : #{phone_number}"

  # save_thank_you_letter(id, form_letter)
  # personal_letter = template_letter.gsub("FIRST_NAME", name)
  # personal_letter.gsub!("LEGISLATORS", legislator_names)
  # puts personal_letter
  #
end
