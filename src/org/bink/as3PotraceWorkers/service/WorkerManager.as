package org.bink.as3PotraceWorkers.service
{
	import flash.concurrent.Condition;
	import flash.concurrent.Mutex;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.Worker;
	import flash.system.WorkerDomain;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import org.bink.as3PotraceWorkers.model.AppConfig;
	
	/**
	 * The WorkerManager class is responsible for spawning backworkers and managing data handover from front to backworker.  
	 * The bulk of the backworker code resides in the Backworker class, for no other reason than to make it easier to read.
	 * 
	 * @author David Armstrong
	 */
	public class WorkerManager extends Sprite
	{
		/**
		 * The processed bitmapData to be displayed.
		 */
		public var bitmapData:BitmapData;
		
		/**
		 * The number of backworkers to spawn.
		 */
		private var backworkers:int;
		
		/**
		 * A vector of bytearrays to be shared between front and backworkers.
		 */
		private var sharedBytes:Vector.<ByteArray>;
		
		/**
		 * Used to manage efficient data handover between front and back workers.
		 */
		private var condition:Vector.<Condition>;
		
		/**
		 * Used to ensure the bitmapData is updated with only newer images.
		 */
		private var lastTimestamp:int = 0;
		
		/**
		 * @param	swfBytes Pass in this.loaderInfo.bytes from the Main.as.
		 * @param	backworkers The number of backworkers you'd like to spawn.  When in Debug mode, expect issues with 3 or more.  In Release, 8 have tested fine (on systems with 8 cores or threads).
		 */
		public function WorkerManager(swfBytes:ByteArray, backworkers:int = 1)
		{
			this.backworkers = backworkers;
			super();
			initBackworker(swfBytes);
		}
		
		/**
		 * Initial setup of front and backworkers.
		 * @param	swfBytes
		 */
		private function initBackworker(swfBytes:ByteArray):void
		{
			if (Worker.current.isPrimordial)
			{
				// Initialise the camera service.
				var cameraService:CameraService = new CameraService(AppConfig.WEBCAM_WIDTH, AppConfig.WEBCAM_HEIGHT, 30, "", null, false);
				
				bitmapData = new BitmapData(AppConfig.STAGE_WIDTH, AppConfig.STAGE_HEIGHT, false, 0x000000);
				addEventListener(Event.ENTER_FRAME, onEnterFrame);
				
				sharedBytes = new Vector.<ByteArray>();
				condition = new Vector.<Condition>();
				
				// Create each backworker and their corresponding shared ByteArray's and Condition/Mutex's.
				for (var i:int = 0; i < backworkers; i++)
				{
					var bgWorker:Worker = WorkerDomain.current.createWorker(swfBytes);
					
					sharedBytes[i] = new ByteArray();
					sharedBytes[i].shareable = true;
					
					var mutex:Mutex = new Mutex();
					condition[i] = new Condition(mutex);
					
					bgWorker.setSharedProperty("sharedBytes", sharedBytes[i]);
					bgWorker.setSharedProperty("condition", condition[i]);
					
					bgWorker.start();
				}
			}
			else // Entry point for the backworkers.
			{
				// Reference the shared objects made avaiable to the backworker.
				var shared:ByteArray = Worker.current.getSharedProperty("sharedBytes") as ByteArray;
				var cond:Condition = Worker.current.getSharedProperty("condition") as Condition;
				
				// A dedicated Backworker class for the purpose of code separation.
				var backworker:Backworker = new Backworker(shared, cond);
				addChild(backworker);
			}
		}
		
		/**
		 * Called when the backworker has finished processing the image data.  If the image is newer than previous ones, 
		 * it is written to the front worker's bitmapData.
		 * @param	id The worker ID.
		 */
		private function imageReady(id:int):void
		{
			// Make sure the amount of bytes available matches the amount expected.  It's expected this will not match on the first loop as the backworker has not yet completed a job.
			sharedBytes[id].position = 0;
			if (sharedBytes[id].bytesAvailable != AppConfig.PROCESSED_BYTES + AppConfig.TIMESTAMP_BYTES) return;			
			
			// Compare the incoming images timestamp with the most recently recorded.  If it's older, disregard it.
			var timestamp:int = sharedBytes[id].readInt();
			if (timestamp < lastTimestamp) return;
			lastTimestamp = timestamp;			
			
			// Lock the bitmapData before updating it (performance).
			bitmapData.lock();
			trace("Front: Processing " + id + " complete. Bytes = " + sharedBytes[id].length);
			
			// Write the processed bytes to the bitmapData object.
			bitmapData.setPixels(bitmapData.rect, sharedBytes[id]);
			
			// Unlock the bitmapData, which updates any bitmap objects referencing it.
			bitmapData.unlock();
		}
		
		private function onEnterFrame(e:Event):void
		{
			// Checks if the webcam has updated data.  If not, there's not point continuing.
			if (!CameraService.bitmapDataUpdated) return;
			
			// Loop through the backworkers and find one that's available for use.
			for (var i:int = 0; i < backworkers; i++)
			{
				// Check if this worker is available.
				if (condition[i].mutex.tryLock())
				{
					// Assume the worker has finishing a processing job.
					imageReady(i);
					
					// Clear all data from the shared ByteArray.
					sharedBytes[i].clear();
					
					// Insert the current timestamp.
					sharedBytes[i].writeInt(getTimer());
					
					// Write the webcam data to the ByteArray.
					CameraService.bitmapData.copyPixelsToByteArray(CameraService.bitmapData.rect, sharedBytes[i]);
					trace("Front: Sending...");
					
					// Notify the waiting Backworker (condition.wait()) that it's about to be handed control of the mutex.
					condition[i].notify();
					
					// Unlock the mutex, so the Backworker can take control.
					condition[i].mutex.unlock();
					break;
				}
			}
		}
	
	}

}