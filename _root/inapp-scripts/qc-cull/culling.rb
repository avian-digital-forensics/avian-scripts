require_relative File.join('..', '..', 'utils', 'utils')

module QCCull
  extend self

  # Find items with QC exclusions.
  # Params:
  # +nuix_case+:: The Nuix case in which to search.
  # +progress_handler+:: An object that can work as a progress dialog.
  # +timer+:: The timer to record internal timings in.
  # +scoping_query+:: Only include items matching this query.
  # +exclude_tag_prefixes+:: A hash of prefixes=>reasons.
  def find_culled_items(nuix_case, progress_handler, timer, scoping_query, exclude_tag_prefixes)
    culled_item_query = exclude_tag_prefixes.values.map { |reason| "exclusion:\"#{reason}\"" }.join(' OR ')
    timer.start('check_for_items_with_culling')
    progress_handler.set_main_status_and_log_it('Searching for already Culled items...')
    found_items = nuix_case.search(Utils::join_queries(scoping_query, culled_item_query))
    timer.stop('check_for_items_with_culling')
    return found_items
  end

  # Excludes items in items with tags with specific prefixes.
  # Params:
  # +nuix_case+:: The case to look for the tags in.
  # +scoping_query+:: Will only exclude items that respond to this query.
  # +exclude_tag_prefixes+:: A hash of prefixes=>reasons.
  # +progress_handler+:: An object that can work as a progress dialog.
  # +timer+:: The timer to record internal timings in.
  # +utilities+:: A reference to the Nuix utilities object.
  def exclude_items(nuix_case, scoping_query, exclude_tag_prefixes, progress_handler, timer, utilities)
    timer.start('exclude_items')
    progress_handler.set_main_status_and_log_it("Excluding items...")
    exclude_tag_prefixes.each do |prefix, reason|
      # Create a list of which tags in the case are exclusion tags.
      # All items with these tags will be excluded.
      progress_handler.set_main_status_and_log_it("Finding exclusion tags with prefix '#{prefix}'...")
      timer.start('find_exclude_tags')
      exclude_tags = nuix_case.all_tags.select { |tag| tag.start_with?(prefix) }
      timer.stop('find_exclude_tags')


      # Finds all selected items with exclusion tags.
      progress_handler.set_main_status_and_log_it('Finding exclusion items...')
      timer.start('find_exclude_items')
      # Create a search string matching all items with exclusion tags.
      exclude_search = exclude_tags.map { |tag| "tag:\"#{tag}\""}.join(' OR ')
      if exclude_search.empty?
        # If there are no exclusion tags, skip exclusion.
        progress_handler.log_message("Skipping exclusion for prefix '#{prefix}' since no matching tags were found.")
        timer.stop('find_exclude_items')
      else
        # Add a clause to ensure that only selected items will match the search.
        exclude_search = Utils::join_queries(scoping_query, exclude_search)
        # Perform the search.
        exclude_items = nuix_case.search(exclude_search)
        timer.stop('find_exclude_items')
  
        # Actually exclude the items.
        progress_handler.set_main_status_and_log_it("Excluding items for prefix '#{prefix}'...")
        Utils::bulk_exclude(utilities, progress_handler, exclude_items, reason)
      end
    end
    timer.stop('exclude_items')
  end
end
