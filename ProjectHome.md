The **cUniteScore** project provides simple **Actionscript 2** and **Actionscript 3** classes for your Flash games to **implement the scores on major game portals**, all in one.
The game swf will **detect which portal it is hosted on**, and select the right score submission method.


---


## AS3 ##
### Validated game portals ###
  * [bubblebox.com](http://www.bubblebox.com/)
  * [kongregate.com](http://www.kongregate.com/)
  * [mochiads.com leaderboards](http://www.mochiads.com/)
  * [pepere.org](http://www.pepere.org/) (issue on firefox with mochiads version control?)
  * [nonoba.com](http://www.nonoba.com/)
  * [games-garden.com](http://www.games-garden.com/)
  * [jeuxgratuits.net](http://www.jeuxgratuits.net/) (issue on firefox with mochiads version control?)
  * [gamegarage.co.uk](http://www.gamegarage.co.uk/)
  * Invision Power Board (IPB) Forum running ibProArcade 3.40+ (issue with mochiads version control?)
  * Invision Power Board (IPB) Forum running Arcade Enhanced 6.15+ (issue with mochiads version control?)
  * Vbulletin (VB) Forum running ibProArcade v2.67+
  * Simple Machines Forum (SMF) E-Arcade 2.4.4+
  * [mindjolt.com](http://www.mindjolt.com/)
### Implemented but not tested game portals ###
  * [gamebrew.com](http://www.gamebrew.com/)
  * [gr8games.eu](http://www.gr8games.eu/) [e-gierki.com](http://e-gierki.com/) (portal not yet compatible with AS3 games)



---


## AS2 ##
**Be careful, using [Mochiads version control](http://mochiland.com/articles/mochiads-version-control-encryption-services) for an AS2 game, will make the scores not working on many portals!**
### Validated game portals ###
  * [kongregate.com](http://www.kongregate.com/) (won't work with mochiads version control)
  * [mochiads.com leaderboards](http://www.mochiads.com/)
  * [pepere.org](http://www.pepere.org/) (issue on firefox with mochiads version control?)
  * [bubblebox.com](http://www.bubblebox.com/)
  * [nonoba.com](http://www.nonoba.com/)
  * [games-garden.com](http://www.games-garden.com/)
  * [jeuxgratuits.net](http://www.jeuxgratuits.net/) (issue on firefox with mochiads version control?)
  * [gr8games.eu](http://www.gr8games.eu/) [e-gierki.com](http://e-gierki.com/)
  * [gamegarage.co.uk](http://www.gamegarage.co.uk/)
  * Invision Power Board (IPB) Forum running ibProArcade 3.40+ (issue with mochiads version control?)
  * Invision Power Board (IPB) Forum running Arcade Enhanced 6.15+ (issue with mochiads version control?)
  * Vbulletin (VB) Forum running ibProArcade v2.67+
  * Simple Machines Forum (SMF) E-Arcade 2.4.4+
  * [mindjolt.com](http://www.mindjolt.com/)
### Implemented but not tested game portals ###
  * [xpogames.com](http://www.xpogames.com/)
  * [surpassarcade.com](http://www.surpassarcade.com/)
  * [hallpass.com](http://www.hallpass.com/) (won't work with mochiads version control)
  * [z-fox.com](http://www.z-fox.com/)
  * [gamebrew.com](http://www.gamebrew.com/)


---


## Use ##
### Code ###
  * [How do I get the sources ?](sources.md)
  * [How do I use the AS2 classes ?](Documentation.md)
  * [How do I use the AS3 classes ?](as3classes.md)

### Specificities ###
#### Mochiads leaderboards ####
  * You must create a leaderboard for your game on the mochiads site. You must call a specific method to inform the cUniteScore class of the leaderboard id you've created.
  * Mochiads leaderboards, is the default highscore system used when the game is not hosted on one of the implemented portals.
#### Nonoba ####
You must create a highscore for your game on the nonoba.com website. The key of your main highscore list must be "totalscores". Then you can create as many highscore lists as you wish.
#### ibProArcade ####
The cUniteScore system is compatible with latest ibProArcade systems.
To detect that the swf is hosted on a compatible system, the game checks 2 conditions that are verified on the boards running an arcade module compatible with ibProArcade (VB ibProArcade, IPB ibProArcade, IPB Arcade Enhanced, SMF E-Arcade).
  * The game swf must be hosted in the `/arcade/` (VB ibProArcade, IPB ibProArcade, IPB Arcade Enhanced) or `/Games/` (SMF E-Arcade) folders.
  * If, for example, the .swf is named myGame.swf, a text file must be present at this url : `/arcade/gamedata/myGame/myGame.txt`.


---


## Portal owners ##
  * [Could my portal be supported by the cUniteScore classes ?](portalowners.md)
  * [cUniteScore game list](GameList.md)


---
