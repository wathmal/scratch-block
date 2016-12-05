package cc.makeblock.util
{
	import flash.display.BitmapData;
	import flash.display.PNGEncoderOptions;
	import flash.display.StageQuality;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import flash.utils.ByteArray;

	public class FileUtil
	{
		static private const fs:FileStream = new FileStream();
		
		static public function LoadFile(path:String):String
		{
			return ReadString(File.applicationDirectory.resolvePath(path));
		}
		
		static public function ReadBytes(file:File):ByteArray
		{
			var result:ByteArray = new ByteArray();
			fs.open(file, FileMode.READ);
			fs.readBytes(result);
			fs.close();
			return result;
		}
		
		static public function ReadString(file:File):String
		{
			fs.open(file, FileMode.READ);
			var result:String = fs.readUTFBytes(fs.bytesAvailable);
			fs.close();
			return result;
		}
		
		static public function WriteString(file:File, str:String):void
		{
			fs.open(file, FileMode.WRITE);
			fs.writeUTFBytes(str);
			fs.close();
		}
		
		static public function WriteBytes(file:File, bytes:ByteArray):void
		{
			fs.open(file, FileMode.WRITE);
			fs.writeBytes(bytes);
			fs.close();
		}
		
		static public function PrintScreen():void
		{
			var scale:Number = 3;
			var bmd:BitmapData = new BitmapData(
				WireMe.app.stage.stageWidth*scale,
				WireMe.app.stage.stageHeight*scale,true
			);
			var matrix:Matrix = new Matrix();
			matrix.scale(scale,scale);
			WireMe.app.scaleX = WireMe.app.scaleY = scale;
			bmd.drawWithQuality(WireMe.app, matrix, null, null, null, false, StageQuality.BEST);
			WireMe.app.scaleX = WireMe.app.scaleY = 1;
			var jpeg:ByteArray = bmd.encode(bmd.rect, new PNGEncoderOptions());
			bmd.dispose();
			var now:Date = new Date();
			var path:String = "screen_"+Math.floor(now.time)+".png";
			var fileScreen:File = File.desktopDirectory.resolvePath(path);
			FileUtil.WriteBytes(fileScreen, jpeg);
			jpeg.clear();
		}
	}
}