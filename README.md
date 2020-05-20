<h2 align="center">Cops vs Terrorists TDM</h2>
Cops vs Terrorists - a team deathmatch gamemode for San Andreas Multiplayer (SA-MP)

<!-- TABLE OF CONTENTS -->
## Table of Contents

* [Introduction](#introduction)
* [Credits](#credits)
* [Getting Started](#getting-started)
* [Features](#features)
* [Contribute](#contribute)
* [License](#license)
* [Contact](#contact)

<!-- INTRODUCTION -->
## Introduction

I had made this script years ago. I came around it when I was cleaning my old harddisk. I have had some fun times playing with this script. Have some good memories. However, it isn't of any use to me anymore, so I have decided to release it. Maybe someone else can have fun with it.

<!-- CREDITS -->
### Credits

* [Cell_](https://forum.sa-mp.com/member.php?u=164585)
* Leo - a good friend and map contributor.

<!-- GETTING STARTED -->
## Getting Started

To get started you will need to edit some of the following:
* **MAX_PLAYERS**.
* **USE_IRC**. Comment it if you don't want to use the IRC feature. If you do decide to use the IRC feature, head over to DM/irc.inc and change IRC_SERVER and IRC_PORT and other details there.
* Load the MySQL tables file "**cs_playerdata**" in your preferred MySQL database.
* **MYSQL_*** (host, user, password, database) in DM/mysql.inc.
* **USE_BLOODSCREEN**. 1 (ON) 0 (OFF).
* **USE_HEADSHOTS/NUTSHOTS**.  1 (ON) 0 (OFF).
* **SERVER_NAME** && **SERVER_GMODE**.
* Create folder named "**ach**" in scriptfiles. (Can change folder name in includes/ach.inc).

You will need the following libraries to compile and run the script.
Plugin/include | Created by | Version
------------ | ------------- | -------------
[MYSQL R41-4 Plugin](https://forum.sa-mp.com/showthread.php?t=56564) | BlueG/maddinat0r. | R41-4
[Streamer](https://forum.sa-mp.com/showthread.php?t=102865) | Incognito. | 2.9.3
[IRC Plugin](https://forum.sa-mp.com/showthread.php?t=98803) | Incognito. | 1.4.8
[Whirlpool Plugin](https://forum.sa-mp.com/showthread.php?t=570945) | Y_Less. | 1.00?
[sscanf Plugin](https://forum.sa-mp.com/showthread.php?t=570927) | Y_Less. | 2.8.3
[md-sort](https://forum.sa-mp.com/showthread.php?t=343172) | Slice. | ??
[Screen Fader](https://forum.sa-mp.com/showthread.php?t=124091) | Joe Staff. | v2
[YSI (y_commands, y_iterate, y_ini, y_va)](https://forum.sa-mp.com/showthread.php?t=570883) | Y_Less. | 3.1
[iAchieve](https://forum.sa-mp.com/showthread.php?t=277706) | iPLEOMAX | Patched
Fixes.inc | Y_Less/Slice. - Can't find thread. | Provided in [pawno-includes](https://github.com/madgenius0/Cops-vs-Terrorists-TDM/tree/master/pawno-includes)
Progressbar include | Infernus. - Can't find thread. | Provided in [pawno-includes](https://github.com/madgenius0/Cops-vs-Terrorists-TDM/tree/master/pawno-includes)

<!-- FEATURES -->
## Features

* Top players' list after every round - scorecard.
* Custom damage system - damage based on weapon type and players' distance. You may see a minigun on buy list but the damage is extremely low.
* Headshot/nutshots - toggleable.
* Armor to save you from torso shots - realistic?
* Helmet to save you from headshots - helmets are damageable as well.
* Armor/health damage indicator - see armor/health icon above players' heads when you give them damage.
* Marking system - aim at player and press 'N' (KEY_NO) to mark them on the map.
* Kill cams - self-explanatory.
* Buy system at each round start - buy weapons for every round. /buy to see the buy menu on next spawn.
* 20 playable maps - credits given in the script.
* Maps system - you can add maps and spawn points for every map. Change MAX_MAPS if you add maps for them to load.
* Admin system - a very basic one with ban system and everything.
* Accounts system - players can choose to register if they wish to, to save stats.
* IRC system - optional.
* Blood screen on damage - toggleable.
* Spawn-kill protection - yeah...
* Team balance system - ensuring teams remain balanced.
* Achievements system - add your own achievements.
* AFK/Return system - allow players to know when someone has gone AFK/has returned.
* Radio system for teams - @before text to chat with teammates. Ex: "@form up on me".
* Killstreaks - you get a killstreak for consecutive kills.
* Lasers - lasers attached to guns.

<!-- CONTRIBUTE -->
## Contribute

You can contribute to the code so other players can enjoy features you have coded.

To contribute, use the following way:

1. Fork this repository.
2. Create a branch for your feature. (`git checkout -b feature/BRANCH_NAME`)
3. Commit your code. (`git commit -m 'DESCRIPTIVE_COMMIT_MESSAGE'`)
4. Push to the branch. (`git push origin feature/BRANCH_NAME`)
5. Open a Pull Request.

<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE` for more information.

<!-- CONTACT -->
## Contact

- [SA-MP forum](https://forum.sa-mp.com/member.php?u=164585)
- Discord - madgenius0#4058
