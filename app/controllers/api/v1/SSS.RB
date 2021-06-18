get_sheet.each_with_index do |data, i|
  check = data.first(7).detect { |x| x === "" }
  if check === ""
    check_blank = check_blank + "line #{i + 1} not blank |  "
    count_col_blank = count_col_blank + 1
    break
  else
    count_col_blank = 0
  end

  if count_col_blank === 2
    check_blank = check_blank + ".... | please check bug in line  #{count_rows}"
    return check_blank
    break
  end
end
