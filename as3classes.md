# Introduction #

First you have to get the latest [sources](sources.md).

# Actionscript 3 #

Then you have to copy/include the AS3 package in your project. You can either copy the folder `unitescore` from the `as3` directory into your project root directory or add the `as3` directory in your classpath.

## Basic use (timeline) ##

In the first frame of your movie import the class and create an instance of it:
```
import unitescore.CUniteScoreAS3;

var scoreSubmitter : CUniteScoreAS3 = new CUniteScoreAS3(this);
```
you can as well instantiate the mochiads leaderboard in the same frame:
```
scoreSubmitter.initMochiAdsLeaderboard("xxx", "yyy");
```
where **"xxx"** is your game mochiad ID and **"yyy"** is your leaderboard ID.

In game over, or whenever you want to submit the score:
```
scoreSubmitter.sendScore(score);
```
where **score** is the variable name of your game score.

You're done!
Just adding those lines of code your game will post scores to the different portals listed on the [Project Homepage](http://code.google.com/p/cunitescore/).