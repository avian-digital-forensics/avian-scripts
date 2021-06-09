require 'set'
require 'date'
require_relative '../../utils/utils'
module HistorySearch
    extend self

    # Settings hash settings:
    #   :start_date_range_start => Script only considers history events with start date after this.
    #   :start_date_range_end => Script only considers history events with start date before this.
    #   :users => A list of strings denoting user names. Script only considers history events by one of these users.
    #   :global_tag => A tag given to all items with events with in the start date range done by one of the specified users.
    #       Leave empty to skip this step.
    #   :event_tag => The tag to search for events about. Leave empty to find all tag events.
    #   :tag_added => Whether to act on events where the specified tag was added.
    #   :tag_removed => Whether to act on events where the specified tag was removed.
    #   :tag_tag => The tag to give to all items with events where :event_tag was added or removed if those are specified. Leave empty to skip this step.
    def history_search(root_directory, nuix_case, utilities, progress_handler, temporary_tag_manager, timer, scoping_query, settings_hash)
        start_date_range_start, start_date_range_end = prepare_dates([settings_hash[:start_date_range_start], settings_hash[:start_date_range_end]])
        users = prepare_user_list(nuix_case, settings_hash[:users], progress_handler)
        global_tag = settings_hash[:global_tag]

        unless global_tag.empty?
            progress_handler.set_main_status_and_log_it('Finding specified events...')
            unless global_tag.start_with?('Avian|')
                global_tag = "Avian|#{global_tag}"
            end
            history = search_history(nuix_case, start_date_range_start, start_date_range_end, users, nil)
            progress_handler.set_main_status_and_log_it('Finding items with the specified events...')
            timer.start('events_to_items')
            history_items = history_event_items(history)
            timer.stop('events_to_items')
            unless scoping_query.empty?
                progress_handler.set_main_status_and_log_it('Restricting found items to scoping query...')
                timer.start('restrict_found_global_items_to_scoping_query')
                tag = temporary_tag_manager.create_temporary_tag('global_event_items', history_items, 'all items with events in range', progress_handler)
                timer.stop('restrict_found_global_items_to_scoping_query')
                history_items = nuix_case.search(Utils::join_queries(Utils::create_tag_query(tag), scoping_query))
            end

            Utils.bulk_add_tag(utilities, progress_handler, global_tag, history_items.select{|item| item.matches_search(scoping_query)})
        end

        event_tag = settings_hash[:event_tag]
        tag_added = settings_hash[:tag_added]
        tag_removed = settings_hash[:tag_removed]
        tag_tag = settings_hash[:tag_tag]
        unless tag_tag.nil? || tag_tag.empty? || (!tag_added && !tag_removed)
            progress_handler.set_main_status_and_log_it('Finding specified tag events...')
            timer.start('find_specified_tag_events')
            annotation_history = search_history(nuix_case, start_date_range_start, start_date_range_end, users, ['annotation'])
            events = annotation_history.select do |event|
                unless event.details.key?('tag') && event.details.key?('added')
                    next false
                end
                unless event_tag.empty? || event.details['tag'] = event_tag
                    next false
                end
                unless (event.details['added'] && tag_added) || (!event.details['added'] && tag_removed)
                    next false
                end
                next true
            end
            timer.stop('find_specified_tag_events')
            progress_handler.set_main_status_and_log_it('Finding items with the specified tag events...')
            timer.start('tag_events_to_items')
            items = history_event_items(events)
            timer.stop('tag_events_to_items')
            
            unless scoping_query.empty?
                progress_handler.set_main_status_and_log_it('Restricting found items to scoping query...')
                timer.start('restrict_found_tag_event_items_to_scoping_query')
                tag = temporary_tag_manager.create_temporary_tag('tag_event_items', items, 'all items with specified tag events', progress_handler)
                timer.stop('restrict_found_tag_event_items_to_scoping_query')
                items = nuix_case.search(Utils::join_queries(Utils::create_tag_query(tag), scoping_query))
            end
            Utils.bulk_add_tag(utilities, progress_handler, tag_tag, items.select{|item| item.matches_search(scoping_query)})
        end
    end

    def prepare_dates(date_list)
        if date_list.empty?
            return nil
        end
        date_list.map{ |date| Date.parse(date)}
    end

    def prepare_user_list(nuix_case, user_list, progress_handler)
        if user_list.empty?
            return nil
        end
        result = []
        for user_string in user_list
            found_user = false
            for case_user in nuix_case.all_users
                if case_user.long_name == user_string || case_user.short_name == user_string
                    result << case_user
                    found_user = true
                    break
                end
            end
            unless found_user
                progress_handler.log_message("ERROR: Could not find user with name '#{user_string}'.")
            end
        end
        result
    end

    def search_history(nuix_case, start_date_range_start, start_date_range_end, users, types)
        if users.nil?
            return search_history_single_user(nuix_case, start_date_range_start, start_date_range_end, nil, types)
        end

        if types.nil?
            types = [nil]
        end
                
        result = []
        for user in users
            for type in types
                result += search_history_single_user(nuix_case, start_date_range_start, start_date_range_end, user, types)
            end
        end
        result
    end

    def search_history_single_user(nuix_case, start_date_range_start, start_date_range_end, user, types)
        if types.nil?
            return nuix_case.history({'startDateAfter' => start_date_range_start, 'startDateBefore' => start_date_range_end, 'user' => user}).to_a
        end

        result = []
        for type in types
            result += nuix_case.history({'startDateAfter' => start_date_range_start, 'startDateBefore' => start_date_range_end, 'user' => user, 'type' => type}).to_a
        end
        result
    end

    def history_event_items(history_events)
        history_events.reduce(Set[]) { |result, event| result + event.affected_items }
    end
end