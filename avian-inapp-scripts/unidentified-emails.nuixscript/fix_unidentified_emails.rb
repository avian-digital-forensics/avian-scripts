script_directory = File.dirname(__FILE__)
require File.join(script_directory,'..','setup.nuixscript','get_main_directory')

main_directory = get_main_directory(false)

unless main_directory
    puts('Script cancelled because no main directory could be found.')
    return
end

require File.join(main_directory, 'utils', 'utils')

require File.join(main_directory, 'utils', 'settings_utils')

require File.join(main_directory, 'utils', 'custom_communication')

require File.join(main_directory, 'utils', 'dates')

require File.join(main_directory, 'avian-inapp-scripts', 'unidentified-emails.nuixscript', 'find_unidentified_emails')

module FixUnidentifiedEmails
    extend self

    # Contains all aliases for the various fields in a communication.
    class CommunicationFieldAliases
        attr_reader :from, :to, :cc, :bcc, :subject, :date

        def initialize(from_aliases, to_aliases, cc_aliases, bcc_aliases, subject_aliases, date_aliases)
            @from = from_aliases
            @to = to_aliases
            @cc = cc_aliases
            @bcc = bcc_aliases
            @subject = subject_aliases
            @date = date_aliases
            
            unless Utils::sets_disjoint?(@from, @to, @cc, @bcc, @subject, @date) 
                raise ArgumentError, 'All sets of aliases must be disjoint.'
            end
        end

        def to_hash
            { :from => @from, :to => @to, :cc => @cc, :bcc => @bcc, :subject => @subject, :date => @date }
        end
    end

    def find_rfc_mails(nuix_case)
        return nuix_case.search('mime-type:message/rfc822')
    end

    # Cleans up the field. Removes surrounding quotation marks and whitespace.
    # Params:
    # +field+:: The string to cleanup.
    def clean_field(field)
        field.strip!
        # Remove a weird whitespace character found in the emails.
        field.gsub!(/ /, '')
        if field.start_with?('"') && field.end_with?('"')
            field[1..-2]
        else
            field
        end
    end

    # Return a hash of possible fields and their values.
    # Params:
    # +item+:: The item whose fields to find.
    # +text+:: The text to use. In case only a subset of the text is to be used. If nil, the only properties will be searched.
    # +communication_field_aliases+:: Lists of aliases for each of the communication fields. In text, a ':' will be added to the end of each.
    def find_fields(item, text, communication_field_aliases, timer)
        fields = {}

		if text
			lines = text.lines.map { |line| line.strip }
			for field_key, aliases in communication_field_aliases
				contained_alias = aliases.find { |field_alias| lines.any? { |line| line.start_with?(field_alias + ':') } }
				if contained_alias
					# If at least one alias is found in the text, store the first value.
                    fields[field_key] = lines.find { |line| line.start_with?(contained_alias + ':') }[contained_alias.size+1..-1].strip
                else
                    fields[field_key] = ''
				end
            end
        end

        if !text || fields[:date] == '' || fields[:from] == ''
            # If no from and date is found in the text, or no text is given, start again and look in the properties.
            fields = {}
            for field_key, aliases in communication_field_aliases
                alias_properties = aliases.select{ |field_alias| item.properties.key?(field_alias) }
                if alias_properties.size > 1
                    raise "Multiple properties found for field '#{field_key}'."
                elsif alias_properties.size == 1
                    # If a property key matches a field alias, store the value.
                    fields[field_key] = item.properties[alias_properties[0]].to_s
                else
                    fields[field_key] = ''
                end
            end
        end

        # Clean up fields.
        fields.each { |key,field| fields[key] = clean_field(field) }
        return fields
    end

    # Given a string representing a list of addresses, returns the list of addresses as CustomAddresses.
    # address_regexps should be a ordered list of regexps that match the different address formats. 
    #   Capture group 1 is the personal address and capture group 2 is the address address.
    # The address_splitter should split the string into a list of strings representing individual addresses.
    def identify_addresses(field_text, address_regexps, &address_splitter)
        if field_text == ''
            return []
        end
        address_strings = address_splitter.call(field_text).select { |s| s.strip != '' }
        return address_strings.map do |address_string|
            if regexp = address_regexps.find{ |regexp| address_string.match(regexp) }
                personal, address = address_string.match(regexp).captures
                Custom::CustomAddress.new(personal, address)
            else
                raise 'No regexp matches address string'
            end
        end
    end

    # Takes a string representing a date and returns a JodaTime DateTime.
    def parse_date(date_string)
        if date_string == ''
            return nil
        end
        english_date_string = Dates::danish_date_string_to_english(date_string)
        ruby_date_time = DateTime.parse(english_date_string)
        joda_time = Dates::date_time_to_joda_time(ruby_date_time)
        return joda_time
    end

    # The body of the FixUnidentifiedEmails script.
    # Finds the communication fields, adds them as custom metadata and exports them to a file by item guid.
    # Params:
    # +case_data_dir+:: The path string to the case's data directory.
    # +current_case+:: The current case.
    # +items+:: The items on which to run the script.
    # +progress_dialog+:: The progress_dialog to update with script progress.
    # +timer+:: The timer to record internal timings in.
    # +utilities+:: A reference to the Nuix Utitilies class.
    # +communication_field_aliases+:: Lists of aliases for each of the communication fields. In text, a ':' will be added to the end of each.
    # +start_area_line_num+:: The number of lines that will be searched for communication fields.
	# +no_text_search_tag+:: Any item will this text will only have its properties searched for fields.
    # +address_regexps+:: Regexps for possible address formats. First capture group should be the personal part and second is the address part. The address part should never be empty.
    # +email_mime_type+:: The MIME-type to give to those items that are not already of kind email.
    # +address_splitter+:: A block that takes a string and splits it into individual address strings that are then matched to the above regexps.
    def fix_unidentified_emails(case_data_dir, current_case, items, progress_dialog, timer, utilities, communication_field_aliases, start_area_line_num, no_text_search_tag, address_regexps, email_mime_type, export_printed_images, fixed_item_tag, &address_splitter)
        progress_dialog.set_main_status_and_log_it('Finding communication fields for items...')
        progress_dialog.set_main_progress(0,items.size)
        items_processed = 0
        item_communications = {}
        timer.start('find_communication_fields')
        for item in items
            progress_dialog.set_sub_status("Items processed: " + items_processed.to_s)

            # Find the text for each of the communication fields.
            timer.start('find_metadata_text')
            item_metadata_text = item.tags.include?(no_text_search_tag) ? nil :
				FindUnidentifiedEmails::metadata_text(item, start_area_line_num, timer)
            timer.stop('find_metadata_text')
            timer.start('find_field_text')
            fields = find_fields(item, item_metadata_text, communication_field_aliases, timer)
            timer.stop('find_field_text')

            # Extract information about the addresses from the from, to, cc, and bcc field strings.
            timer.start('identify_addresses')
            from_addresses = identify_addresses(fields[:from], address_regexps, &address_splitter)
            to_addresses = identify_addresses(fields[:to], address_regexps, &address_splitter)
            cc_addresses = identify_addresses(fields[:cc], address_regexps, &address_splitter)
            bcc_addresses = identify_addresses(fields[:bcc], address_regexps, &address_splitter)
            timer.stop('identify_addresses')

            # If the item is not already an email, set its MIME-type to the given email MIME-type.
            timer.start('find_mime_type')
            mime_type = item.is_kind('email') ? item.type.name : email_mime_type
            timer.stop('find_mime_type')

            # Find date.
            timer.start('find_date')
            date = parse_date(fields[:date])
            timer.stop('find_date')

            # Find subject.
            subject = fields[:subject]
            
            # Create communication.
            timer.start('create_custom_communication')
            communication = Custom::CustomCommunication.new(date, subject, from_addresses, to_addresses, cc_addresses, bcc_addresses)
            timer.stop('create_custom_communication')

            # Convert communication to yaml hash and add to hash.
            timer.start('convert_communication_to_yaml_hash')
            item_communications[item.guid] = [communication.to_yaml_hash, mime_type]
            timer.stop('convert_communication_to_yaml_hash')

            items_processed += 1
            progress_dialog.increment_main_progress

            if progress_dialog.abort_was_requested
                progress_dialog.log_message('Aborting script...')
                return
            end
        end
        timer.stop('find_communication_fields')

        # Finds the data file path.
        data_path = File.join(case_data_dir, 'unidentified_emails_data.yml')

        # Save communications to file.
        progress_dialog.set_main_status_and_log_it('Writing result to file, this may take a while...')
        timer.start('save_communications')
        File.open(data_path, 'w') { |file| file.write(item_communications.to_yaml) }
        timer.stop('save_communications')

        # Export printed images.
        timer.start('export_printed_images')
        if export_printed_images
            printed_image_dir = File.join(case_data_dir, 'unidentified_emails_printed_images')
            items_for_export = items.select { |item| item_communications[item.guid][1] != item.type.name }
            Utils::export_printed_images(items_for_export, printed_image_dir, utilities, progress_dialog)
        end
        timer.stop('export_printed_images')

        # Add tag to fixed items.
        timer.start('add_tag_to_fixed_items')
        progress_dialog.set_main_status_and_log_it('Adding tag to fixed items...')
        Utils.bulk_add_tag(utilities, progress_dialog, fixed_item_tag, items)
        timer.stop('add_tag_to_fixed_items')
    end
end
