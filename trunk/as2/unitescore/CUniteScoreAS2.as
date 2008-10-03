﻿/**
 * CUnisScoreAS2.as
 * AS2 submition score on major game portals
 * Class created by Badim (badim.ru)
 * 
 * *************************
 * Basic use :
 * *************************
 * 
 * //In _root Frame 1 :
 * import unitescore.CUniteScoreAS2;
 * var scoreSubmitter : CUniteScoreAS2 = new CUniteScoreAS2();
 * 
 * //Optional init, XXX = mochiadID, YYY = boardID, ZZZ = game name.
 * scoreSubmitter.initMochiAdsLeaderboard("XXX","YYY");
 * scoreSubmitter.initIbProArcade("ZZZ");
 * 
 * //In game over :
 * _root.scoreSubmitter.sendScore(myScoreVar);
 * 
 */

import flash.external.ExternalInterface;
import unitescore.nonoba.NonobaAPI;
import unitescore.mochi.*;

class unitescore.CUniteScoreAS2 {
	
	/**
	 * TextArea debug. Before turning on this flag, get sure that you ahve a TextArea called "debug" on the root of your game swf.
	 */
	public var DEBUG:Boolean = false;
	
	/**
	 * Common LocalConnection object
	 */
	private var sendLocalConnection:LocalConnection;
	
	/**
	 * Main score category, for portals that don't implement score categories
	 */
	private var mainScoreCategory:String = "";
	
	/**
	 * Hosting url of the game swf
	 */
	private var url:String;
	
	/**
	 * Setinterval object
	 */
	private var interval:Number;
	
	//********************************************************
	//* Scores systems that need a specific vars (ID, etc...)
	//********************************************************
	
	/**
	 * The game name for ibProArcade score submition
	 */
	private var ibProArcadeGameName:String;
	/**
	 * Mochiads leaderboards
	 */
	private var mochiadsGameID:String;
	private var mochiadsBoardID:String;
	/**
	 * Score GUI object (used for portals imlpementuing a GUI API)
	 */
	private var scoreGUI:MovieClip;

	
	/**
	 * Constructor
	 * @param	urlDebug : To simulate a swf hosting url. Exple "kongregate.com".
	 * @param	paramsDebug : To simulate a list of url parameters passed to the game swf.
	 */
	public function CUniteScoreAS2(urlDebug:String, paramsDebug:Object) {
		_root._lockroot = true;
		_root._cuniscoreContext = this; //save the context for callbacks
		
		//get the hosting url
		url = urlDebug || _root._url;
		
		//get the debug root parameters
		if (paramsDebug) {
			if (DEBUG) _root.debug.text += "CUniteScoreAS2 paramsDebug, debug swf url parameters : \n";
			for ( var property in paramsDebug ) {
				if (DEBUG) _root.debug.text += "   property(" + property + ") = "+paramsDebug[property]+"\n";
				_root[property] = paramsDebug[property];
			}
		}
		
		if (DEBUG) _root.debug.text += "CUniteScoreAS2 url=" + url + "\n";
		
		init();
	}

	//***************************************
	//* Public methods
	//***************************************
	
	/**
	 * If your game use score categories, call this method to set the category that will be used to submit the score on portals that don't manage score categories.
	 * Example : If you have 3 categories "easy", "medium", and "hard", you can call setMainScoreCategory("hard"). The score submitted on portals without score categories, will be the score of the "hard" category.
	 * If you don't call this method, the default main score category is "".
	 * If your game don't use score categories, you don't need to bother with this.
	 * @param	category
	 */
	public function setMainScoreCategory(category:String):Void {
		mainScoreCategory = category;
	}
	
	/**
	 * Call this if you want to use mochiads leaderboard.
	 * http://mochiland.com/articles/introducing-mochiads-leaderboards
	 * @param	gameid The mochiads game id 
	 * @param	boardid The leaderboard id that you created on mochiads site for your game
	 */
	public function initMochiAdsLeaderboard(gameid:String, boardid:String):Void {
		mochiadsGameID = gameid;
		mochiadsBoardID = boardid;
		MochiServices.connect(mochiadsGameID);
	}
	
	/**
	 * Call this if you want to use ibProArcade scores.
	 * @param	gameName The game name as in the swf name.
	 */
	public function initIbProArcade(gameName:String):Void {
		ibProArcadeGameName = gameName;
	}

