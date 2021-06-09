require_relative 'utils'
require_relative 'inapp_script_utils'

module TemporaryTagManager
    extend self

    class TemporaryTagManager
        def initialize(utilities, timer, script_name)
            @utilities = utilities
            @timer = timer
            @script_name = script_name

            # A list of all the temporary tags added by the script.
            @temporary_tags = {}
        end

        # Add tag to the specified items.
        # The tag will be modified to ensure the proper prefix. The modified tag is returned.
        # Tag will be removed from all items in the case when the script is finished.
        # Params:
        # +tag+:: The tag to give to the items. Automatically adds the Avian| prefix if it is missing.
        # +items+:: The items to give the tag to.
        # +item_group_name+:: What to call the items in messages, e.g. item_group_name='RFC mails' -> 'Adding temporary tag to RFC mails for internal use...'
        # +progress_handler+:: The ProgressDialog used to update the user on progress.
        def create_temporary_tag(tag, items, item_group_name, progress_handler)
            # Add Avian| prefix to tag if it isn't there already.
            tag = InappScriptUtils::to_script_tag(@script_name, tag)
            @timer.start('add_temp_tag_' + tag)
            progress_handler.set_main_status_and_log_it('Adding temporary tag to ' + item_group_name + ' for internal use...')
            Utils.bulk_add_tag(@utilities, progress_handler, tag, items)
            @temporary_tags[tag] = item_group_name
            @timer.stop('add_temp_tag_' + tag)
            return tag
        end

        def delete(nuix_case, progress_handler)
            # Remove temporary tags.
            progress_handler.set_main_status_and_log_it('Removing temporary tags...')
            @timer.start('remove_temporary_tags')
            for tag,group_name in @temporary_tags
                @timer.start('remove_temp_tag_' + tag)
                progress_handler.set_main_status_and_log_it('Removing temporary tag from ' + group_name + '...')
                items_with_tag = nuix_case.search(Utils::create_tag_query(tag))
                Utils.bulk_remove_tag(@utilities, progress_handler, tag, items_with_tag)
                nuix_case.delete_tag(tag)
                @timer.stop('remove_temp_tag_' + tag)
            end
            @timer.stop('remove_temporary_tags')
        end
    end
end