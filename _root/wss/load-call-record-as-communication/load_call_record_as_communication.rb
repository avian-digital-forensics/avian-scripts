require 'date'

require_relative File.join('..','..','utils','custom_communication')
require_relative File.join('..','..','utils','dates')

module LoadCallRecordAsCommunication
  extend self


  def run_init(wss_global)
    # Will be run once before loading items.
    # Setup script here.
  end
  
  def run(wss_global, worker_item)
    # TODO:
    # The script could take some standard properties as being the various communication fields, and then a custom metadata profile could ensure that these were created.
    source_item = worker_item.getSourceItem

    if source_item.getType.getName == 'application/x-database-table-row'
      begin
        properties = source_item.properties
        
        date_string = properties['Time'].to_s
        date_time = DateTime.parse(date_string, '%Y-%m-%d %H:%M:%S')
        joda_date_time = Dates::date_time_to_joda_time(date_time)

        from_address_personal = properties['From name'].to_s
        if from_address_personal == 'NOT FOUND'
            from_address_personal = ''
        end
        from_address_address = properties['From no'].to_s
        from_address = Custom::CustomAddress::new(from_address_personal, from_address_address, 'telephone-number')

        to_address_personal = properties['To name'].to_s
        if to_address_personal == 'NOT FOUND'
            to_address_personal = ''
        end
        to_address_address = properties['To no'].to_s
        to_address = Custom::CustomAddress::new(to_address_personal, to_address_address, 'telephone-number')

        communication = Custom::CustomCommunication::new(joda_date_time, '', [from_address], [to_address])

        worker_item.set_item_communication(communication)
        worker_item.set_item_type('application/x-call-record')

        item_name = "#{from_address_address} -> #{to_address_address}"
        worker_item.set_item_name(item_name)
        
      rescue Exception => ex
        worker_item.addTag('Avian|WSS Error')
        worker_item.addCustomMetadata('Processing Error',ex.inspect.to_s,'text','user')
        STDERR::puts("Processing error for item #{worker_item.item_guid}")
      end
    end
  end
  
  def run_close(wss_global)
    # Will be run after loading all items.
  end
end
  