	/**
	 * Call this method to submit the score. The method detect automatically on wich portal your game is hosted and call the corresponding API.
	 * @param	score : Score of the player
	 * @param	category : Category (example : "easy", "medium", "hard", "super hard", ...). Optional. If you use score categories, don't forget to call also sendScore(scoreVar) for portals that don't manage the score categories.
	 */
	public function sendScore(score:Number, category:String):Void {
		
		category = category || mainScoreCategory;
		
		var lv:LoadVars;
		
		trace("CUniteScoreAS2 sendScore url=" + url);
		
		if (url.indexOf("nonoba.com") > -1) {
			//nonoba.com
			var nonoba_key:String;
			//You have to create a highscore for your game. Set the key to "totalscores" for your main score.
			//nonoba_key is "totalscores" if there's no category name, otherwise this code removes ' ' and '-' characters from it.
			nonoba_key = (category == mainScoreCategory) ? "totalscores" : category.split(' ').join('').split('-').join('').toLowerCase();
			NonobaAPI.SubmitScore(nonoba_key, score, null);
		} else if (url.indexOf("kongregate.com") > -1) {
			//kongregate.com
			if (DEBUG) _root.debug.text += "CUniteScoreAS2 _root.kongregateScores=" + _root.kongregateScores + "\n";
			_root.kongregateScores.setMode(category);
			_root.kongregateScores.submit(score);
		} else if (url.indexOf("surpassarcade.com") > -1) {
			//surpassarcade.com
			if (category == mainScoreCategory) {
				sendLocalConnection.send("spapi", "submitScore", score);
			} else {
				sendLocalConnection.send("spapi", "submitScore", score, category);
			}
		} else if ((url.indexOf("mindjolt") > -1)||(url.indexOf("thisarcade.com") > -1)) {
			//mindjolt.com & thisarcade.com
			if (category == mainScoreCategory) {
				sendLocalConnection.send(_root.com_mindjolt_api, "submitScore", score);
			} else {
				sendLocalConnection.send(_root.com_mindjolt_api, "submitScore", score, category);
			}
		} else if (url.indexOf("hallpass.com") > -1) {
			//hallpass.com
			_root.HPScoreService.postScore(score, category);
		} else if (url.indexOf("gamegarage.co.uk") > -1) {
			//gamegarage.co.uk
			/* Old way, for members only and without GUI, never tested
			if ((_root.game_id != undefined) && (_root.user_id != undefined)) {
				if (category == mainScoreCategory) {
					var lv:LoadVars = new LoadVars();
					lv.game_id = _root.game_id;
					lv.user_id = _root.user_id;
					lv.score = score;
					lv.alg = _root.game_id + _root.user_id + score + "a83l9xj";
					lv.sendAndLoad("http://www.gamegarage.co.uk/scripts/score.php", lv, "POST");
				}
			}
			*/
			if ((_root.gamegarageApiPath != undefined) && (_root.game_id != undefined) && (category == mainScoreCategory)) {
				_root.unitescorePendingScore = score; // to be used once the bubblebox component is loaded
				_root.unitescoreSendScoreMethod = gamegarageSendScore;
				if (scoreGUI != undefined) {
					gamegarageSendScore();
				} else {
					var useridVar:String="";
					if (_root.user_id != undefined) useridVar="&user_id="+_root.user_id;
					loadScoreGUI(_root.gamegarageApiPath + "?game_id=" + _root.game_id + useridVar, 550, 400, scoreGUIComplete);
				}
			}
		} else if (url.indexOf("pepere.org") > -1) {
			//pepere.org
			if (category == mainScoreCategory) {
				if (ExternalInterface.available) {
					ExternalInterface.call("saveGlobalScore", score);
				} else {
					fscommand("saveGlobalScore", score + "");
				}
			}
		} else if ((_root.bubbleboxApiPath != undefined) && (_root.bubbleboxGameID!=undefined) && (url.indexOf("bubblebox.com") > -1)) {
			//bubblebox.com
			if (category == mainScoreCategory) {
				_root.unitescorePendingScore = score; // to be used once the bubblebox component is loaded
				_root.unitescoreSendScoreMethod = bubbleboxSendScore;
				if (scoreGUI != undefined) {
					bubbleboxSendScore();
				} else {
					loadScoreGUI(_root.bubbleboxApiPath + "?bubbleboxGameID=" + _root.bubbleboxGameID, 400, 200, scoreGUIComplete);
				}
			}
		} else if (url.indexOf("z-fox.com") > -1) {
			if (category == mainScoreCategory) _root.sendScore(score);
		} else if ((url.indexOf("games-garden.com") > -1) && (_root.isUser == "1")) {
			//games-garden.com (derived from ibProArcade system)
			if (category == mainScoreCategory) {
				_root.gscore = score;
				getURL("index.php?act=Arcade&do=newscore", "_self", "POST");
			}
		} else if (ibProArcadeGameName != undefined) {
			//ibProArcade compatible site
			if (category == mainScoreCategory) {
				/*
				lv = new LoadVars();
				lv.gname = ibProArcadeGameName;
				lv.gscore = score;
				lv.sendAndLoad("index.php?act=Arcade&do=newscore", lv, "POST");
				*/
				_root.gname = ibProArcadeGameName;
				_root.gscore = score;
				getURL("index.php?act=Arcade&do=newscore", "_self", "POST");
			}
		} else if ((mochiadsGameID != undefined) && (mochiadsBoardID != undefined)) {
			if (category == mainScoreCategory) MochiScores.showLeaderboard( {boardID : mochiadsBoardID, score : score} );
		}
	}
	
