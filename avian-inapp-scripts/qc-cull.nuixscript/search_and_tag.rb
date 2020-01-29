module QCCull
    extend self

    # Performs Search and Tag in the given case.
    # Progress is shown in the main progress bar of the given progress dialog.
    def search_and_tag(current_case, progress_dialog, timer, search_and_tag_files, scoping_query)
        # Initialize a bulk searcher with the given scoping query.
        bulk_searcher = current_case.create_bulk_searcher.with_scoping_query(scoping_query)
        # Imports the specified files to the bulk searcher.
        for file in search_and_tag_files
            bulk_searcher.import_file(file)
        end

        progress_dialog.set_sub_progress_visible(false)
        
        progress_dialog.set_main_status_and_log_it('Performing search and tag...')
        timer.start('search_and_tag')
        num_items = current_case.search(bulk_searcher.scoping_query).size
        item_num = 1
        progress_dialog.set_main_progress(0, num_items)
        # Perform search
        bulk_searcher.run do |progress_info|
            progress_dialog.increment_main_progress
            progress_dialog.set_sub_status("#{item_num += 1}/#{num_items}")
        end
        timer.stop('search_and_tag')
    end
end