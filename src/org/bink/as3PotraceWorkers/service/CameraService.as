package org.bink.as3PotraceWorkers.service
{
	/**
	 * A simple singleton-like class that aims to make the Camera and it's bitmapData
	 * available to multiple classes efficiently.
	 *
	 * Instantiate it in the ViewRoot.
	 *
	 * In classes using this service, to fetch the current frame's bitmapData, use:
	 * CameraService.bitmapData
	 *
	 * To display the camera feed:
	 *
	 * var texture:Texture = Texture.fromCamera(CameraService.camera, 1, function():void
	 *	{
	 *		var image:Image = new Image(texture);
	 *		image.blendMode = BlendMode.NONE; // Optional, but good for performance if alpha not required.
	 *		addChild(image);
	 *		image.width = CameraService.width;
	 *		image.height = CameraService.height;
	 *	});
	 *
	 *
	 * @author David Armstrong
	 */
	
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Camera;
	import flash.media.Video;
	
	public class CameraService
	{
		/**
		 * A static reference to the Camera object.
		 */
		public static var camera:Camera;
		
		/**
		 * A static reference to the Texture of the camera feed.
		 */
		//private static var _texture:Texture;
		
		/**
		 * The Camera's reported width.
		 */
		public static var width:int;
		
		/**
		 * The Camera's reported height.
		 */
		public static var height:int;
		
		private static var _cameraAvailable:Boolean = false;
		
		/**
		 * The name of the camera, as recognised by the OS.
		 */
		public static var cameraName:String = null;
		
		private static var cached:Boolean;
		private static var sourceBitmapData:BitmapData;
		private static var _bitmapData:BitmapData;
		public static var mirror:Boolean;
		private static var horizontalFlipMatrix:Matrix;
		public static var clipRect:Rectangle;
		private static var video:Video;
		
		/**
		 * When bitmapData is fetched, this becomes false.  When the camera updates the bitmapData, this becomes true.  Use it to manage texture updates and the like.
		 */
		public static var bitmapDataUpdated:Boolean;
		
		private static var point:Point;
		
		static private var cameraWidth:int;
		static private var cameraHeight:int;
		static private var fps:int;
		
		/**
		 *
		 * @param	cameraWidth Your target camera resolution for width.  Does not promise this width, the device will try to use the closest supported resolution.
		 * @param	cameraHeight Your target camera resolution for height.  Does not promise this height, the device will try to use the closest supported resolution.
		 * @param	fps  Your target camera framerate.  Does not promise this framerate, the device will try to use the closest supported rate.
		 * @param	cameraName The name of the camera, as reported by the Camera.names array.  Leave empty to use first available camera.  Using "-1" (an invalid name) will result in using the last available camera.
		 * @param	clipRect Define the cropped output of the bitmapData.
		 * @param	mirror Flip the Camera feed horizontally.  This affects CameraService.bitmapData and my partnering WebcamView class also takes it into account.
		 */
		public function CameraService(cameraWidth:int = 1920, cameraHeight:int = 1080, fps:int = 30, cameraName:String = "", clipRect:Rectangle = null, mirror:Boolean = false)
		{
			super();
			
			CameraService.clipRect = clipRect;
			CameraService.mirror = mirror;
			CameraService.cameraWidth = cameraWidth;
			CameraService.cameraHeight = cameraHeight;
			CameraService.fps = fps;
			CameraService.cameraName = cameraName;
			
			initCamera();
		}
		
		static private function initCamera():void
		{
			if (camera) return;
			if (!Camera.names || Camera.names.length == 0)
			{
				trace("CameraService: No cameras found.");
				_cameraAvailable = false;
				return;
			}
			
			trace("CameraService: Available cameras:");
			trace(Camera.names);
			
			if (cameraName != "")
			{
				if (Camera.names.indexOf(cameraName) == -1)
				{
					trace("CameraService: Camera " + cameraName + " is not found.  Perhaps you got the name wrong, or it's not currently connected?");
					trace("CameraService: Failing over to last available camera, " + Camera.names[Camera.names.length - 1]);
					cameraName = String(Camera.names.length - 1);
				}
				else
				{
					trace("CameraService: Connecting specified camera, " + cameraName);
					cameraName = String(Camera.names.indexOf(cameraName));
				}
			}
			else
			{
				trace("CameraService: Connecting to first available camera, " + Camera.names[0]);
				cameraName = Camera.names[0];
			}
			
			camera = Camera.getCamera("0");
			camera.setMode(cameraWidth, cameraHeight, fps);
			camera.setQuality(0, 100);
			
			width = camera.width;
			height = camera.height;
			video = new Video(width, height);
			video.smoothing = true;
			video.attachCamera(camera);
			
			camera.addEventListener(Event.VIDEO_FRAME, newVideoFrame);
		}
		
		/**
		 * Deactivates the camera, allowing it to switch off.
		 */
		static public function pauseCamera():void
		{
			video.attachCamera(null);
		}
		
		/**
		 * Allows you to switch the camera on again, after using pauseCamera().
		 */
		static public function resumeCamera():void
		{
			video.attachCamera(camera);
		}
		
		/**
		 * New video data available.  Cached bitmapData is now invalid.
		 */
		static private function newVideoFrame(e:Event):void
		{
			cached = false;
			bitmapDataUpdated = true;
		}
		
		/**
		 * A reference to the current frame's bitmapData.  Changes to this object will affect the original.
		 * DO NOT dispose of this bitmapData!
		 *
		 * If you need to modify this image, clone it first and modify the clone.
		 */
		static public function get bitmapData():BitmapData
		{
			if (!cached)
			{
				if (!_bitmapData) setupBitmapData();
				
				if (clipRect)
				{
					camera.drawToBitmapData(sourceBitmapData);
					_bitmapData.copyPixels(sourceBitmapData, clipRect, point);
				}
				else
				{
					camera.drawToBitmapData(_bitmapData);
				}
				
				if (mirror) _bitmapData.draw(_bitmapData, horizontalFlipMatrix);
				
				cached = true;
			}
			
			bitmapDataUpdated = false;
			return _bitmapData;
		}
		
		static private function setupBitmapData():void
		{
			if (clipRect)
			{
				_bitmapData = new BitmapData(clipRect.width, clipRect.height, false, 0x000000);
				if (!sourceBitmapData) sourceBitmapData = new BitmapData(width, height, false, 0x000000);
				point = new Point();
			}
			else
			{
				_bitmapData = new BitmapData(width, height, false, 0x000000);
			}
			
			// Something crazy going on here.  It needs to be fixed.
			if (mirror && !horizontalFlipMatrix)
			{
				//horizontalFlipMatrix = new Matrix(-1, 0, 0, 1, _bitmapData.width, 0);
				horizontalFlipMatrix = new Matrix();
				horizontalFlipMatrix.scale(-1, 1);
				horizontalFlipMatrix.translate(_bitmapData.width, 0);
			}
		}
		
		/**
		 * If no cameras were found when initialised, this is false.
		 */
		static public function get cameraAvailable():Boolean
		{
			if (Camera.names.length == 0) return false;
			if (_cameraAvailable == false)
			{
				initCamera();
				if (camera) return true;
			}
			
			return false;
		}
	}

}