module TagWeirdCharacters
    extend self

    def run(nuix_case, utilities, settings_hash, progress_handler)
        root_directory = settings_hash[:root_directory]
        require File.join(root_directory,'utils','timer')
        require File.join(root_directory,'inapp-scripts','tag-weird-characters','tag_weird_characters')

        timer = Timing::Timer.new
        timer.start('total')

        scoping_query = settings_hash.key?(:scoping_query) ? settings_hash[:scoping_query] : ''

        accepted_character_codes = settings_hash.key?(:accepted_character_codes) ? settings_hash[:accepted_character_codes].split(',').map(&:to_i) : []
        tag_name = settings_hash[:tag_name]

        items = nuix_case.search(scoping_query)
        script_finished_message = TagWeirdCharacters::tag_weird_characters(items, progress_handler, timer, utilities, accepted_character_codes, tag_name)

        progress_handler.log_message("Script finished. #{script_finished_message}")
    
        timer.stop('total')
    end
end
