package org.bink.as3PotraceWorkers
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.system.Worker;
	import org.bink.as3PotraceWorkers.service.WorkerManager;
	
	/**
	 * A demo that explores:
	 * 
	 * 1. Realtime vector tracing using Claus Wahlers' ActionScript 3.0 port of potrace.
	 * 	Potrace by Peter Selinger: http://potrace.sourceforge.net/
	 * 	Claus Wahlers' ActionScript 3.0 port of potrace 1.8: https://wahlers.com.br/claus/blog/as3-bitmap-tracer-vectorizer-as3potrace/
	 * 
	 * 2. An efficient way to spawn and use multiple workers of an easily adjustable amount.
	 * 	When running Debug builds, using 3 or more workers may throw errors.
	 * 	Successfully tested up to 8 workers in Release builds.
	 *
	 * 3. Using efficient Condition and Mutex operations to handover data between front and back workers, rather than the slower MessageChannel method.
	 * 
	 * @author David Armstrong
	 */
	public class Main extends Sprite 
	{
		
		public function Main() 
		{
			init();
		}
		
		private function init():void 
		{
			// Wherever the WorkerManager is initialised, just make sure the loaderInfo.bytes come from here (root of the code, such as Main.as).
			var workerManager:WorkerManager = new WorkerManager(this.loaderInfo.bytes, 8);
			addChild(workerManager);
			
			// Display objects only need be added to the main display list, not the worker's, so check if it's Primordial (main) before adding.
			if (Worker.current.isPrimordial)
			{
				// Reference the processed bitmapData, updated by workerManager.
				var bitmap:Bitmap = new Bitmap(workerManager.bitmapData);
				
				// Mirror the bitmap so the webcam feed is correctly mirroring the user.
				bitmap.scaleX = -1;
				bitmap.x += bitmap.width;				
				
				addChild(bitmap);
			}
		}
		
	}
	
}