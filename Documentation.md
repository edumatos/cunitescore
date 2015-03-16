# Introduction #

First you have to get the latest [sources](sources.md).

# Actionscript 2 #

Then you have to copy/include the AS2 package in your project. You can either copy the folder `unitescore` from the `as2` directory into your project root directory or add the `as2` directory in your classpath.

## Basic use ##

In the first frame of your movie import the class and create an instance of it :
```
import unitescore.CUniteScoreAS2;

var scoreSubmitter : CUniteScoreAS2 = new CUniteScoreAS2();
```
you can as well instantiate the mochiads leaderboard in the same frame:
```
scoreSubmitter.initMochiAdsLeaderboard("xxx", "yyy");
```
where **"xxx"** is your game mochiad ID and **"yyy"** is your leaderboard ID.

In game over, either when submitting through a button or in the last frame:
```
scoreSubmitter.sendScore(score);
```
where **score** is the variable name of your game score.

You're done!
Just adding those lines of code your game will post scores to the different portals listed on the [Project Homepage](http://code.google.com/p/cunitescore/).