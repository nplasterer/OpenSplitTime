module SplitTimesHelper

  def composite_time(split_row)
    time_array = []
    (0...split_row.times_from_start.count).each do |i|
      time = split_row.times_from_start[i]
      data_status = split_row.time_data_statuses[i]
      if time
        element = case data_status
                    when 'bad'
                      '[*' + time_format_xxhyym(time) + '*]'
                    when 'questionable'
                      '[' + time_format_xxhyym(time) + ']'
                    else
                      time_format_xxhyym(time)
                  end
      else
        element = '--:--:--'
      end
      time_array << element
    end
    time_array.join(' / ')
  end

  def composite_time_zzs(split_row)
    time_array = []
    (0...split_row.times_from_start.count).each do |i|
      time = split_row.times_from_start[i]
      data_status = split_row.time_data_statuses[i]
      if time
        element = case data_status
                    when 'bad'
                      '[*' + time_format_xxhyymzzs(time) + '*]'
                    when 'questionable'
                      '[' + time_format_xxhyymzzs(time) + ']'
                    else
                      time_format_xxhyymzzs(time)
                  end
      else
        element = '--:--:--'
      end
      time_array << element
    end
    time_array.join(' / ')
  end

end