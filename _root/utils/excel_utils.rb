module ExcelUtils
  extend self

  def string_num?(string)
    Float(string) != nil rescue false
  end

  def row(style, data)
    "\
   <Row ss:AutoFitHeight=\"0\">
    #{data.map{|datum| "<Cell ss:StyleID=\"s#{style.to_s}\"><Data ss:Type=\"#{string_num?(datum) ? 'Number' : 'String'}\">#{datum.to_s}</Data></Cell>"}.join("\n  ")}
   </Row>"
  end
end
  