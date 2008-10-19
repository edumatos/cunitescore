/**
 * CUnisScoreAS3.as
 * AS3 submition score on major game portals
 * From an original idea by Badim (badim.ru)
 *
 * *************************
 * Basic use :
 * *************************
 * 
 * //In root Frame 1 :
 * import unitescore.*;
 * var scoreSubmitter:CUniteScoreAS3 = new CUniteScoreAS3(this);
 * 
 * //Optional init, XXX = mochiadID, YYY = boardID, ZZZ = game name.
 * scoreSubmitter.initMochiAdsLeaderboard("XXX","YYY");
 * 
 * //In game over :
 * scoreSubmitter.sendScore(myScoreVar);
 * 
 */

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
	import flash.net.navigateToURL;
	import flash.events.Event;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.text.TextField;
	import flash.utils.getTimer;
	import flash.utils.getDefinitionByName;
	import flash.utils.Timer;
	import unitescore.mochi.*;
	import unitescore.nonoba.*;

	
	public class CUniteScoreAS3 {
		
		/**
		 * Debug TextField.
		 */
		public var DEBUGFIELD:TextField;
		
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
			{ mcclass:"MCnewgrounds", domain:"ungrounded.net" } , //newgrounds games are hosted on ungrounded.net
			{ mcclass:"MCnonoba", domain:"nonoba.com" } ,
			{ mcclass:"MCmindjolt", domain:"mindjolt.com" } ,
			{ mcclass:"MCaddictinggames", domain:"addictinggames.com" } ,
			{ mcclass:"MCgamesgarden", domain:"games-garden.com" } ,
			{ mcclass:"MCgamegarage", domain:"gamegarage.co.uk" } ,
			{ mcclass:"MCgameshot", domain:"gameshot.org" } ,
			{ mcclass:"MCgamebrew", domain:"gamebrew.com" } ,
			{ mcclass:"MCminijuegos", domain:"72.36.157." } ,
			{ mcclass:"MCminijuegos", domain:"72.232." } ,
			{ mcclass:"MConemorelevel", domain:"onemorelevel.com" }
		];

		/**
		 * Score parameters by domain
		 */
		private var scoreParams:Array = [ 
			{ domain:"kongregate.com", GUI:false, needUrlVars:["api_path"] } ,
			{ domain:"pepere.org", GUI:false, needUrlVars:[] } ,
			{ domain:"jeuxgratuits.net", GUI:false, needUrlVars:[] } ,
			{ domain:"bubblebox.com", GUI:true, needUrlVars:["bubbleboxGameID","bubbleboxApiPath"] } ,
			{ domain:"gamegarage.co.uk", GUI:true, needUrlVars:["game_id","gamegarageApiPath"] } ,
			{ domain:"nonoba.com", GUI:false, needUrlVars:[] } ,
			{ domain:"mindjolt.com", GUI:false, needUrlVars:["mjPath"] } ,
			{ domain:"gr8games.eu", GUI:false, needUrlVars:["gr8games_api"] } ,
			{ domain:"e-gierki.com", GUI:false, needUrlVars:["gr8games_api"] } ,
			{ domain:"gamebrew.com", GUI:false, needUrlVars:[] } ,
			{ domain:"games-garden.com", GUI:true, needUrlVars:["isUser","gname"] } //not really powered by GUI, but a score submission is reloading the page
		];
		
		/**
		 * This category is used on portals that don't manage score categories.
		 * If your game don't use score categories, you do'nt need to bother with this.
		 */
		public var mainScoreCategory:String = "";
		
		/**
		 * The game name for ibProArcade score submition
		 */
		//private var ibProArcadeGameName:String;
	
		/**
		 * Mochiads parameters
		 */
		private var mochiadsGameID:String, mochiadsBoardID:String;
		
		/**
		 * The local connection object
		 */
		private var sendLocalConnection:LocalConnection = new LocalConnection();
		
		public static var theroot:MovieClip;
		private var initTimer:Timer;
		private var mindJoltAPI:Object;
		private var kongregateAPI:Object;
		private var apiGUI:DisplayObject,apiGUIParams:Object;
		private var pendingScore:int;
		private var url:String;
		private var gameParams:Object; //parameters of the swf url (game.swf?myvar1=XXX&myvar2=YYY)

		/**
		 * Constructor
		 * @param	root : root Movieclip
		 * @param	debugField : Debug TextField to toggle on the debug traces. null to not output the traces.
		 * @param	urlDebug : To simulate a swf hosting url. Exple "kongregate.com".
		 * @param	paramsDebug : To simulate a list of url parameters (flash vars) passed to the game swf.
		 */
		function CUniteScoreAS3(root:MovieClip, debugField:TextField = null, urlDebug:String = null, paramsDebug:Object = null) {
			if (debugField != null) DEBUGFIELD = debugField;
			CUniteScoreAS3.theroot = root;
			//get the hosting url
			if (urlDebug == null) url = theroot.stage.loaderInfo.url;
			else url = urlDebug;
			// get the parameters passed into the game
			if (paramsDebug == null) {
				gameParams = LoaderInfo(theroot.loaderInfo).parameters;
			} else gameParams = paramsDebug;
			// init local connection listener
			sendLocalConnection.addEventListener(StatusEvent.STATUS, onConnStatus);
			init();
			
			if (DEBUGFIELD) {
				DEBUGFIELD.appendText( "CUniteScoreAS3 url=" + url + "\n" );
				DEBUGFIELD.appendText( "CUniteScoreAS3 gameParams=\n" );
				for (var p:String in gameParams) {
					DEBUGFIELD.appendText( "     " + p + "=" + gameParams[p] + "\n" );
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
		/*
		public function initIbProArcade(gameName:String):void {
			ibProArcadeGameName = gameName;
		}
		*/
		
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
			
			if (DEBUGFIELD) DEBUGFIELD.appendText( "sendScore score=" + score + " category=" + category + "\n" );

			if (url.indexOf("pepere.org") >= 0) {
				if (category == mainScoreCategory) ExternalInterface.call("saveGlobalScore", score);
			} else if (url.indexOf("jeuxgratuits.net") >= 0) {
				ExternalInterface.call("flashScoreService", score, category);
			} else if (url.indexOf("mindjolt.com") >= 0) {
				if (!mindJoltAPI) return;
				if (category == mainScoreCategory) mindJoltAPI.service.submitScore(score);
				else mindJoltAPI.service.submitScore(score, category);
			} else if (url.indexOf("kongregate.com") >= 0) {
				if (!kongregateAPI) return;
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
			} else if (url.indexOf("gamebrew.com") >= 0) {
				if (category == mainScoreCategory) {
					try {sendLocalConnection.send("gbapi", "scoreSubmit", score); } catch (error:ArgumentError) {}
				}
			} else if ( (url.indexOf("gr8games.eu") >= 0) || (url.indexOf("e-gierki.com") >= 0) ) {
				if (category == mainScoreCategory) {
					try {sendLocalConnection.send(gameParams.gr8games_api, "submitScore", score); } catch (error:ArgumentError) {}
				} else {
					try {sendLocalConnection.send(gameParams.gr8games_api, "submitScore", score, category); } catch (error:ArgumentError) {}
				}
			} else if (url.indexOf("bubblebox.com") >= 0) {
				if (category == mainScoreCategory) {
					if (apiGUI != null) {
						showScoreGUI();
						try { sendLocalConnection.send("bubbleboxRcvApi" + gameParams.bubbleboxGameID, "sendScore", pendingScore); } catch (error:ArgumentError) {}
					} else {
						//trace("gameParams.bubbleboxApiPath=" + gameParams.bubbleboxApiPath + " gameParams.bubbleboxGameID=" + gameParams.bubbleboxGameID);
						apiGUIParams = { w:400, h:200 }; //size of the GUI
						pendingScore = score; // to be used once the bubblebox component is loaded
						urlVars = new URLVariables();
						urlVars.bubbleboxGameID = gameParams.bubbleboxGameID;
						
						loadScoreGUI(gameParams.bubbleboxApiPath, urlVars, bubbleboxComplete);
					}
				}
			} else if (url.indexOf("gamegarage.co.uk") >= 0) {
				if (category == mainScoreCategory) {
					if (apiGUI != null) {
						showScoreGUI();
						try { sendLocalConnection.send("gamegarageRcvApi" + gameParams.game_id, "sendScore", pendingScore); } catch (error:ArgumentError) {}
					} else {
						trace("gameParams.gamegarageApiPath=" + gameParams.gamegarageApiPath + " gameParams.game_id=" + gameParams.game_id+ " gameParams.user_id=" + gameParams.user_id);
						apiGUIParams = { w:550, h:400 }; //size of the GUI
						pendingScore = score; // to be used once the gamegarage component is loaded
						urlVars = new URLVariables();
						urlVars.game_id = gameParams.game_id;
						if (gameParams.user_id) urlVars.user_id = gameParams.user_id;
						
						loadScoreGUI(gameParams.gamegarageApiPath, urlVars, gamegarageComplete);
					}
				}
			} else if ( (url.indexOf("games-garden.com") > -1) && (gameParams.isUser == "1") && (gameParams.gname) ) {
				//games-garden.com (derived from ibProArcade system)
				if (category == mainScoreCategory) {
					//urlRequest = new URLRequest("http://localhost:8080/cunitescore/index.php?act=Arcade&do=newscore"); //for local testings
					urlRequest = new URLRequest("http://www.games-garden.com/index.php?act=Arcade&do=newscore");
					urlVars = new URLVariables();
					urlVars.gname = gameParams.gname;
					urlVars.gscore = score;
					
					if (DEBUGFIELD) DEBUGFIELD.appendText( "http://www.games-garden.com/index.php?act=Arcade&do=newscore POST gname=" + urlVars.gname + " gscore=" + urlVars.gscore + "\n" );
					
					urlRequest.method = URLRequestMethod.POST;
					urlRequest.data = urlVars;
					/*
					urlLoader = new URLLoader();
					urlLoader.load(urlRequest);
					*/
					navigateToURL(urlRequest, "_self");
				}
			/*
			} else if (ibProArcadeGameName != null) {
				urlRequest = new URLRequest("index.php?act=Arcade&do=newscore");
				urlVars = new URLVariables();
				urlVars.gname = ibProArcadeGameName; //ibProArcadeGameName must be initialized with the method initIbProArcade
				urlVars.gscore = score;
				urlRequest.method = URLRequestMethod.POST;
				urlRequest.data = urlVars;
				navigateToURL(urlRequest, "_self");
				
				if (DEBUGFIELD) DEBUGFIELD.appendText( "request index.php?act=Arcade&do=newscore POST gscore=" + score + " gname=" + ibProArcadeGameName+"\n" );
			*/
			} else if ((mochiadsGameID != null) && (mochiadsBoardID != null)) {
				// Default score submittion is mochiads leaderboards
				if (category == mainScoreCategory) {
					MochiScores.showLeaderboard( { boardID: mochiadsBoardID, score: score } );
				}
			}
		}
		
		
		/**
		 * Show a portal logo (if assets have been embedded in your game).
		 * If you don't want to feature the logo of a portal on your game, just remove / don't embed the corresponding asset int your game.
		 * @param	layout Position of the log (TOP, TOP_RIGHT, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, LEFT, TOP_LEFT, CENTER)
		 * @param	duration Duration in milliseconds (minimum is 2 seconds)
		 */
		public function showLogo(layout:int = 3 /*CUniteScoreAS3.BOTTOM_RIGHT*/, duration:int = 5000):void {
			//If the log is already displayed, don't do anything
			if (logo_mc != null) return;
			if (duration < 2000) duration = 2000; //min 2 seconds
			
			//Is loaderInfo ready ? If not we delay the showLogo method.
			if (theroot.loaderInfo.bytesLoaded < theroot.loaderInfo.bytesTotal) {
				logoLayout = layout;
				logoDuration = duration;
				theroot.loaderInfo.addEventListener (Event.COMPLETE, showLogoDelayed);
				return;
			}
			
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
		
		/**
		 * Call this function to know if the score is powered on this portal by a Graphic User Interface.
		 * Most of the score system are not powered by GUI but some of them like mochiads, bubblebox.com are.
		 * @return true is the method sendScore will popup a GUI over your game. false if the sendScore method will be processed in background withtout a GUI.
		 */
		public function isScorePoweredByGUI():Boolean {
			for (var i:int = 0; i < scoreParams.length;i++) {
				if (url.indexOf(scoreParams[i].domain) >= 0) return scoreParams[i].GUI;
			}
			/*
			if (ibProArcadeGameName != null) {
				return true; //not really powered by GUI, but a score submission is reloading the page
			}
			*/
			if ((mochiadsGameID != null) && (mochiadsBoardID != null)) {
				return true; //mochiads score is a GUI
			}
			return false;
		}
		
		
		//***************************************
		//* Private methods
		//***************************************

		/**
		 * When the loaderInfo is not completed, a call to showLogo must be dealyed until it is completed.
		 * @param	ev
		 */
		private function showLogoDelayed(ev:Event):void {
			showLogo(logoLayout, logoDuration);
		}
		
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
		 * Try to get loaderIndo from the parent in case the fgame swf is already embedded (like in mochiads version control)
		 */
		private function topGameParams():void {
			//Are we in a mochiads version control/encryption movieclip ?
			if (DEBUGFIELD) DEBUGFIELD.appendText( "topGameParams()\n" );
			try {
				var topLoader:Object = (LoaderInfo(theroot.loaderInfo)).loader;
				gameParams = LoaderInfo(topLoader.loaderInfo).parameters;
			} catch (e:Error) {
				if (DEBUGFIELD) DEBUGFIELD.appendText( "topGameParams Error "+e+"\n" );
			}
		}
		
		
		/**
		 * Called by the constructor.
		 */
		private function init():void {
			var loader:Loader = new Loader();
			
			//Top container management (mochiads version control)
			for (var i:int = 0; i < scoreParams.length;i++) {
				if (url.indexOf(scoreParams[i].domain) >= 0) {
					if ( scoreParams[i].needUrlVars.length > 0 ) {
						for (var j:int = 0; j < scoreParams[i].needUrlVars.length; j++) {
							if (gameParams[scoreParams[i].needUrlVars[j]] == null) {
								topGameParams(); //try to get loader info from top container in case the game swf is embedded (mochiads version control)
								if (gameParams[scoreParams[i].needUrlVars[j]] == null) { delayedInit(); return; }
							}
						}
					}
					break;
				}
			}
			
			if (url.indexOf("mindjolt.com") >= 0) {
				// manually load the API
				//if (!gameParams.mjPath) topGameParams(); //try to get loader info from top container in case the game swf is embedded (mochiads version control)
				//if (!gameParams.mjPath) { delayedInit(); return; }
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, mindJoltComplete);
				loader.load(new URLRequest(gameParams.mjPath));
				theroot.addChild(loader);
			} else if (url.indexOf("kongregate.com") >= 0) {
				// The API path. The debug version ("shadow" API) will load if testing locally.
				//if (!gameParams.api_path) topGameParams(); //try to get loader info from top container in case the game swf is embedded (mochiads version control)
				//if (!gameParams.api_path) { delayedInit(); return; }
				loader.contentLoaderInfo.addEventListener ( Event.COMPLETE, kongregateComplete );
				loader.load ( new URLRequest( gameParams.api_path ) );
				theroot.addChild ( loader );
			}
		}
		
		/**
		 * Postpone the init method
		 */
		private function delayedInit():void {
			if (DEBUGFIELD) DEBUGFIELD.appendText( "delayedInit()\n" );
			initTimer = new Timer(1000);
			initTimer.addEventListener("timer", onDelayedInit);
			initTimer.start();
		}
		
		/**
		 * Init timer ends
		 */
		private function onDelayedInit(ev:Event):void {
			initTimer.stop();
			initTimer.removeEventListener("timer", onDelayedInit);
			initTimer = null;
			init();
		}
		
		/**
		 * Mindjolt component loaded
		 * @param	e
		 */
		private function mindJoltComplete ( e:Event ):void {
			mindJoltAPI=e.target.content;
			mindJoltAPI.service.connect();
			//trace ("[MindJoltAPI] service manually loaded");
		}
		
		/**
		 * Kongregate component loaded
		 * @param	e
		 */
		private function kongregateComplete ( e:Event ):void {
			kongregateAPI = e.target.content; // Save Kongregate API reference
			kongregateAPI.services.connect(); // Connect
			//trace ( "\n" + kongregateAPI.services + "\n" + kongregateAPI.user + "\n" + kongregateAPI.scores + "\n" + kongregateAPI.stats );
		}
		
		/**
		 * Bubblebox component loaded
		 * @param	e
		 */
		private function bubbleboxComplete ( e:Event ):void {
			trace ("[bubblebox API] bubbleboxComplete");
			//apiGUI = e.currentTarget;
			showScoreGUI();
			
			try { sendLocalConnection.send("bubbleboxRcvApi" + gameParams.bubbleboxGameID, "sendScore", pendingScore); } catch (error:ArgumentError) {}
		}
		
		/**
		 * Gamegarage component loaded
		 * @param	e
		 */
		private function gamegarageComplete ( e:Event ):void {
			trace ("[gamegarage API] gamegarageComplete");
			//apiGUI = e.currentTarget;
			showScoreGUI();
			
			try { sendLocalConnection.send("gamegarageRcvApi" + gameParams.game_id, "sendScore", pendingScore); } catch (error:ArgumentError) {}
		}
		
		
		
		/**
		 * Load the score GUI (for portals that use a GUI to submit the score)
		 * @param	apiPath
		 * @param	urlVars
		 * @param	completeCallback
		 */
		private function loadScoreGUI(apiPath:String, urlVars:URLVariables, completeCallback:Function):void {
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener ( Event.COMPLETE, completeCallback );
			trace("loadScoreGUI apiPath=" + apiPath);
			var urlRequest:URLRequest = new URLRequest( apiPath);
			urlRequest.method = URLRequestMethod.GET;
			urlRequest.data = urlVars;
			
			loader.load ( urlRequest );
			
			apiGUI = loader;
		}
		
		/**
		 * Show the score submittion GUI
		 */
		private function showScoreGUI ( ):void {
			trace ("[score GUI API] showScoreGUI");
			//Keep the GUI on TOP
			//TODO check the GUI is on top on every frame
			try {
				theroot.removeChild(apiGUI);
			} catch (e:Error) {
			}
			theroot.addChild(apiGUI);
			
			apiGUI.x = theroot.loaderInfo.width/2 - apiGUIParams.w/2;
			apiGUI.y = theroot.loaderInfo.height/2 - apiGUIParams.h/2;
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