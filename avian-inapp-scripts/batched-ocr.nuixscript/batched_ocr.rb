# This script was originally taken by the github repository https://github.com/Nuix/Batched-OCR by JuicyDragon.

# Standard code for finding main directory.
script_directory = File.dirname(__FILE__)
require File.join(script_directory,"..","setup.nuixscript","get_main_directory")

main_directory = get_main_directory(false)

unless main_directory
    puts("Script cancelled.")
    return
end

# Progress messages.
require File.join(main_directory,"utils","utils")
# Timings.
require File.join(main_directory,"utils","timer")
# For GUI messages.
require File.join(main_directory,"utils","nx_utils")
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

dialog.display
if dialog.getDialogResult == true
    values = dialog.toMap
    batch_index = 0
    last_progress = Time.now

    $window.closeAllTabs

    ProgressDialog.forBlock do |pd|
        progress_dialog.on_message_logged do |message|
            Utils.print_progress(message)
        end
        pd.setTitle("Batched OCR")
        pd.logMessage("Selected Items: #{$current_selected_items.size}")
        pd.logMessage("Batch Size: #{values["target_batch_size"]}")

        pd.logMessage("Worker Settings:")
        values["worker_settings"].each do |k,v|
            pd.logMessage("\t#{k} => #{v}")
        end

        pd.logMessage("OCR Settings:")
        values["ocr_settings"].each do |k,v|
            pd.logMessage("\t#{k} => #{v}")
        end

        ocr_processor = $utilities.createOcrProcessor
        ocr_processor.setParallelProcessingSettings(values["worker_settings"])
        ocr_processor.whenItemEventOccurs do |info|
            if (Time.now - last_progress) > 0.5
                pd.setSubStatus("Stage: #{info.getStage.split("_").map{|v|v.capitalize}.join(" ")}")
                last_progress = Time.now
            end
        end
        
        timer = Timing::Timer.new
        
        total_batches = ($current_selected_items.size.to_f / values["target_batch_size"].to_f).ceil
        pd.setMainProgress(0,total_batches)
        stop_requested = false
        $current_selected_items.each_slice(values["target_batch_size"]) do |slice_items|
            break if pd.abortWasRequested
            
            # Start batch timer.
            timer_name = "batch#{batch_index+1}"
            if timer.exist?(timer_name)
                puts("Unexpected behavior: several batches with same index.")
                timer.reset(timer_name)
            end
            timer.start(timer_name)
            
            # Process batch.
            pd.setSubProgress(0,slice_items.size)
            pd.setMainStatusAndLogIt("Processing Batch #{batch_index+1}")
            ocr_job = ocr_processor.processAsync(slice_items,values["ocr_settings"])
            while !ocr_job.hasFinished
                if pd.abortWasRequested && !stop_requested
                    ocr_job.stop
                    stop_requested = true
                end
                pd.setSubProgress(ocr_job.getCurrentStageExportedItemsCount,slice_items.size)
                sleep(0.25)
            end
            
            # Print timer result.
            timer.stop(timer_name)
            pd.log_message("Finished batch #{batch_index+1}")
            timing_message = "Time taken: " + timer.total_time(timer_name)
            pd.log_message(timing_message)
            
            batch_index += 1
            pd.setMainProgress(batch_index)
        end

        if pd.abortWasRequested
            pd.setMainStatusAndLogIt("User Aborted")
        else
            pd.setCompleted
        end

        $window.openTab("workbench",{"search"=>""})
    end
end