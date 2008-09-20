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
	import unitescore.mochi.*;
	
	/**
	 * Use in the first frame of your game root MovieClip:
	 * import unitescore.*;
	 * var scoreSubmitter:CUniteScoreAS3 = new CUniteScoreAS3(this);
	 */
	public class CUniteScoreAS3 {
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
		
		private var theroot:MovieClip;
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
		function CUniteScoreAS3(theroot:MovieClip,urlDebug:String=null,paramsDebug:Object=null) {
			this.theroot = theroot;
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
						//theroot.addChild ( urlLoader );
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
		
		//***************************************
		//* Private methods
		//***************************************

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
			//TODO check it is on top on every frame
			try {
				theroot.removeChild(bubbleboxGUI);
			} catch (e:Error) {
			}
			theroot.addChild(bubbleboxGUI);
			bubbleboxGUI.x = theroot.stage.stageWidth / 2 - 200;
			bubbleboxGUI.y = theroot.stage.stageHeight / 2 - 100;
			
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