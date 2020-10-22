script_directory = File.dirname(__FILE__)
require File.join(script_directory,'..','setup.nuixscript','get_main_directory')

main_directory = get_main_directory(false)

unless main_directory
    puts('Script cancelled because no main directory could be found.')
    return
end

require File.join(main_directory, 'utils', 'utils')

require File.join(main_directory, 'utils', 'settings_utils')

module ExportPrintedImages
    extend self

    def export_printed_images(main_directory, progress_handler, timer, utilities, nuix_case, scoping_query)
        items = nuix_case.search(scoping_query)

        directory = File.join(SettingsUtils::case_data_dir(main_directory, nuix_case.name, nuix_case.guid), 'printed_images')
        
        timer.start('export_images')
        images_exported = Utils::export_printed_images(items, directory, utilities, progress_handler)
        timer.stop('export_images')
        images_exported
    end
end