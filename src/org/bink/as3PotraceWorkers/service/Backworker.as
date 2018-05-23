package org.bink.as3PotraceWorkers.service
{
	import com.powerflasher.as3potrace.POTrace;
	import com.powerflasher.as3potrace.backend.GraphicsDataBackend;
	import flash.concurrent.Condition;
	import flash.display.BitmapData;
	import flash.display.CapsStyle;
	import flash.display.GraphicsSolidFill;
	import flash.display.GraphicsStroke;
	import flash.display.IGraphicsData;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.system.MessageChannel;
	import flash.utils.ByteArray;
	import org.bink.as3PotraceWorkers.model.AppConfig;
	
	/**
	 * Backworker consolidates all code related to the backworker.
	 * @author David Armstrong
	 */
	public class Backworker extends Sprite
	{
		private var id:int;
		private var sharedBytes:ByteArray;
		
		/**
		 * The traced vector data is drawn into this sprite.
		 */
		private var sketch:Sprite;
		
		/**
		 * The traced vector data.
		 */
		private var gd:Vector.<IGraphicsData>;
		
		private var condition:Condition;
		private var matrix:Matrix;
		
		private var sharedBitmapData:BitmapData;
		private var processedBitmapData:BitmapData;
		
		/**
		 * @param	sharedBytes The shared ByteArray both front and backworker have access to.
		 * @param	condition The Condition/Mutex allowing efficient handover of data via the shared ByteArray.
		 */
		public function Backworker(sharedBytes:ByteArray, condition:Condition)
		{
			this.id = id;
			this.sharedBytes = sharedBytes;
			this.condition = condition;
			
			init();
		}
		
		private function init():void
		{
			// Create the BitmapData objects that'll be re-used, rather than created/destroyed.  This reduces GC overhead.
			sharedBitmapData = new BitmapData(AppConfig.WEBCAM_WIDTH, AppConfig.WEBCAM_HEIGHT, false, 0x000000);
			processedBitmapData = new BitmapData(AppConfig.STAGE_WIDTH, AppConfig.STAGE_HEIGHT, false, 0x000000);
			
			sketch = new Sprite();
			gd = new Vector.<IGraphicsData>();
			
			// Used to scale the traced vector up to the stage dimensions.
			var myScale:Number = AppConfig.STAGE_WIDTH / AppConfig.WEBCAM_WIDTH;
			matrix = new Matrix();
			matrix.scale(myScale, myScale);
			
			addEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}
		
		private function enterFrameHandler(e:Event):void
		{
			// Get control of the mutex.  Will pause this worker until control is possible.
			condition.mutex.lock();
			condition.wait(); // Waits for condition.notify() to be called.
			
			trace("Back" + id + ": Got mutex lock.");
			
			// Process the image data.
			processImage();
			
			// Processing complete, release mutex control, allowing the front worker to access the processed image data.
			condition.mutex.unlock();
		}
		
		/**
		 * Takes the shared ByteArray, writes it to BitmapData, traces it to Vector, converts that to scaled BitmapData and re-writes it back into the shared ByteArray.
		 */
		private function processImage():void
		{
			trace("Back" + id + ": Processing...");
			
			// Check that the bytes available match the expected amount.
			sharedBytes.position = 0;
			if (sharedBytes.bytesAvailable != AppConfig.SHARED_BYTES + AppConfig.TIMESTAMP_BYTES) return;
			
			// Write the sharedBytes into BitmapData.
			sharedBitmapData.setPixels(sharedBitmapData.rect, sharedBytes);
			
			// Clears the IGraphicsData vector.
			gd.length = 0;
			gd.push(new GraphicsStroke(AppConfig.STROKE_THICKNESS, true, LineScaleMode.NONE, CapsStyle.ROUND, JointStyle.ROUND, 3, new GraphicsSolidFill(AppConfig.STROKE_COLOUR, 1)));
			
			// Convert the bitmapData to vector.
			var potrace:POTrace = new POTrace(null, new GraphicsDataBackend(gd));
			potrace.potrace_trace(sharedBitmapData);
			
			// Reset the graphics object (clean slate).
			sketch.graphics.clear();
			// Draw the vector data.
			sketch.graphics.drawGraphicsData(gd);
			
			// Processed image bytes will be written after the timestamp, overwriting the original unprocessed image data.
			sharedBytes.position = AppConfig.TIMESTAMP_BYTES;
			
			// Blank the bitmapData (clean slate) before drawing the vector data to it.
			processedBitmapData.fillRect(processedBitmapData.rect, 0x000000);
			
			// Draw the vector data to a BitmapData object.
			processedBitmapData.drawWithQuality(sketch, matrix, null, null, processedBitmapData.rect, false, AppConfig.DRAW_QUALITY);
			
			// Writes the processed BitmapData back into the shared ByteArray object.
			processedBitmapData.copyPixelsToByteArray(processedBitmapData.rect, sharedBytes);
			trace("Back" + id + ": Processing complete. Bytes = " + sharedBytes.length);
		}
	}
}