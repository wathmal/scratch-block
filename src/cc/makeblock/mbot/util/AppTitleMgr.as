package cc.makeblock.mbot.util
{
	import flash.display.NativeWindow;
	import flash.events.Event;

	import translation.Translator;

	import util.SharedObjectManager;

	public class AppTitleMgr
	{
		static public const Instance:AppTitleMgr = new AppTitleMgr();

		private var window:NativeWindow;
		private var strList:Array;

		public function AppTitleMgr()
		{
		}

		public function init(window:NativeWindow):void
		{
			this.window = window;
			strList = [window.title];

			Translator.regChangeEvt(__onLangChanged, false);
			setConnectInfo(null);
		}

		private function __onLangChanged(evt:Event):void
		{
			updateTitle();
		}

		public function setConnectInfo(info:String):void
		{
			strList[1] = info;
			updateTitle();
		}

		public function setProjectModifyInfo(isModified:Boolean):void
		{
			strList[2] = isModified;
			updateTitle();
		}

		public function updateTitle():void
		{
			if(!window.closed)
			{
				window.title = getTitleStr();
			}
		}

		private function getTitleStr():String
		{
			var result:String = strList[0];

            result += " - " + SharedObjectManager.sharedManager().getObject("username");

			var str:String = strList[1];
			if(Boolean(str)){
				str = Translator.map(str) + " " + Translator.map("connected");
			}else{
				str = Translator.map("disconnected");
			}
			result += " - " + str;
			result += " - " + Translator.map(strList[2] ? "not saved" :  "saved");

			return result;
		}
	}
}