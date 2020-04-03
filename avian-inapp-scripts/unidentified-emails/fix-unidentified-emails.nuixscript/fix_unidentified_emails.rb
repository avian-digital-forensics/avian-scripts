script_directory = File.dirname(__FILE__)
require File.join(script_directory,'..','..','setup.nuixscript','get_main_directory')

main_directory = get_main_directory(false)

unless main_directory
    puts('Script cancelled because no main directory could be found.')
    return
end

require File.join(main_directory, 'utils', 'utils')

require File.join(main_directory, 'utils', 'settings_utils')

require File.join(main_directory, 'utils', 'custom_communication')

require File.join(main_directory, 'utils', 'dates')

require File.join(main_directory, 'avian-inapp-scripts', 'unidentified-emails', 'find-unidentified-emails.nuixscript', 'find_unidentified_emails')

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

    # Return a hash of possible fields and there values.
    def find_fields(item, text, communication_field_aliases, timer)
        lines = text.lines.map { |line| line.strip }
        
        fields = {}

        for field_key, aliases in communication_field_aliases
            contained_aliases = aliases.select { |field_alias| lines.any? { |line| line.start_with?(field_alias + ':') } }
            if contained_aliases.size >= 1
                # If at least one alias is found in the text, store the value.
                fields[field_key] = lines.find { |line| line.start_with?(contained_aliases[0] + ':') }[contained_aliases[0].size+1..-1].strip
            else 
                # If no alias is found in the text, look for one in properties.
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
        address_strings = address_splitter.call(field_text)
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
    # +communication_field_aliases+:: Lists of aliases for each of the communication fields. In text, a ':' will be added to the end of each.
    # +start_area_size+:: Number of characters at the start of each items text to search for field information.
    # +address_regexps+:: Regexps for possible address formats. First capture group should be the personal part and second is the address part. The address part should never be empty.
    # +address_splitter+:: A block that takes a string and splits it into individual address strings that are then matched to the above regexps.
    def fix_unidentified_emails(case_data_dir, current_case, items, progress_dialog, timer, communication_field_aliases, start_area_size, address_regexps, &address_splitter)
        progress_dialog.set_main_status_and_log_it('Finding communication fields for items...')
        progress_dialog.set_main_progress(0,items.size)
        items_processed = 0
        item_communications = {}
        timer.start('find_communication_fields')
        for item in items
            progress_dialog.set_sub_status("Items processed: " + items_processed.to_s)

            # Find the text for each of the communication fields.
            timer.start('find_field_text')
            fields = find_fields(item, FindUnidentifiedEmails::metadata_text(item, start_area_size, timer), communication_field_aliases, timer)
            timer.stop('find_field_text')

            # Extract information about the addresses from the from, to, cc, and bcc field strings.
            timer.start('identify_addresses')
            from_addresses = identify_addresses(fields[:from], address_regexps, &address_splitter)
            to_addresses = identify_addresses(fields[:to], address_regexps, &address_splitter)
            cc_addresses = identify_addresses(fields[:cc], address_regexps, &address_splitter)
            bcc_addresses = identify_addresses(fields[:bcc], address_regexps, &address_splitter)
            timer.stop('identify_addresses')

            # Find date.
            timer.start('find_date')
            date = parse_date(fields[:date])
            timer.stop('find_date')

            # Find subject.
            subject = fields[:subject]
            
            # Create communication and add to hash
            communication = Custom::CustomCommunication.new(date, subject, from_addresses, to_addresses, cc_addresses, bcc_addresses)
            item_communications[item.guid] = communication

            # Add custom metadata. Should be removed later.
            address_to_string = lambda do |address|
                "<#{address.personal}, #{address.address}>"
            end
			item.custom_metadata['Date'] = date.to_s
			item.custom_metadata['Subject'] = subject
            item.custom_metadata['FromAddresses'] = from_addresses.map(&address_to_string).to_s
            item.custom_metadata['ToAddresses'] = to_addresses.map(&address_to_string).to_s
            item.custom_metadata['CcAddresses'] = cc_addresses.map(&address_to_string).to_s
            item.custom_metadata['BccAddresses'] = bcc_addresses.map(&address_to_string).to_s

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
        timer.start('save_communications')
        timer.start('create_yaml_hash')
        yaml_hash = Hash[item_communications.map{ |guid, communication| [guid, communication.to_yaml_hash] }]
        timer.stop('create_yaml_hash')
        File.open(data_path, 'w') { |file| file.write(yaml_hash.to_yaml) }
        timer.stop('save_communications')
    end
end