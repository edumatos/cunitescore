package unitescore { 
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.StatusEvent;
	import flash.external.ExternalInterface;
	import flash.display.LoaderInfo;
	import flash.display.Loader;
	import flash.net.LocalConnection;
	import flash.net.URLLoader;
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
		 * TextArea debug
		 */
		public var DEBUG:Boolean = false;
		
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
		private var logoClasses:Array = [ 
			{ mcclass:"MCkongregate", domain:"kongregate.com" } ,
			{ mcclass:"MCpepere", domain:"pepere.org" } ,
			{ mcclass:"MCbubblebox", domain:"bubblebox.com" } ,
			{ mcclass:"MCnewgrounds", domain:"ungrounded.net" } ,
			{ mcclass:"MCnonoba", domain:"nonoba.com" } ,
			{ mcclass:"MCmindjolt", domain:"mindjolt.com" } ,
			{ mcclass:"MCaddictinggames", domain:"addictinggames.com" } ,
			{ mcclass:"MCgamesgarden", domain:"games-garden.com" } ,
			{ mcclass:"MConemorelevel", domain:"onemorelevel.com" }
		];
		
		/**
		 * This category is used on portals that don't manage score categories.
		 * If your game don't use score categories, you do'nt need to bother with this.
		 */
		public var mainScoreCategory:String = "";
		
		/**
		 * The game name for ibProArcade score submition
		 */
		private var ibProArcadeGameName:String;
	
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
			
			if (DEBUG) {
				theroot.debug.text += "CUniteScoreAS3 url=" + url + "\n";
				theroot.debug.text += "CUniteScoreAS3 gameParams=\n";
				for (var p:String in gameParams) {
					theroot.debug.text += "     "+p+"="+gameParams[p]+"\n";
				}
			}
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
		 * Call this if you want to use ibProArcade scores.
		 * @param	gameName The game name on ibProArcade
		 */
		public function initIbProArcade(gameName:String):void {
			ibProArcadeGameName = gameName;
		}
		
		/**
		 * Call this method to submit the score. The method detect automatically on wich portal your game is hosted and call the corresponding API.
		 * @param	score : Score of the player
		 * @param	category : Category (example : "easy", "medium", "hard", "super hard", ...). Optional. If you use score categories, don't forget to call also sendScore(scoreVar) for portals that don't manage the score categories.
		 */
		public function sendScore(score : int, category : String = "") : void {
			
			//Local vars that can be used by portal methods
			var urlRequest:URLRequest;
			var urlVars:URLVariables;
			var urlLoader:URLLoader;
			var loader:Loader;
			
			if (DEBUG) theroot.debug.text += "sendScore score=" + score + " category=" + category + "\n";

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
						loader = new Loader();
						loader.contentLoaderInfo.addEventListener ( Event.COMPLETE, bubbleboxComplete );
						trace("gameParams.bubbleboxApiPath=" + gameParams.bubbleboxApiPath + " gameParams.bubbleboxGameID=" + gameParams.bubbleboxGameID);
						urlRequest = new URLRequest( gameParams.bubbleboxApiPath);
						urlVars = new URLVariables();
						urlVars.bubbleboxGameID = gameParams.bubbleboxGameID;
						urlRequest.method = URLRequestMethod.GET;
						urlRequest.data = urlVars;
						
						loader.load ( urlRequest );
						
						bubbleboxGUI = loader;
					}
				}
			} else if (url.indexOf("games-garden.com") > -1) {
				//games-garden.com (derived from ibProArcade system)
				if ((gameParams.isUser == 1) && (gameParams.gname)) {
					urlRequest = new URLRequest("index.php?act=Arcade&do=newscore");
					urlVars = new URLVariables();
					urlVars.gname = gameParams.gname;
					urlVars.gscore = score;
					urlRequest.method = URLRequestMethod.POST;
					urlRequest.data = urlVars;
					urlLoader = new URLLoader();
					urlLoader.load(urlRequest);
				}
			} else if (ibProArcadeGameName != null) {
				urlRequest = new URLRequest("index.php?act=Arcade&do=newscore");
				urlVars = new URLVariables();
				urlVars.gname = ibProArcadeGameName; //ibProArcadeGameName must be initialized with the method initIbProArcade
				urlVars.gscore = score;
				urlRequest.method = URLRequestMethod.POST;
				urlRequest.data = urlVars;
				urlLoader = new URLLoader();
				urlLoader.load(urlRequest);
				
				if (DEBUG) theroot.debug.text += "request index.php?act=Arcade&do=newscore POST gscore=" + score + " gname=" + ibProArcadeGameName+"\n";
			} else if ((mochiadsGameID != null) && (mochiadsBoardID != null)) {
				// Default score submittion is mochiads leaderboards
				if (category == mainScoreCategory) {
					MochiScores.showLeaderboard( { boardID: mochiadsBoardID, score: score } );
				}
			}
		}
		
		
		/**
		 * Show a portal logo (if assets have been embedded in your game).
		 * If you don't want to feature the logo of a portal on your game, just remove / don'yt embed the corresponding asset int your game.
		 * @param	layout Position of the log (TOP, TOP_RIGHT, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, LEFT, TOP_LEFT, CENTER)
		 * @param	duration Duration in milliseconds (minimum is 2 seconds)
		 */
		public function showLogo(layout:int = 3 /*CUniteScoreAS3.BOTTOM_RIGHT*/, duration:int = 5000, urlOutFilters:Array = null, urlInFilters:Array = null):void {
			//If the log is already displayed, don't do anything
			if (logo_mc != null) return;
			if (duration < 2000) duration = 2000; //min 2 seconds
			var logoClass:Class;
			var i:int;
			for (i = logoClasses.length - 1; i >= 0; i--) {
				if (url.indexOf(logoClasses[i].domain) >= 0) {
					// Each entry in the array logoClasses define a 'mcclass' property (String), anme of the logo MovieClip class.
					// All logo classes must be in the package unitescore
					logoClass = Class(getDefinitionByName("unitescore." + logoClasses[i].mcclass));
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

		/**
		 * Manage logo display (fade in fade out) on every frame
		 * TODO : check the logo is still on top of the root MovieClip.
		 * @param	ev
		 */
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
					// theroot.loaderInfo.height and theroot.loaderInfo.width are not always ready on the first frame of the game.
					// We need this info to display the logo on the right position.
					// So we wait here and check on every loop taht loaderInfo.width and loaderInfo.height are available.
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
			var loader:Loader = new Loader();
			if (url.indexOf("mindjolt.com") >= 0) {
				// manually load the API
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, mindJoltComplete);
				loader.load(new URLRequest(gameParams.mjPath || "http://static.mindjolt.com/api/as3/scoreapi_as3_local.swf"));
				theroot.addChild(loader);
			} else if (url.indexOf("kongregate.com") >= 0) {
				// The API path. The debug version ("shadow" API) will load if testing locally.
				loader.contentLoaderInfo.addEventListener ( Event.COMPLETE, kongregateComplete );
				loader.load ( new URLRequest( gameParams.api_path || "http://www.kongregate.com/flash/API_AS3_Local.swf") );
				theroot.addChild ( loader );
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
	}
}