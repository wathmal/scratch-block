package cc.makeblock.mbot.ui.parts
{
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import cc.makeblock.mbot.uiwidgets.DynamicCompiler;
	import cc.makeblock.mbot.uiwidgets.errorreport.ErrorReportFrame;
	import cc.makeblock.mbot.uiwidgets.extensionMgr.ExtensionUtil;
	import cc.makeblock.media.MediaManager;
	import cc.makeblock.menu.MenuUtil;
	import cc.makeblock.menu.SystemMenu;
	import cc.makeblock.updater.AppUpdater;
	
	import extensions.ArduinoManager;
	import extensions.ConnectionManager;
	import extensions.DeviceManager;
	import extensions.ExtensionManager;
	import extensions.HIDManager;
	import extensions.SerialDevice;
	import extensions.SerialManager;
	import extensions.SocketManager;
	
	import org.aswing.AsWingUtils;
	
	import services.WebService;
	
	import translation.Translator;
	
	import util.ApplicationManager;
	import util.SharedObjectManager;
	
	public class TopSystemMenu extends SystemMenu
	{
		public function TopSystemMenu(stage:Stage, path:String)
		{
			super(stage, path);
			
			if(!ApplicationManager.sharedManager().isCatVersion){
				/*var helpMenu:NativeMenu = getNativeMenu().getItemByName("Help").submenu;
				helpMenu.removeItemAt(2);
				helpMenu.removeItemAt(1);
				helpMenu.removeItemAt(0);*/
			}
			
			getNativeMenu().getItemByName("File").submenu.addEventListener(Event.DISPLAYING, __onInitFielMenu);
			getNativeMenu().getItemByName("Edit").submenu.addEventListener(Event.DISPLAYING, __onInitEditMenu);
			getNativeMenu().getItemByName("Extensions").submenu.addEventListener(Event.DISPLAYING, __onInitExtMenu);
			getNativeMenu().getItemByName("Boards").submenu.addEventListener(Event.DISPLAYING, __onShowBoards);
			getNativeMenu().getItemByName("Connect").submenu.addEventListener(Event.DISPLAYING, __onShowConnect);
			getNativeMenu().getItemByName("Language").submenu.addEventListener(Event.DISPLAYING, __onShowLanguage);
			
			register("File", __onFile);
			register("Edit", __onEdit);
			register("Connect", __onConnect);
			register("Boards", __onSelectBoard);
//			register("Help", __onHelp);
			register("Manage Extensions", ExtensionUtil.OnManagerExtension);
			register("Restore Extensions", ExtensionUtil.OnLoadExtension);
			register("Clear Cache", ArduinoManager.sharedManager().clearTempFiles);
		}
		
		public function changeLang():void
		{
			MenuUtil.ForEach(getNativeMenu(), changeLangImpl);
		}
		
		private function changeLangImpl(item:NativeMenuItem):*
		{
			var index:int = getNativeMenu().getItemIndex(item);
			if(0 <= index && index < defaultMenuCount){
				return true;
			}
			if(item.name.indexOf("serial_") == 0){
				return;
			}
			var p:NativeMenuItem = MenuUtil.FindParentItem(item);
			if(p != null && p.name == "Extensions"){
				if(p.submenu.getItemIndex(item) > 2){
					return true;
				}
			}
			setItemLabel(item);
			if(item.name == "Boards"){
//				setItemLabel(item.submenu.getItemByName("Others"));
				return true;
			}
			if(item.name == "Language"){
				item = MenuUtil.FindItem(item.submenu, "set font size");
				setItemLabel(item);
				return true;
			}
		}
		
		private function setItemLabel(item:NativeMenuItem):void
		{
			var newLabel:String = Translator.map(item.name);
			if(item.label != newLabel){
				item.label = newLabel;
			}
		}
		
		private function __onFile(item:NativeMenuItem):void
		{
			switch(item.name)
			{
				case "New":
					WireMe.app.createNewProject();
					break;
				case "Load Project":
					WireMe.app.runtime.selectProjectFile();
					break;
				case "Save Project":
					WireMe.app.saveFile();
					break;
				case "Save Project As":
					WireMe.app.exportProjectToFile();
					break;
				case "Undo Revert":
					WireMe.app.undoRevert();
					break;
				case "Revert":
					WireMe.app.revertToOriginalProject();
					break;
				case "Import Image":
					MediaManager.getInstance().importImage();
					break;
				case "Export Image":
					MediaManager.getInstance().exportImage();
					break;
				case "Log Out":
					SharedObjectManager.sharedManager().setObject("isUserNotSet",true);
					break;
				case "Log In":
					WebService.getInstance().login();
					break;
			}
		}
		
		private function __onEdit(item:NativeMenuItem):void
		{
			switch(item.name){
				case "Undelete":
					WireMe.app.runtime.undelete();
					break;
				case "Hide stage layout":
					WireMe.app.toggleHideStage();
					break;
				case "Small stage layout":
					WireMe.app.toggleSmallStage();
					break;
				case "Turbo mode":
					WireMe.app.toggleTurboMode();
					break;
				case "Code mode":
					WireMe.app.changeToArduinoMode();
					break;
			}
			WireMe.app.track("/OpenEdit");
		}
		
		private function __onConnect(menuItem:NativeMenuItem):void
		{
			var key:String;
			if(menuItem.data){
				key = menuItem.data.@action;
			}else{
				key = menuItem.name;
			}
			if("upgrade_custom_firmware" == key){
				var panel:DynamicCompiler = new DynamicCompiler();
				panel.show();
				AsWingUtils.centerLocate(panel);
			}else{
				ConnectionManager.sharedManager().onConnect(key);
			}
		}
		
		private function __onShowLanguage(evt:Event):void
		{
			var languageMenu:NativeMenu = evt.target as NativeMenu;
			if(languageMenu.numItems <= 2){
				for each (var entry:Array in Translator.languages) {
					var item:NativeMenuItem = languageMenu.addItemAt(new NativeMenuItem(entry[1]), languageMenu.numItems-2);
					item.name = entry[0];
					item.checked = Translator.currentLang==entry[0];
				}
				languageMenu.addEventListener(Event.SELECT, __onLanguageSelect);
			}else{
				for each(item in languageMenu.items){
					if(item.isSeparator){
						break;
					}
					MenuUtil.setChecked(item, Translator.currentLang==item.name);
				}
			}
			try{
				var fontItem:NativeMenuItem = languageMenu.items[languageMenu.numItems-1];
				for each(item in fontItem.submenu.items){
					MenuUtil.setChecked(item, Translator.currentFontSize==int(item.label));
				}
			}catch(e:Error){
				
			}
		}
		
		private function __onLanguageSelect(evt:Event):void
		{
			var item:NativeMenuItem = evt.target as NativeMenuItem;
			if(item.name == "setFontSize"){
				Translator.setFontSize(int(item.label));
			}else{
				Translator.setLanguage(item.name);
			}
		}
		
		private function __onInitFielMenu(evt:Event):void
		{
			var menu:NativeMenu = evt.target as NativeMenu;
			
			MenuUtil.setEnable(menu.getItemByName("Undo Revert"), WireMe.app.canUndoRevert());
			MenuUtil.setEnable(menu.getItemByName("Revert"), WireMe.app.canRevert());
			
			WireMe.app.track("/OpenFile");
		}
		
		private function __onInitEditMenu(evt:Event):void
		{
			var menu:NativeMenu = evt.target as NativeMenu;
			MenuUtil.setEnable(menu.getItemByName("Undelete"), WireMe.app.runtime.canUndelete());
			MenuUtil.setChecked(menu.getItemByName("Hide stage layout"), WireMe.app.stageIsHided);
			MenuUtil.setChecked(menu.getItemByName("Small stage layout"), !WireMe.app.stageIsHided && WireMe.app.stageIsContracted);
			MenuUtil.setChecked(menu.getItemByName("Turbo mode"), WireMe.app.interp.turboMode);
			MenuUtil.setChecked(menu.getItemByName("Code mode"), WireMe.app.stageIsArduino);
			WireMe.app.track("/OpenEdit");
		}
		
		private function __onShowConnect(evt:Event):void
		{
			SocketManager.sharedManager().probe();
			HIDManager.sharedManager();
			
			var menu:NativeMenu = evt.target as NativeMenu;
			var subMenu:NativeMenu = new NativeMenu();
			
			var enabled:Boolean = WireMe.app.extensionManager.checkExtensionEnabled();
			var arr:Array = SerialManager.sharedManager().list;
			for(var i:int=0;i<arr.length;i++){
				var item:NativeMenuItem = subMenu.addItem(new NativeMenuItem(arr[i]));
				item.name = "serial_"+arr[i];
				item.enabled = enabled;
				item.checked = SerialDevice.sharedDevice().ports.indexOf(arr[i])>-1 && SerialManager.sharedManager().isConnected;
			}
			menu.getItemByName("Serial Port").submenu = subMenu;
			
		}
		
		private function __onSelectBoard(menuItem:NativeMenuItem):void
		{
			DeviceManager.sharedManager().onSelectBoard(menuItem.name);
		}
		
		private function __onShowBoards(evt:Event):void
		{
			var menu:NativeMenu = evt.target as NativeMenu;
			for each(var item:NativeMenuItem in menu.items){
				if(item.enabled){
					MenuUtil.setChecked(item, DeviceManager.sharedManager().checkCurrentBoard(item.name));
				}
			}
		}
		
		private var initExtMenuItemCount:int = -1;
		
		private function __onInitExtMenu(evt:Event):void
		{
			var menuItem:NativeMenu = evt.target as NativeMenu;
//			menuItem.removeEventListener(evt.type, __onInitExtMenu);
//			menuItem.addEventListener(evt.type, __onShowExtMenu);
			var list:Array = WireMe.app.extensionManager.extensionList;
			trace("on init ext");
			if(list.length==0){
				WireMe.app.extensionManager.copyLocalFiles();
				SharedObjectManager.sharedManager().setObject("first-launch",false);
			}
			if(initExtMenuItemCount < 0){
				initExtMenuItemCount = menuItem.numItems;
			}
			while(menuItem.numItems > initExtMenuItemCount){
				menuItem.removeItemAt(menuItem.numItems-1);
			}
			list = WireMe.app.extensionManager.extensionList;
//			var subMenu:NativeMenu = menuItem;
			for(var i:int=0;i<list.length;i++){
				trace(list[i].extensionName);
				var extName:String = list[i].extensionName;
				if(!canShowExt(extName)){
					continue;
				}
				var subMenuItem:NativeMenuItem = menuItem.addItem(new NativeMenuItem(Translator.map(extName)));
				subMenuItem.name = extName;
				subMenuItem.label = ExtensionManager.isMekeBlockExt(extName) ? "Makeblock" : extName;
				subMenuItem.checked = WireMe.app.extensionManager.checkExtensionSelected(extName);
				register(extName, __onExtensions);
			}
		}
		
		static private function canShowExt(extName:String):Boolean
		{
			var board:String = DeviceManager.sharedManager().currentBoard;
			var result:Boolean = true;
			switch(extName)
			{
				case "Makeblock":
					result = board.indexOf("orion") >= 0;
					break;
				case "mBot":
					result = board.indexOf("mbot") >= 0;
					break;
				case "UNO Shield":
					result = board.indexOf("shield") >= 0;
					break;
				case "BaseBoard":
					result = board.indexOf("baseboard") >= 0;
					break;
				case "PicoBoard":
					result = board.indexOf("picoboard") >= 0;
					break;
			}
			return result;
		}
		/*
		private function __onShowExtMenu(evt:Event):void
		{
			var menuItem:NativeMenu = evt.target as NativeMenu;
			var list:Array = WireMe.app.extensionManager.extensionList;
			for(var i:int=0;i<list.length;i++){
				var extName:String = list[i].extensionName;
				var subMenuItem:NativeMenuItem = menuItem.getItemAt(i+2);
				subMenuItem.checked = WireMe.app.extensionManager.checkExtensionSelected(extName);
			}
		}
		*/
		private function __onExtensions(menuItem:NativeMenuItem):void
		{
			WireMe.app.extensionManager.onSelectExtension(menuItem.name);
		}
		
	}
}