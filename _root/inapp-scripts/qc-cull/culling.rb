require_relative File.join('..', '..', 'utils', 'utils')

module QCCull
  extend self

  # Find items with QC exclusions.
  # Params:
  # +nuix_case+:: The Nuix case in which to search.
  # +progress_handler+:: An object that can work as a progress dialog.
  # +timer+:: The timer to record internal timings in.
  # +scoping_query+:: Only include items matching this query.
  # +exclusion_sets+:: A hash of tags=>exclusion reasons.
  def find_culled_items(nuix_case, progress_handler, timer, scoping_query, exclusion_sets)
    culled_item_query = exclusion_sets.values.map { |reason| "exclusion:\"#{reason}\"" }.join(' OR ')
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
  # +exclusion_sets+:: A hash of tags=>exclusion reasons.
  # +progress_handler+:: An object that can work as a progress dialog.
  # +timer+:: The timer to record internal timings in.
  # +utilities+:: A reference to the Nuix utilities object.
  def exclude_items(nuix_case, scoping_query, exclusion_sets, progress_handler, timer, utilities)
    timer.start('exclude_items')
    progress_handler.set_main_status_and_log_it("Excluding items...")
    exclusion_sets.each do |tag, reason|
      # Find exclusion items.
      timer.start('find_exclude_items')
      exclude_items = nuix_case.search(Utils::join_queries(scoping_query, Utils::create_tag_query(tag)))
      timer.stop('find_exclude_items')

      # Exclude items.
      timer.start('exclude_found_items')
      Utils::bulk_exclude(utilities, progress_handler, exclude_items, reason)
      timer.stop('exclude_found_items')
    end
    timer.stop('exclude_items')
  end
end
