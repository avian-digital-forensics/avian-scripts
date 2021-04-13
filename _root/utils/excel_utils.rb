# A number of utility methods for working with spreadsheets in the XML Spreadsheet 2003 format.
module ExcelUtils
  extend self

  # Returns true if the argument can be cast to a float.
  #
  # Params:
  # +x+:: The argument to check for numericness.
  def numeric?(x)
    Float(x) != nil rescue false
  end

  # Returns a string representing a spreadsheet row in the correct format.
  # Remember to update the 'ExpandedColumnCount' and 'ExpandedRowCount' attributes if necessary.
  #
  # Params:
  # +style+:: The style of all cells in the row using a StyleID defined earlier in the document.
  # +data+:: An array with the values for each cell in the row starting from the left.
  def generate_row(style, data)
    "\
   <Row ss:AutoFitHeight=\"0\">
    #{data.map{|datum| "<Cell ss:StyleID=\"s#{style.to_s}\"><Data ss:Type=\"#{numeric?(datum) ? 'Number' : 'String'}\">#{datum.to_s}</Data></Cell>"}.join("\n  ")}
   </Row>"
  end
end
  