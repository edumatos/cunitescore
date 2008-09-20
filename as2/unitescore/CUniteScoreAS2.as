/**
 * CUnisScoreAS2.as
 * AS2 submition score on major game portals
 * Class created by Badim (badim.ru)
 * 
 * *************************
 * Basic use :
 * *************************
 * 
 * //In _root Frame 1 :
 * import unitescore.*;
 * var scoreSubmitter:CUniteScoreAS2 = new CUniteScoreAS2();
 * //Optional init
 * scoreSubmitter.initMochiAdsLeaderboard("XXX","YYY");
 * scoreSubmitter.initIbProArcade("XXX");
 * 
 * //In game over :
 * _root.scoreSubmitter.sendScore(myScoreVar);
 * 
 */

import flash.external.ExternalInterface;
import unitescore.nonoba.*;
import unitescore.mochi.*;

class unitescore.CUniteScoreAS2 {
	var _user_name:String;

	

	/**
	 * Common LocalConnection object
	 */
	private var localConnection:LocalConnection;
	
	/**
	 * Main score category, for portals that don't implement score categories
	 */
	private var mainScoreCategory:String = "";
	
	/**
	 * Hosting url of the game swf
	 */
	private var url:String;
	
	
	//****************************************
	//* Scores systems that need a special ID
	//****************************************
	
	/**
	 * the game name for ibProArcade score submition
	 */
	private var ibProArcadeGameName:String;
	/**
	 * Mochiads leaderboards
	 */
	private var mochiadsGameID:String;
	private var mochiadsBoardID:String;

	
	/**
	 * Constructor
	 * @param	urlDebug : To simulate a swf hosting url. Exple "kongregate.com".
	 * @param	paramsDebug : To simulate a list of url parameters passed to the game swf.
	 */
	function CUniteScoreAS2(urlDebug:String,paramsDebug:Object) {
		_root._lockroot = true;
		
		//get the hosting url
		if (urlDebug == undefined) url = _root._url;
		else url = urlDebug;
		
		//get the debug root parameters
		if (paramsDebug!=undefined) {
			for ( var property in paramsDebug ) {
				_root[property] = paramsDebug[property];
			}
		}
		
		init();
	}

	/**
	 * init method called by the constructor
	 */
	private function init():Void {
		localConnection = new LocalConnection();
		if (url.indexOf("kongregate.com") > -1) {
			// Kongregate.com init
			_root.kongregateServices.connect();
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
	 * If your game use score categories, call this method to set the category that will be used to submit the score on portals that don't manage score categories.
	 * Exple : If you have 3 categories "easy", "medium", and "hard", you can call setMainScoreCategory("hard"). The score submitted on portals without score categories, will be the score of the "hard" category.
	 * If you don't call this method, the default main score category is "".
	 * If your game don't use score categories, you do'nt need to bother with this.
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
	public function initMochiAdsLeaderboard(gameid:String,boardid:String):Void {
		mochiadsGameID = gameid;
		mochiadsBoardID = boardid;
		MochiServices.connect(mochiadsGameID);
	}
	
	/**
	 * Call this if you want to use ibProArcade scores.
	 * @param	gameName The game name on ibProArcade
	 */
	public function initIbProArcade(gameName:String):Void {
		ibProArcadeGameName = gameName;
	}

	/**
	 * Call this method to submit the score. The method detect automatically on wich portal your game is hosted and call the corresponding API.
	 * @param	score : Score of the player
	 * @param	category : Category (example : "easy", "medium", "hard", "super hard", ...). Optional. If you use score categories, don't forget to call also sendScore(scoreVar) for portals that don't manage the score categories.
	 */
	function sendScore(score:Number , category:String):Void {
		if (category == undefined) {
			category = mainScoreCategory;
		}

		if (url.indexOf("nonoba.com") > -1) {
			//nonoba
			var nonoba_key:String;
			if (category == mainScoreCategory) {
				nonoba_key = "totalscores";
			} else {
				//remove ' ' and '-' characters from the category name
				nonoba_key = category.split(' ').join('').split('-').join('').toLowerCase();
			}
			NonobaAPI.SubmitScore(nonoba_key, score, null);
		} else if (url.indexOf("kongregate.com") > -1) {
			//kongregate
			if (category == mainScoreCategory) {
				_root.kongregateStats.submit('Total scores', score);
			} else {
				_root.kongregateStats.submit(category, score);
			}
		} else if (url.indexOf("surpass.com") > -1) {
			//surpass
			if (category == mainScoreCategory) localConnection.send("spapi", "scoreSend", score);
		} else if ((url.indexOf("mindjolt.com") > -1)||(url.indexOf("thisarcade.com") > -1)) {
			//mindjolt.com & thisarcade.com
			if (category == mainScoreCategory) {
				localConnection.send(_root.com_mindjolt_api, "submitScore", score);
			} else {
				localConnection.send(_root.com_mindjolt_api, "submitScore", score, category);
			}
		} else if (url.indexOf("hallpass.com") > -1) {
			//hallpass.com
			_root.HPScoreService.postScore(score, category);
		} else if (url.indexOf("gamegarage.co.uk") > -1) {
			//gamegarage.co.uk
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
		} else if (_root._url.indexOf("pepere.org") > -1) {
			if (category == mainScoreCategory) {
				if (ExternalInterface.available) {
					ExternalInterface.call("saveGlobalScore", score);
				} else {
					fscommand("saveGlobalScore", score + "");
				}
			}
		} else if ((ibProArcadeGameName != undefined) && (_root.isUser == 1)) {
			//ibProArcade compatible site
			var lv:LoadVars = new LoadVars();
			lv.gname = ibProArcadeGameName;
			lv.gscore = score;
			lv.sendAndLoad("index.php?act=Arcade&do=newscore", lv, "POST");
		} else if ((mochiadsGameID != undefined) && (mochiadsBoardID != undefined)) {
			MochiScores.showLeaderboard( {boardID : mochiadsBoardID, score : score} );
		}
	}
}
