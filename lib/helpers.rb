module Helpers
  def can_check_in_from_coordinate?(lat_0, lng_0, lat_1, lng_1)
      haversine_distance_in_meters_between_coordinates(lat_0, lng_0, lat_1, lng_1) < 1000
    end

    def distance_and_bearing_from_between_coordinates(lat_0, lng_0, lat_1, lng_1)
      distance  = case meters = haversine_distance_in_meters_between_coordinates(lat_0, lng_0, lat_1, lng_1)
                  when 0..50    then return ""
                  when 50..999  then sprintf("%d meters", meters)
                  else sprintf("%.1d km", meters / 1000.0)
                  end
      direction = case degrees = bearing_in_degrees_between_coordinates(lat_0, lng_0, lat_1, lng_1)
                    when 22.5..67.5   then "Northeast"
                    when 67.5..112.5  then "East"
                    when 1125..157.5  then "Southeast"
                    when 157.5..202.5 then "South"
                    when 202.5..247.5 then "Southwest"
                    when 247.5..292.5 then "West"
                    when 292.5..337.5 then "Northwest"
                    else "North"
                  end

      "#{distance} #{direction}"
    end

    def haversine_distance_in_meters_between_coordinates(lat_0, lng_0, lat_1, lng_1)
      a0 = lat_0 * (Math::PI / 180)
      b0 = lng_0 * (Math::PI / 180)
      a1 = lat_1 * (Math::PI / 180)
      b1 = lng_1 * (Math::PI / 180)

      r_e = 6378.135 # radius of the earth in kilometers (at the equator)
      # note that the earth is not a perfect sphere, r is also as small as
      r_p = 6356.75 #km at the poles

      # find the earth's radius at the average latitude between the two locations
      theta = (lat_0 + lat_1) / 2

      r = Math.sqrt(((r_e**2 * Math.cos(theta))**2 + (r_p**2 * Math.cos(theta))**2) /
                    ((r_e * Math.cos(theta))**2 + (r_p * Math.cos(theta))**2))

      # Do the calculation with radians as units
      km = r * Math.acos(Math.cos(a0)*Math.cos(b0)*Math.cos(a1)*Math.cos(b1) +
                 Math.cos(a0)*Math.sin(b0)*Math.cos(a1)*Math.sin(b1) + Math.sin(a0)*Math.sin(a1))

      return 1000 * km
    end

    def bearing_in_degrees_between_coordinates(lat_0, lng_0, lat_1, lng_1)
      a0 = lat_0 * (Math::PI / 180)
      b0 = lng_0 * (Math::PI / 180)
      a1 = lat_1 * (Math::PI / 180)
      b1 = lng_1 * (Math::PI / 180)

	    dLon = b1 - b0
	    y = Math.sin(dLon) * Math.cos(a1)
	    x = Math.cos(a0) * Math.sin(a1) - Math.sin(a0) * Math.cos(a1) * Math.cos(dLon)

	    bearing = Math.atan2(y, x) + (2 * Math::PI)

	    return (bearing / (Math::PI / 180)) % 360
    end
  
  # Returns relative time in words referencing the given date
  # relative_time_ago(Time.now) => 'about a minute ago'
  def relative_time_ago(from_time)
    distance_in_minutes = (((Time.now - from_time.to_time).abs)/60).round
    case distance_in_minutes
      when 0..1 then 'less than a minute ago'
      when 2..44 then "#{distance_in_minutes} minutes ago"
      when 45..89 then 'about 1 hour ago'
      when 90..1439 then "#{(distance_in_minutes.to_f / 60.0).round} hours ago"
      when 1440..2879 then '1 day ago'
      when 2880..43199 then "#{(distance_in_minutes / 1440).round} days ago"
      when 43200..86399 then 'about 1 month ago'
      when 86400..525599 then "#{(distance_in_minutes / 43200).round} months ago"
      when 525600..1051199 then 'about 1 year ago'
      else "over #{(distance_in_minutes / 525600).round} years ago"
    end
  end
end

class DateTime
  def to_time
    ::Time.utc(year, month, day, hour, min, sec)
  end
end