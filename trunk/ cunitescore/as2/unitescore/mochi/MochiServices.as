/**
* MochiServices
* Connection class for all MochiAds Remote Services
* @author Mochi Media+
* @version 1.34
*/

class unitescore.mochi.MochiServices {

	private static var _id:String;
	private static var _container:MovieClip;
	private static var _clip:MovieClip;
	private static var _loader:MovieClipLoader;
	private static var _loaderListener:Object;
	private static var _gatewayURL:String = "http://www.mochiads.com/static/lib/services/services.swf";
	private static var _swfVersion:String;
	private static var _listenChannel:Object;
	private static var _listenChannelName:String = "__mochiservices";
	private static var _sendChannel:Object;
	private static var _sendChannelName:String;
	private static var _rcvChannel:Object;
	private static var _rcvChannelName:String;
	
	private static var _connecting:Boolean = false;
	private static var _connected:Boolean = false;
	
	public static var onError:Object;
	
	//
	public static function get id ():String {
		return _id;
	}
	
	//
	public static function get clip ():MovieClip {
		return _container;
	}
	
	//
	public static function get childClip ():Object {
		return _clip;
	}

	//
	//
	static function getVersion():String {
        return "1.34";
    }
	
	//
	//
    private static function allowDomains(server:String):String {
        var hostname = server.split("/")[2].split(":")[0];
        if (System.security) {
            if (System.security.allowDomain) {
                System.security.allowDomain("*");
                System.security.allowDomain(hostname);
            }
            if (System.security.allowInsecureDomain) {
                System.security.allowInsecureDomain("*");
                System.security.allowInsecureDomain(hostname);
            }
        }
        return hostname;
    }
	
	//
	public static function get isNetworkAvailable():Boolean {
        if (System.security) {
            var o:Object = System.security;
            if (o.sandboxType == "localWithFile") {
                return false;
            }
        }
        return true;
    }
	
	//
	public static function set comChannelName(val:String):Void {
		if (val != undefined) {
			if (val.length > 3) {
				_sendChannelName = val + "_fromgame";
				_rcvChannelName = val;
				initComChannels();
			}
		}
	}
	
	//
	public static function get connected ():Boolean {
		return _connected;
	}
	
	/**
	 * Method: connect
	 * Connects your game to the MochiServices API
	 * @param	id the MochiAds ID of your game
	 * @param	clip the MovieClip in which to load the API (optional for all but AS3, defaults to _root)
	 * @param	onError a function to call upon connection or IO error
	 */
	public static function connect (id:String, clip:MovieClip, onError:Object):Void {
		if (!_connected && _clip == undefined) {
			trace("MochiServices Connecting...");
			_connecting = true;
			init(id, clip);	
		}
		if (onError != undefined) {
			MochiServices.onError = onError;
		} else if (MochiServices.onError == undefined) {
			MochiServices.onError = function (errorCode:String):Void { trace(errorCode); };
		}
	}
	
	//
	//
	public static function disconnect ():Void {
		if (_connected || _connecting) {
			_connecting = _connected = false;
			flush(true);
			if (_clip != undefined) {
				_clip.removeMovieClip();
				delete _clip;
			}
			_listenChannel.close();
			_rcvChannel.close();
		}
	}
	
	//
	//
	private static function init (id:String, clip:MovieClip):Void {
		_id = id;
		if (clip != undefined) {
			_container = clip;
		} else {
			_container = _root;
		}
		loadCommunicator(id, _container);
	}
	
	//
	//
	private static function loadCommunicator (id:String, clip:MovieClip):MovieClip {
		
		var clipname:String = '_mochiservices_com_' + id;
		
		if (_clip != null) {
			return _clip;
		}
		
        if (!MochiServices.isNetworkAvailable) {
            return null;
        }
		
		MochiServices.allowDomains(_gatewayURL);
		
		_clip = clip.createEmptyMovieClip(clipname, 10336, false);
		
		// load com swf into container
		_loader = new MovieClipLoader();
		if (_loaderListener.waitInterval != null) clearInterval(_loaderListener.waitInterval);
		_loaderListener = {};
		_loaderListener.onLoadError = function (target_mc:MovieClip, errorCode:String, httpStatus:Number):Void { 
			trace("MochiServices could not load.");
			MochiServices.disconnect();
			MochiServices.onError.apply(null, [errorCode]);
		};
		_loaderListener.onLoadStart = function (target_mc:MovieClip):Void { this.isLoading = true; }
		_loaderListener.startTime = getTimer();
		_loaderListener.wait = function ():Void { 
			if (getTimer() - this.startTime > 10000) {
				if (!this.isLoading) {
					MochiServices.disconnect();
					MochiServices.onError.apply(null, ["IOError"]);
				}
				clearInterval(this.waitInterval);
			}
		};
		_loaderListener.waitInterval = setInterval(_loaderListener, "wait", 1000);
		_loader.addListener(_loaderListener);
		_loader.loadClip(_gatewayURL, _clip);	
		// init send channel
		_sendChannel = new LocalConnection();
		_sendChannel._queue = [];
		// init rcv channel
		_rcvChannel = new LocalConnection();
		_rcvChannel.allowDomain = function (d:String):Boolean { return true; };
		_rcvChannel.allowInsecureDomain = _rcvChannel.allowDomain;
		_rcvChannel._nextcallbackID = 0;
		_rcvChannel._callbacks = {};
		listen();
		return _clip;
	}

