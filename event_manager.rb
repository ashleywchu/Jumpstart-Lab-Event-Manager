require "csv"
require "sunlight/congress"
require "erb"
require "date"

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"
puts "EventManager Initialized!"

def clean_zipcode(zipcode)
	zipcode.to_s.rjust(5, "0")[0..4]
end

def legislators_by_zipcode(zipcode)
	legislators = Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
	Dir.mkdir("output") unless Dir.exists? "output"

	filename = "output/thanks_#{id}.html"

	File.open(filename, "w") do |file|
		file.puts form_letter
	end
end

def clean_phone_number(phone_number)
	number = phone_number.to_s.gsub(/\D/, "")
	if number.length == 10
		number
	elsif (number.length == 11) && (number[0] == "1")
		number = number[1..-1]
	else
		number = "0000000000"
	end
	return number[0..2] + "-" + number[3..5] + "-" + number[6..9]
end

def peak_hours(hour_hash)
	most_popular = hour_hash.select do |hour, people|
		people == hour_hash.values.max
	end

	time = most_popular.keys.map do |hour|
			if hour < 12
				hour.to_s + "AM"
			else
				(hour - 12).to_s + "PM"
			end
	end

	return time.join(", ")
end

def peak_days(day_hash)
	days_of_week = %w{Sunday Monday Tuesday Wednesday Thursday Friday Saturday}
	most_popular = day_hash.select do |day, people|
		people == day_hash.values.max
	end
	return most_popular.keys.map { |day_in_num| days_of_week[day_in_num]}.join(", ")
end

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

hour_hash = Hash.new(0)
day_hash = Hash.new(0)

contents.each do |row|
	id = row[0]
	name = row[:first_name]
	
	zipcode = clean_zipcode(row[:zipcode])

	legislators = legislators_by_zipcode(zipcode)

	phone_number = clean_phone_number(row[:homephone])

	date_time = DateTime.strptime(row[:regdate], "%m/%d/%y %H:%M")
	hour_hash[date_time.hour] += 1
	day_hash[date_time.wday] += 1

	form_letter = erb_template.result(binding)

	save_thank_you_letters(id, form_letter)
	
end
puts "Peak registration hour: #{peak_hours(hour_hash)}"
puts "Peak registration day of the week: #{peak_days(day_hash)}"
