package org.bink.as3PotraceWorkers.model 
{
	import flash.display.StageQuality;
	/**
	 * A centralised place for app settings.
	 * @author David Armstrong
	 */
	public class AppConfig 
	{
		// DIMENSIONS
		
		// Webcam dimensions.  This works much better on a low setting, producing smoother vector traces.  Higher resolutions are also prohibitively slow.
		static public const WEBCAM_WIDTH:int = 640;
		static public const WEBCAM_HEIGHT:int = 360;
		
		// The stage dimensions the traced vector will be scaled up to.
		static public const STAGE_WIDTH:int = 1920;
		static public const STAGE_HEIGHT:int = 1080;
		
		
		// DATA
		
		// The expected sizes for ByteArrays.
		static public const SHARED_BYTES:int = WEBCAM_WIDTH * WEBCAM_HEIGHT * 4;
		static public const PROCESSED_BYTES:int = STAGE_WIDTH * STAGE_HEIGHT * 4;
		static public const TIMESTAMP_BYTES:int = 4;
		
		
		// VECTOR
		
		// The line/stroke thickness, colour and antialising.
		static public const STROKE_THICKNESS:int = 5;
		static public const STROKE_COLOUR:uint = 0xFFFFFF;
		static public const DRAW_QUALITY:String = StageQuality.BEST;
		
		public function AppConfig() 
		{
			
		}
		
	}

}