	//
	//
	private static function onStatus (infoObject:Object):Void {
        switch (infoObject.level) {	
			case 'error' :
				_connected = false;
				_listenChannel.connect(_listenChannelName);
				break;	
        }
    }
	
	//
	//
	private static function listen ():Void {
		_listenChannel = new LocalConnection();
		_listenChannel.handshake = function (args:Object):Void { MochiServices.comChannelName = args.newChannel; };
		_listenChannel.allowDomain = function (d:String):Boolean { return true; };
		_listenChannel.allowInsecureDomain = _listenChannel.allowDomain;
		_listenChannel.connect(_listenChannelName);
		trace("Waiting for MochiAds services to connect...");
	}
	
	//
	//
	private static function initComChannels ():Void {	
		if (!_connected) {	
			_sendChannel.onStatus = function (infoObject:Object):Void { MochiServices.onStatus(infoObject); };
			_sendChannel.send(_sendChannelName, "onReceive", {methodName: "handshakeDone"});
			_sendChannel.send(_sendChannelName, "onReceive", { methodName: "registerGame", id: _id, clip: _clip, version: getVersion() } );
			_rcvChannel.onStatus = function (infoObject:Object):Void { MochiServices.onStatus(infoObject); };
			_rcvChannel.onReceive = function (pkg:Object):Void {
				var cb:String = pkg.callbackID;
				var cblst:Object = this._callbacks[cb];
				if (!cblst) return;
				var method = cblst.callbackMethod;
				var obj = cblst.callbackObject;
				if (obj && typeof(method) == 'string') method = obj[method];
				if (method != undefined) method.apply(obj, pkg.args);
				delete this._callbacks[cb];
			};
			_rcvChannel.onError = function ():Void { MochiServices.onError.apply(null, ["IOError"]); };
			_rcvChannel.connect(_rcvChannelName);
			trace("connected!");
			_connecting = false;
			_connected = true;
			_listenChannel.close();
			while(_sendChannel._queue.length > 0) {
				_sendChannel.send(_sendChannelName, "onReceive", _sendChannel._queue.shift());
			}
		}	
	}
	
	//
	//
	private static function flush (error:Boolean):Void {
		
		var request:Object;
		var callback:Object;
		
		while (_sendChannel._queue.length > 0) {
			
			request = _sendChannel._queue.shift();
			delete callback;
			if (request.callbackID != null) callback = _rcvChannel._callbacks[request.callbackID];
			delete _rcvChannel._callbacks[request.callbackID];
			
			if (error) {
				handleError(request.args, callback.callbackObject, callback.callbackMethod);
			}
			
		}		
		
	}
	
	//
	//
	private static function handleError (args:Object, callbackObject:Object, callbackMethod:Object):Void {
		
		if (args != null) {
			if (args.onError != null) {
				args.onError.apply(null, ["NotConnected"]);
			} 
			if (args.options != null && args.options.onError != null) {
				args.options.onError.apply(null, ["NotConnected"]);
			}
		}
		
		if (callbackMethod != null) {
			
			args = { };
			args.error = true;
			args.errorCode = "NotConnected";
		
			if (callbackObject != null && typeof(callbackMethod) == "string") {
				callbackObject[callbackMethod](args);
			} else if (callbackMethod != null) {
				callbackMethod.apply(args);
			}	
			
		}
		
	}
	
	//
	//
	public static function send (methodName:String, args:Object, callbackObject:Object, callbackMethod:Object):Void {
		if (_connected) {
			_sendChannel.send(_sendChannelName, "onReceive", {methodName: methodName, args: args, callbackID: _rcvChannel._nextcallbackID});
		} else if (_clip == undefined || !_connecting) {
			onError.apply(null, ["NotConnected"]);
			handleError(args, callbackObject, callbackMethod);
			flush(true);
			return;
		} else {
			_sendChannel._queue.push({methodName: methodName, args: args, callbackID: _rcvChannel._nextcallbackID});
		}
		_rcvChannel._callbacks[_rcvChannel._nextcallbackID] = {callbackObject: callbackObject, callbackMethod: callbackMethod};
		_rcvChannel._nextcallbackID++;
	}
	
}