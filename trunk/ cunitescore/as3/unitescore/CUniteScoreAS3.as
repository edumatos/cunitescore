package unitescore { 
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.StatusEvent;
	import flash.external.ExternalInterface;
	import flash.display.LoaderInfo;
	import flash.display.Loader;
	import flash.net.LocalConnection;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.utils.getTimer;
	import flash.utils.getDefinitionByName;
	import unitescore.mochi.*;
	import unitescore.nonoba.*;
	
	
	/**
	 * Use in the first frame of your game root MovieClip:
	 * import unitescore.*;
	 * var scoreSubmitter:CUniteScoreAS3 = new CUniteScoreAS3(this);
	 */
	public class CUniteScoreAS3 {
		
		/**
		 * Logo layouts
		 */
		static public var TOP:int = 0;
		static public var TOP_RIGHT:int = 1;
		static public var RIGHT:int = 2;
		static public var BOTTOM_RIGHT:int = 3;
		static public var BOTTOM:int = 4;
		static public var BOTTOM_LEFT:int = 5;
		static public var LEFT:int = 6;
		static public var TOP_LEFT:int = 7;
		static public var CENTER:int = 8;
		
		/**
		 * Logo vars
		 */
		private var logoDuration:int;
		private var logoStartStamp:int;
		private var logoLayout:int;
		private var logoSet:Boolean;
		private var logo_mc:MovieClip;
		private var logoKeys:Array = [ 
			{ key:"kongregate", domain:"kongregate.com" } ,
			{ key:"pepere", domain:"pepere.org" } ,
			{ key:"bubblebox", domain:"bubblebox.com" } ,
			{ key:"newgrounds", domain:"newgrounds.com" } ,
			{ key:"nonoba", domain:"nonoba.com" } ,
			{ key:"mindjolt", domain:"mindjolt.com" } ,
			{ key:"addictinggames", domain:"addictinggames.com" } ,
			{ key:"onemorelevel", domain:"onemorelevel.com" }
		];
		
		/**
		 * This category is used on portals that don't manage score categories.
		 * If your game don't use score categories, you do'nt need to bother with this.
		 */
		public var mainScoreCategory:String = "";
		
		/**
		 * Mochiads parameters
		 */
		private var mochiadsGameID:String, mochiadsBoardID:String;
		
		/**
		 * The local connection object
		 */
		private var sendLocalConnection:LocalConnection = new LocalConnection();
		
		public static var theroot:MovieClip;
		private var mindJoltAPI:Object;
		private var kongregateAPI:Object;
		private var bubbleboxGUI:DisplayObject;
		private var pendingScore:int;
		private var url:String;
		private var gameParams:Object; //parameters of the swf url (game.swf?myvar1=XXX&myvar2=YYY)

		/**
		 * Constructor
		 * @param	theroot : root Movieclip
		 * @param	urlDebug : To simulate a swf hosting url. Exple "kongregate.com".
		 */
		function CUniteScoreAS3(root:MovieClip,urlDebug:String=null,paramsDebug:Object=null) {
			CUniteScoreAS3.theroot = root;
			//get the hosting url
			if (urlDebug == null) url = theroot.stage.loaderInfo.url;
			else url = urlDebug;
			// get the parameters passed into the game
			if (paramsDebug == null) gameParams = LoaderInfo(theroot.loaderInfo).parameters;
			else gameParams = paramsDebug;
			// init local connection listener
			sendLocalConnection.addEventListener(StatusEvent.STATUS, onConnStatus);
			init();
		}
		
		//***************************************
		//* Public methods
		//***************************************
		
		/**
		 * If your game use score categories, call this method to set the category that will be used to submit the score on portals that don't manage score categories.
		 * Exple : If you have 3 categories "easy", "medium", and "hard", you can call setMainScoreCategory("hard"). The score submitted on portals without score categories, will be the score of the "hard" category.
		 * If you don't call this method, the default main score category is "".
		 * If your game don't use score categories, you do'nt need to bother with this.
		 * @param	category
		 */
		public function setMainScoreCategory(category:String):void {
			mainScoreCategory = category;
		}
		
		/**
		 * Call this if you want to use mochiads leaderboard.
		 * http://mochiland.com/articles/introducing-mochiads-leaderboards
		 * @param	gameid The mochiads game id 
		 * @param	boardid The leaderboard id that you created on mochiads site for your game
		 */
		public function initMochiAdsLeaderboard(gameid:String,boardid:String):void {
			mochiadsGameID = gameid;
			mochiadsBoardID = boardid;
			var clip:MovieClip = new MovieClip();
			theroot.addChild(clip);
			MochiServices.connect(mochiadsGameID , clip);
		}
		
		/**
		 * Call this method to submit the score. The method detect automatically on wich portal your game is hosted and call the corresponding API.
		 * @param	score : Score of the player
		 * @param	category : Category (example : "easy", "medium", "hard", "super hard", ...). Optional. If you use score categories, don't forget to call also sendScore(scoreVar) for portals that don't manage the score categories.
		 */
		public function sendScore(score : int, category : String = "") : void {
			if (url.indexOf("pepere.org") >= 0) {
				if (category == mainScoreCategory) ExternalInterface.call("saveGlobalScore", score);
			} else if (url.indexOf("mindjolt.com") >= 0) {
				if (category == mainScoreCategory) mindJoltAPI.servicesubmitScore(score);
				else mindJoltAPI.servicesubmitScore(score, category);
			} else if (url.indexOf("kongregate.com") >= 0) {
				if (category == mainScoreCategory) kongregateAPI.scores.submit(score);
				else kongregateAPI.scores.submit(score, category);
			} else if (url.indexOf("nonoba.com") >= 0) {
				var nonoba_key:String;
				//On nonoba.com you have to create a highscore for your game. Set the key to "totalscores" for your main score.
				if (category == mainScoreCategory) {
					nonoba_key = "totalscores";
				} else {
					//remove ' ' and '-' characters from the category name
					nonoba_key = category.split(' ').join('').split('-').join('').toLowerCase();
				}
				NonobaAPI.SubmitScore(theroot.stage, nonoba_key, score, function(response:String){
					switch(response){
						case NonobaAPI.SUCCESS:{ trace("The Nonoba score was submitted successfully"); break; }
						case NonobaAPI.NOT_LOGGED_IN: { trace("The Nonoba user is not logged in"); break; }
						case NonobaAPI.ERROR: { trace("A Nonoba error occurred."); break; }
					}
				});
			} else if (url.indexOf("bubblebox.com") >= 0) {
				if (category == mainScoreCategory) {
					if (bubbleboxGUI != null) showBubbleboxScoreGUI(score);
					else {
						pendingScore = score; // to be used once the bubblebox component is loaded
						var urlLoader:Loader = new Loader();
						urlLoader.contentLoaderInfo.addEventListener ( Event.COMPLETE, bubbleboxComplete );
						trace("gameParams.bubbleboxApiPath=" + gameParams.bubbleboxApiPath + " gameParams.bubbleboxGameID=" + gameParams.bubbleboxGameID);
						var request:URLRequest = new URLRequest( gameParams.bubbleboxApiPath);
						var vars:URLVariables = new URLVariables();
						vars.bubbleboxGameID = gameParams.bubbleboxGameID;
						request.method = URLRequestMethod.GET;
						request.data = vars;
						
						urlLoader.load ( request );
						
						bubbleboxGUI = urlLoader;
					}
				}
			} else if ((mochiadsGameID != null) && (mochiadsBoardID != null)) {
				// Default score submittion is mochiads leaderboards
				if (category == mainScoreCategory) {
					MochiScores.showLeaderboard( { boardID: mochiadsBoardID, score: score } );
				}
			}
		}
		
		
		/**
		 * Show a portal logo (if assets have been embedded in your game).
		 * Filters arrays contains String values like "mindjolt", "pepere", "bubblebox", "kongregate" etc...
		 * @param	layout Position of the log (TOP, TOP_RIGHT, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, LEFT, TOP_LEFT, CENTER)
		 * @param	duration Duration in milliseconds (minimum is 2 seconds)
		 * @param	urlOutFilters List of portals you don't want to dislpay the logo.
		 * @param	urlInFilters List of portals you want to dislpay the logo.
		 */
		public function showLogo(layout:int = 3 /*CUniteScoreAS3.BOTTOM_RIGHT*/, duration:int = 5000, urlOutFilters:Array = null, urlInFilters:Array = null):void {
			//If the log is already displayed, don't do anything
			if (logo_mc != null) return;
			if (duration < 2000) duration = 2000; //min 2 seconds
			var logoClass:Class;
			var i:int;
			for (i = logoKeys.length - 1; i >= 0; i--) {
				logoKeys
				if (url.indexOf(logoKeys[i].domain) >= 0) {
					if (filterOK(logoKeys[i].key, urlOutFilters, urlInFilters)) {
						// Each entry in the array logoKeys define a 'key' property (String). The logo MovieClip has to be linked to a class called "unistescore.MC[the logo key defined in the logoKeys array]".
						// Exple unitescore.kongregateMC , unitescore.bubbleboxMC etc...
						logoClass = Class(getDefinitionByName("unitescore.MC" + logoKeys[i].key));
					}
				}
			}
			
			//A logo class has been found, we have a log for this portal.
			if (logoClass) {
				//Embed in try catch in case the logo is not a MovieClip ?
				try {
					//trace("logoClass=" + logoClass);
					logo_mc = MovieClip(new logoClass());
					logoDuration = duration;
					logoLayout = layout;
					logoSet = false;
					logoStartStamp = getTimer();
					logo_mc.alpha = 0;
					logo_mc.addEventListener(Event.ENTER_FRAME, logoLoop);
				} catch (e:Error) {
					logo_mc = null;
					trace("Logo instance creation failed : " + e);
				}
			}
		}
		
		
		//***************************************
		//* Private methods
		//***************************************

		private function logoLoop(ev:Event):void {
			if (getTimer() - logoStartStamp > logoDuration) {
				logo_mc.removeEventListener(Event.ENTER_FRAME, logoLoop);
				try {
					theroot.removeChild(logo_mc);
				} catch (e:Error) {
					trace("Logo remove error : " + e);
				}
			} else {
				if (!logoSet) {
					// theroot.loaderInfo.height and theroot.loaderInfo.width are not always ready on the first frame; 
					try {
						if ( (logoLayout == TOP_LEFT) || (logoLayout == TOP) || (logoLayout == TOP_RIGHT) ) {
							logo_mc.y = 10;
						} else if ( (logoLayout == BOTTOM_LEFT) || (logoLayout == BOTTOM) || (logoLayout == BOTTOM_RIGHT)) {
							logo_mc.y = theroot.loaderInfo.height - logo_mc.height - 10;
						} else if (logoLayout == CENTER) {
							logo_mc.y = theroot.loaderInfo.height/2 - logo_mc.height/2;
						}
						
						if ( (logoLayout == TOP_LEFT) || (logoLayout == LEFT) || (logoLayout == BOTTOM_LEFT) ) {
							logo_mc.x = 10;
						} else if ( (logoLayout == TOP_RIGHT) || (logoLayout == RIGHT) || (logoLayout == BOTTOM_RIGHT)) {
							logo_mc.x = theroot.loaderInfo.width - logo_mc.width - 10;
						} else if (logoLayout == CENTER) {
							logo_mc.x = theroot.loaderInfo.width/2 - logo_mc.width/2;
						}
						//show the log on top
						theroot.addChild(logo_mc);
						logoSet = true;
						logoStartStamp = getTimer();
					} catch (e:Error) {
						trace("Logo position failed : " + e);
					}
				} else {
					if (getTimer() - logoStartStamp > logoDuration - 1000) {
						if (logo_mc.alpha > 0) {
							logo_mc.alpha = (logoStartStamp + logoDuration - getTimer()) / 1000; if (logo_mc.alpha <= 0) logo_mc.alpha = 0;
						}
					} else {
						if (logo_mc.alpha < 1) {
							logo_mc.alpha = (getTimer() - logoStartStamp) / 1000; if (logo_mc.alpha >= 1) logo_mc.alpha = 1;
						}
					}
				}
			}
		}
		

		
		/**
		 * Called by the constructor.
		 */
		private function init():void {
			var urlLoader:Loader = new Loader();
			if (url.indexOf("mindjolt.com") >= 0) {
				// manually load the API
				urlLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, mindJoltComplete);
				urlLoader.load(new URLRequest(gameParams.mjPath || "http://static.mindjolt.com/api/as3/scoreapi_as3_local.swf"));
				theroot.addChild(urlLoader);
			} else if (url.indexOf("kongregate.com") >= 0) {
				// The API path. The debug version ("shadow" API) will load if testing locally.
				urlLoader.contentLoaderInfo.addEventListener ( Event.COMPLETE, kongregateComplete );
				urlLoader.load ( new URLRequest( gameParams.api_path || "http://www.kongregate.com/flash/API_AS3_Local.swf") );
				theroot.addChild ( urlLoader );
			}
		}
		
		/**
		 * Mindjolt component loaded
		 * @param	e
		 */
		private function mindJoltComplete ( e:Event ):void {
			mindJoltAPI=e.target.content;
			mindJoltAPI.service.connect();
			trace ("[MindJoltAPI] service manually loaded");
		}
		
		/**
		 * Kongregate component loaded
		 * @param	e
		 */
		private function kongregateComplete ( e:Event ):void {
			// Save Kongregate API reference
			kongregateAPI = e.target.content;
			// Connect
			kongregateAPI.services.connect();
			trace ( "\n" + kongregateAPI.services + "\n" + kongregateAPI.user + "\n" + kongregateAPI.scores + "\n" + kongregateAPI.stats );
		}
		
		/**
		 * Bubblebox component loaded
		 * @param	e
		 */
		private function bubbleboxComplete ( e:Event ):void {
			trace ("[bubblebox API] bubbleboxComplete");
			//bubbleboxGUI = e.currentTarget;
			showBubbleboxScoreGUI(pendingScore);
		}
		
		/**
		 * Show the bubblebox username input for score submittion
		 * @param	score
		 */
		private function showBubbleboxScoreGUI ( score:int ):void {
			trace ("[bubblebox API] showBubbleboxScoreGUI");
			//Keep the GUI on TOP
			//TODO check the GUI is on top on every frame
			try {
				theroot.removeChild(bubbleboxGUI);
			} catch (e:Error) {
			}
			theroot.addChild(bubbleboxGUI);
			
			bubbleboxGUI.x = theroot.loaderInfo.width/2 - 200;
			bubbleboxGUI.y = theroot.loaderInfo.height/2 - 100;
			
			try {
				sendLocalConnection.send("bubbleboxRcvApi" + gameParams.bubbleboxGameID, "sendScore", score);
			} catch (error:ArgumentError) {
			}
		}
		
		private function onConnStatus(event:StatusEvent):void {
			switch (event.level) {
				case "status":
					trace("LocalConnection.send() succeeded");
					break;
				case "error":
					trace("LocalConnection.send() failed");
					break;
			}
		}
		
		/**
		 * Check if the key word is OK with the fileters.
		 * If the key is in urlOutFilters, returns false.
		 * Else If the urlInFilters is not null and key is in urlInFilters, return false
		 * Else returns true
		 * @param	key
		 * @param	iutFilters
		 * @param	inFilters
		 * @return
		 */
		private function filterOK(key:String, outFilters:Array, inFilters:Array):Boolean {
			var i:int;
			if (outFilters != null) {
				for (i = outFilters.length - 1; i >= 0; i--) {
					if (outFilters[i].indexOf(key) >= 0) {
						//the key is in the outFilters
						return false;
					}
				}
			}
			if (inFilters != null) {
				for (i = inFilters.length - 1; i >= 0; i--) {
					if (inFilters[i].indexOf(key) >= 0) {
						//the key is in the inFilters
						return true;
					}
				}
				//the key is not in inFilters
				return false;
			}
			return true;
		}
	}
}