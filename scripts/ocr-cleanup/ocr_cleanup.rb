# Menu Title: OCR Cleanup
# Needs Case: true

# Given the string output of OCR, removes any error messages from failed OCR.
def remove_ocr_error(ocr)
    # Splits the ocr output into lines.
    lines = ocr.lines 
    # Finds all possible starts of errors.
    possible_indexes = lines.each_index.select{ |i| lines[i] == "----------------------\n"}
    
    # Finds which of the possible starts of errors are actual starts of errors.
    error_indexes = []
    for lineNum in possible_indexes
        if lines[lineNum + 1] == "\n" and 
            !lines[lineNum + 2].start_with?("-------------") and # To prevent overlapping findings.
            lines[lineNum + 3] == "Failed to export native;\n" and
            lines[lineNum + 4] == "unexpected error.\n" and
            lines[lineNum + 5].start_with?("Name:") and
            lines[lineNum + 6].start_with?("GUID:") and
            lines[lineNum + 7].start_with?("File Type:")
            error_indexes << lineNum
        end
    end
    # Walks backwards through error messages and removes them.
    for lineNum in error_indexes.reverse_each # Backwards so indexes aren't invalidated.
        lines[lineNum..lineNum+7] = []
    end
    # Joins the lines again. No newlines are needed as they are already included in the lines.
    return lines.join("")
end
    