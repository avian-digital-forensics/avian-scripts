require_relative File.join('..', '..', 'utils', 'utils')
require_relative File.join('..', ,"..",'resources','Nx.jar')

require 'java'

# Allow catching this specific exception.
java_import 'java.lang.IllegalStateException'

module QCCull
  extend self

  # Find items with QC or Culling tags.
  # Params:
  # +nuix_case+:: The Nuix case in which to search.
  # +progress_handler+:: An object that can work as a progress dialog.
  # +timer+:: The timer to record internal timings in.
  # +scoping_query+:: Only include items matching this query.
  def check_for_items_with_qc_tags(nuix_case, progress_handler, timer, scoping_query)
    qc_tag_query = 'tag:"Avian|QC*" OR tag:"Avian|Exclude*"'
    timer.start('check_for_items_with_qc')
    progress_handler.set_main_status_and_log_it('Searching for already QC\'ed items...')
    found_items = nuix_case.search(Utils::join_queries(scoping_query, qc_tag_query))
    timer.end('check_for_items_with_qc')
    return found_items
  end

  # Performs Search and Tag in the given case.
  # Progress is shown in the main progress bar of the given progress dialog.
  def search_and_tag(current_case, progress_dialog, timer, search_and_tag_files, scoping_query)
    # Initialize a bulk searcher with the given scoping query.
    bulk_searcher = current_case.create_bulk_searcher
    # Imports the specified files to the bulk searcher.
    for file in search_and_tag_files
      bulk_searcher.import_file(file)
    end
    bulk_searcher = bulk_searcher.with_scoping_query(scoping_query)

    progress_dialog.set_sub_progress_visible(false)
    
    progress_dialog.set_main_status_and_log_it('Performing search and tag...')
    timer.start('search_and_tag')
    num_rows = bulk_searcher.row_count
    row_num = 0
    progress_dialog.set_main_progress(0, num_rows)
    # Perform search
    begin
      bulk_searcher.run do |progress_info|
        
        progress_dialog.increment_main_progress
        progress_dialog.set_sub_status("#{row_num += 1}/#{num_rows}")
      end
    rescue IllegalStateException => cnfe
      if cnfe.message.include?('Cannot find the file for digest list')
        STDERR.puts('Missing a digest list!')
        progress_dialog.log_message('ERROR: Missing a digest list!')
      else
        STDERR.puts('Found error in search and tag.')
      end
      throw cnfe
    end
    timer.stop('search_and_tag')
    progress_dialog.log_message('Finished search and tag.')
  end
end