	//***************************************
	//* Private methods
	//***************************************
	
	/**
	 * init method called by the constructor
	 */
	private function loadScoreGUI(apiPath:String, w:Number, h:Number, completeCallback:Function):Void {
		scoreGUI = _root.createEmptyMovieClip("scoreGUI_mc", 10336);
		scoreGUI._x = Stage.width/2 - w/2;
		scoreGUI._y = Stage.height/2 - h/2;
		
		var myLoader:MovieClipLoader = new MovieClipLoader();
		var myListener:Object = new Object();					
		myListener.onLoadError = function (target_mc:MovieClip, errorCode:String) { trace("load error " + errorCode); };
		//myListener.onLoadStart = function () { trace("load start"); }; myListener.onLoadProgress = function () { trace("load progress"); };
		myListener.onLoadInit = completeCallback;
		
		myLoader.addListener(myListener);
		myLoader.loadClip(apiPath, scoreGUI);
	}
	
	
	/**
	 * init method called by the constructor
	 */
	private function init():Void {
		sendLocalConnection = new LocalConnection();
		sendLocalConnection.onStatus = function (info:Object):Void { trace("localConnection " + info.level+" "+info); };
		
		if (url.indexOf("kongregate.com") > -1) {
			// Kongregate.com init
			if (DEBUG) _root.debug.text += "CUniteScoreAS2 _root.kongregateServices=" + _root.kongregateServices + "\n";
			_root.kongregateServices.connect();
			if (DEBUG) _root.debug.text += "\nCUniteScoreAS2 _root.kongregateServices.connect()\n";
		} else if (url.indexOf("gamegarage.co.uk") > -1) {
			// Gamegarage.co.uk init (tracking code)
			if (_root.game_id != undefined && _root.user_id != undefined) {
				var lv:LoadVars = new LoadVars();
				lv.game_id = _root.game_id;
				lv.user_id = _root.user_id;
				lv.sendAndLoad("http://www.gamegarage.co.uk/scripts/tracking.php", lv, "POST");
			}
		}
	}
	
	/**
	 * Score GUI Movieclip loaded
	 * @param	target_mc
	 */
	private function scoreGUIComplete(target_mc:MovieClip) : Void {
		this = _root._cuniscoreContext;
		trace("scoreGUIComplete(" + target_mc + ") _root.unitescoreSendScoreMethodD=" + _root.unitescoreSendScoreMethod + " _root.unitescorePendingScore=" + _root.unitescorePendingScore);
		//must wait a few milliseconds before using local connection
		interval = setInterval(_root.unitescoreSendScoreMethod , 500);
	}
	
	/**
	 * Send score to bubblebox GUI
	 */
	private function bubbleboxSendScore():Void {
		this = _root._cuniscoreContext;
		clearInterval(interval);
		sendLocalConnection.send("bubbleboxRcvApi" + _root.bubbleboxGameID, "sendScore", _root.unitescorePendingScore);
	}
	
	/**
	 * Send score to gamegarage GUI
	 */
	private function gamegarageSendScore():Void {
		this = _root._cuniscoreContext;
		clearInterval(interval);
		sendLocalConnection.send("gamegarageRcvApi" + _root.game_id, "sendScore", _root.unitescorePendingScore);
	}
}
