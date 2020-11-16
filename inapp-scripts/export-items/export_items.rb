module ExportItems
    extend self

    def export_items(nuix_case, progress_handler, timer, utilities, items, settings_hash)
        exporter = utilities.create_batch_exporter(settings_hash[:output_path])

        # Configure to export text if settings specify this
		if settings_hash[:export_text]
			progress_handler.set_main_status_and_log_it("Adding text...")
			exporter.addProduct("text", {
				:naming => "guid",
				:path => "TEXT",
			})
		end

		# Configure to export natives if settings specify this
		if settings_hash[:export_natives]
			progress_handler.set_main_status_and_log_it("Adding natives...")
			exporter.addProduct("native", {
				:naming => "guid",
				:path => "NATIVE",
			})
		end

		# Configure to export PDFs if settings specify this
		if settings_hash[:export_pdf]
			progress_handler.set_main_status_and_log_it("Adding PDFs...")
			exporter.addProduct("pdf", {
				:naming => "guid",
				:path => "PDF",
			})
		end

		# Configure to export TIFFs if settings specify this
		if settings_hash[:export_tiff]
			progress_handler.set_main_status_and_log_it("Adding TIFFs...")
			exporter.addProduct("tiff", {
				:naming => "guid",
				:path => "TIFF",
			})
        end
        
        # Get progress dialog ready and hookup export callback so that it will
		# update the progress dialog
		progress_handler.set_main_progress(0,items.size)
        
        current_export_stage = nil
		exporter.when_item_event_occurs do |info|
			stage_name = info.get_stage
			progress_handler.set_sub_status("Export Stage: #{stage_name}")
			progress_handler.set_main_progress(info.get_stage_count)
			if current_export_stage != stage_name
				progress_handler.log_message("Export Stage: #{stage_name}")
				current_export_stage = stage_name
			end
        end
        
        progress_handler.set_main_status_and_log_it("Exporting items...")
		exporter.export_items(items)
		
		"Items has been exported to: #{settings_hash[:output_path].to_s}"
    end
end