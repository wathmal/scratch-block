package services
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import cc.makeblock.mbot.util.AppTitleMgr;
	
	import uiwidgets.DialogBox;
	
	import util.JSON;
	import util.SharedObjectManager;

	public class WebService
	{
		private static var _instance:WebService;

		public static function getInstance():WebService
		{
			if(_instance==null){
				_instance = new WebService();
			}
			return _instance;
		}
		
		public function login():void
		{
			trace("user not set");
			var dBox:DialogBox = new DialogBox();
			
			dBox.addTitle("please login");
			dBox.addField("username", 100, "");
			dBox.addPasswordField("password", 100, "");			
			dBox.addButton("login",function(): void{
				trace("logging in: "+ dBox.getField("username"));
				getJwt(dBox.getField("username"),dBox.getField("password"));
			});
			dBox.addButton("Cancel", function onCancel():void {
				dBox.cancel();
			});
			dBox.showOnStage(WireMe.app.stage);
			dBox.fixLayout();
		}
		
		/**
		 * Login API call
		 */
		private function getJwt(username:String, password:String):void
		{
			var user:Object = new Object();
			user.username = username;
			user.pass = password;
			
			var request:URLRequest = new URLRequest();
			request.url = "http://wireme.projects.mrt.ac.lk/api/login";
			request.contentType = "multipart/form-data";
			request.method = URLRequestMethod.POST;
			
			request.data = util.JSON.stringify(user);
			var reponseData:Object;
			request.requestHeaders = [new URLRequestHeader("Accept", "application/json"),
				new URLRequestHeader("Content-Type", "application/json")];
			var postLoader:URLLoader = new URLLoader();
			postLoader.dataFormat = URLLoaderDataFormat.BINARY;
			
			postLoader.addEventListener(Event.COMPLETE, function (e:Event):void {
				reponseData = util.JSON.parse(URLLoader(e.target).data.toString());
				auth(reponseData,username, password);
			});
			
			postLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function (e:Event):void {
				trace("SECURITY_ERROR: " + e);
				reponseData = util.JSON.parse(URLLoader(e.target).data.toString());
				auth(reponseData,username, password);
			});
			postLoader.addEventListener(IOErrorEvent.IO_ERROR, function (e:Event):void {
				trace("IO_ERROR: " + e);
				reponseData = util.JSON.parse(URLLoader(e.target).data.toString());
				auth(reponseData,username, password);
			});
			
			try {
				postLoader.load(request);
			}
			catch (e:Error) {
				trace("Unable to Log in: " +e);
			}
			
		}
		
		private function auth(returnData:Object,username:String, password:String):void
		{
			var dialog:DialogBox;
			if(returnData!=null && returnData.code == 200){
				
				SharedObjectManager.sharedManager().setObject("token",returnData.token);
				trace("In logging in, token=: "+returnData.token);
				SharedObjectManager.sharedManager().setObject("isUserNotSet",false);
				SharedObjectManager.sharedManager().setObject("username",username);
				SharedObjectManager.sharedManager().setObject("password",password);
				
				WireMe.app.scriptsPart.showArduinoCode();
				
				dialog= new DialogBox();
				dialog.addTitle("Login");
				dialog.addText("User Logged in Successfully!");
				dialog.addButton("OK", function onCancel():void {
					dialog.cancel();
				});
				dialog.showOnStage(WireMe.app.stage);
				AppTitleMgr.Instance.updateTitle();
			}
			else{
//			login failed
				login();
				SharedObjectManager.sharedManager().setObject("isUserNotSet",true);
				dialog= new DialogBox();
				dialog.addTitle("Login");
				dialog.addText("Login Failed!");
				dialog.addButton("OK", function onCancel():void {
					dialog.cancel();
				});
				dialog.showOnStage(WireMe.app.stage);
				
			}	
		}
		
		public function sendWidgets(url:String,data:String):void
		{
			//		post request
			var request:URLRequest = new URLRequest();
			request.url = url;
			request.contentType = "multipart/form-data";
			request.method = URLRequestMethod.POST;
			request.data = data;
			
			var reponseData:Object;
			
			request.requestHeaders = [new URLRequestHeader("Accept", "application/json"),
				new URLRequestHeader("Content-Type", "application/json")];
			
			var postLoader:URLLoader = new URLLoader();
			postLoader.dataFormat = URLLoaderDataFormat.BINARY;
			var dialog:DialogBox;
			postLoader.addEventListener(Event.COMPLETE, function (e:Event):void {
				trace("Send data successfully! " + e);
				reponseData = util.JSON.parse(URLLoader(e.target).data.toString());
				dialog= new DialogBox();
				dialog.addTitle("Website Deployment!");
				dialog.addText("Widgets Published Successfully!");
				dialog.addButton("OK", function onCancel():void {
					dialog.cancel();
				});
				dialog.showOnStage(WireMe.app.stage);
			});
			
			postLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function (e:Event):void {
				trace("SECURITY_ERROR: " + e);
				//					throw new Error(e);
			});
			postLoader.addEventListener(IOErrorEvent.IO_ERROR, function (e:Event):void {
				trace("IO_ERROR: " + e);
				reponseData=null;
				dialog = new DialogBox();
				dialog.addTitle("Website Deployment!");
				dialog.addText("Widgets Published Failed!\n Please Try again!");
				dialog.addButton("OK", function onCancel():void {
					dialog.cancel();
				});
				dialog.showOnStage(WireMe.app.stage);
				//					throw new Error(e);
			});
			
			try {
				postLoader.load(request);
			}
			catch (e:Error) {
				trace("Unable to POST Widgets: " +e);
			}
		}
		
		public function sendGetRequest(url:String):Object
		{
			var request:URLRequest = new URLRequest();
			request.url = url;
			request.method = URLRequestMethod.GET;
			var data:URLVariables = new URLVariables();
			data.token=SharedObjectManager.sharedManager().getObject("token");
			request.data = data;			
			var reponseData:Object;
			
			var loader:URLLoader = new URLLoader();
			
			loader.addEventListener(Event.COMPLETE, function (e:Event):void {
				trace("Send data successfully! " + e);
				reponseData = util.JSON.parse(URLLoader(e.target).data.toString());
			});
			
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function (e:Event):void {
				trace("SECURITY_ERROR: " + e);
				reponseData=null;
			});
			loader.addEventListener(IOErrorEvent.IO_ERROR, function (e:Event):void {
				trace("IO_ERROR: " + e);
				reponseData=null;
			});
			
			try {
				
				loader.load(request);
				return reponseData;
			}
			catch (e:Error) {
				trace("Unable to GET: " +e);
				return null;
			}
			
		}
		
	}
}