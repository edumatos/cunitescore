# Flashvars #
## Game ID ##
The game id will not be hard coded in the game. You need to pass all necessary variables to the .swf within the url flashvars arguments.

# Player name ? #
## Member only ##
The cUniteScore project manage mostly member only score systems. Systems where you don't need to enter a nickname.
## "Enter nickname" GUI ##
If your score system is open to all visitors, this requires the player to enter a nickname. This is not managed by the cUniteScore project. You must provide/host a GUI swf for the player to enter his/her nickname and to save the score on your servers. Your GUI will be dynamically loaded by the cUnitScore system and displayed on top of the game. Get in touch with us for more details.

# Easiest score systems to implement #
## ExternalInterface ##
It is an elegant way to manage scores. The game .swf just call a javscript method on the portal page, which sends a request to the server to save the score (AJAX).
## LocalConnection ##
It is also very simple to implement. The game .swf calls a method in a second swf hosted on the portal page, which sends a request to the server to save the score. This second .swf is developed and managed by the portal owner. It can be a container for the game .swf or a .swf embedded on the same page.