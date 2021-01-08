# This script was originally taken by the github repository https://github.com/Nuix/Batched-OCR by JuicyDragon.
root_directory = File.expand_path('../../_root', __FILE__)

# Progress messages.
require File.join(root_directory,"utils","utils")
# Timings.
require File.join(root_directory,"utils","timer")
# For GUI messages.
require File.join(root_directory,"utils","nx_utils")
java_import "com.nuix.nx.NuixConnection"
java_import "com.nuix.nx.LookAndFeelHelper"
java_import "com.nuix.nx.dialogs.ChoiceDialog"
java_import "com.nuix.nx.dialogs.TabbedCustomDialog"
java_import "com.nuix.nx.dialogs.CommonDialogs"
java_import "com.nuix.nx.dialogs.ProgressDialog"
java_import "com.nuix.nx.digest.DigestHelper"

LookAndFeelHelper.setWindowsIfMetal
NuixConnection.setUtilities($utilities)
NuixConnection.setCurrentNuixVersion(NUIX_VERSION)

dialog = TabbedCustomDialog.new("Batched OCR")

main_tab = dialog.addTab("main_tab","Main")
main_tab.appendSpinner("target_batch_size","Target Batch Size",10000)

ocr_settings_tab = dialog.addTab("ocr_settings_tab","OCR Settings")
ocr_settings_tab.appendOcrSettings("ocr_settings")

worker_settings_tab = dialog.addTab("worker_settings_tab","Worker Settings")
worker_settings_tab.appendLocalWorkerSettings("worker_settings")

dialog.validateBeforeClosing do |values|
    if CommonDialogs.getConfirmation("The script needs to close all workbench tabs, proceed?") == false
        next false
    end
    next true
end

def log_message(progress_dialog, message)
    time_stamp = Utils.time_stamp
    puts(time_stamp + "  " + message)
    progress_dialog.log_message(time_stamp + "  " + message)
end

dialog.display
if dialog.get_dialog_result == true
    values = dialog.to_map
    batch_index = 0
    last_progress = Time.now

    $window.closeAllTabs

    ProgressDialog.for_block do |pd|
        pd.set_title("Batched OCR")
        log_message(pd, "Selected Items: #{$current_selected_items.size}")
        log_message(pd, "Batch Size: #{values["target_batch_size"]}")

        log_message(pd,"Worker Settings:")
        values["worker_settings"].each do |k,v|
            log_message(pd, "\t#{k} => #{v}")
        end

        log_message(pd,"OCR Settings:")
        values["ocr_settings"].each do |k,v|
            log_message(pd,"\t#{k} => #{v}")
        end

        ocr_processor = $utilities.createOcrProcessor
        ocr_processor.set_parallel_processing_settings(values["worker_settings"])
        ocr_processor.when_item_event_occurs do |info|
            if (Time.now - last_progress) > 0.5
                pd.set_sub_status("Stage: #{info.stage.split("_").map{|v|v.capitalize}.join(" ")}")
                last_progress = Time.now
            end
        end
        
        timer = Timing::Timer.new
        
        total_batches = ($current_selected_items.size.to_f / values["target_batch_size"].to_f).ceil
        pd.set_main_progress(0,total_batches)
        stop_requested = false
        $current_selected_items.each_slice(values["target_batch_size"]) do |slice_items|
            break if pd.abort_was_requested
            
            # Start batch timer.
            timer_name = "batch#{batch_index+1}"
            if timer.exist?(timer_name)
                log_message(pd, "Unexpected behavior: several batches with same index.")
                timer.reset(timer_name)
            end
            timer.start(timer_name)
            
            # Process batch.
            pd.set_sub_progress(0,slice_items.size)
            log_message(pd, "Processing Batch #{batch_index+1}...")
            pd.set_main_status("Processing Batch #{batch_index+1}...")
            ocr_job = ocr_processor.processAsync(slice_items,values["ocr_settings"])
            while !ocr_job.hasFinished
                if pd.abortWasRequested && !stop_requested
                    ocr_job.stop
                    stop_requested = true
                end
                pd.set_sub_progress(ocr_job.getCurrentStageExportedItemsCount,slice_items.size)
                sleep(0.25)
            end
            
            # Print timer result.
            timer.stop(timer_name)
            batch_index += 1
            timing_message = "Time taken: " + timer.total_time(timer_name).to_s
            log_message(pd,"Finished batch #{batch_index}. " + timing_message)
            
            pd.set_main_progress(batch_index)
        end

        if pd.abort_was_requested
            log_message(pd, "User Aborted")
            pd.set_main_status("User Aborted")
        else
            pd.set_completed
        end

        $window.open_tab("workbench",{"search"=>""})
    end
end