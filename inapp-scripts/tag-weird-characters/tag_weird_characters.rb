module TagWeirdCharacters
    extend self

    def weird_character?(char_code, accepted_char_codes)
        return char_code > 127 && !accepted_char_codes.include?(char_code)
    end

    def tag_weird_characters (items, progress_handler, timer, utilities, accepted_char_codes, tag_name)
        progress_handler.set_main_status_and_log_it('Searching for items with weird characters...')
        progress_handler.set_main_progress(0,items.size)
        timer.start("find_items")
        # Find items with weird characters.
        tag_items = items.select do |item|
            progress_handler.increment_main_progress
            item.name.codepoints.any?{ |codepoint| weird_character?(codepoint, accepted_char_codes) }
        end
        timer.stop("find_items")
        
        bulk_annotater = utilities.get_bulk_annotater
        
        progress_handler.set_main_status_and_log_it('Tagging items with weird characters...')
        timer.start("tag_items")
        bulk_annotater.add_tag(tag_name, tag_items)
        timer.stop("tag_items")
        
        
        "Script finished. Found #{tag_items.size.to_s} items with weird characters in name."
    end
end