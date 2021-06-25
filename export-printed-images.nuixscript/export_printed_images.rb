root_directory = File.expand_path('../../_root', __FILE__)

require File.join(root_directory, 'utils', 'utils')

require File.join(root_directory, 'utils', 'settings_utils')

module ExportPrintedImages
    extend self

    def export_printed_images(root_directory, progress_handler, timer, utilities, nuix_case, scoping_query)
        items = nuix_case.search(scoping_query)

        directory = File.join(SettingsUtils::case_data_dir(root_directory, nuix_case.name, nuix_case.guid), 'printed_images')
        
        timer.start('export_images')
        images_exported = Utils::export_printed_images(items, directory, utilities, progress_handler)
        timer.stop('export_images')
        images_exported
    end
end
