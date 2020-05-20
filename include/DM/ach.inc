/*-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=*/
/*-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=*/
/*     iAchieve - Dynamic Achievement System, Release by iPLEOMAX 2011 ©      */
/* Just another include which saves players achievements                      */
/* And Notifies them on Unlock. You can also give Money,Score,Car w/e..       */
/* Callback:   OnPlayerAchieve( playerid, achid ) {}                          */
/*                                                                            */
/* This system uses Y_INI, Y_HOOKS & foreach by Y_Less. (BIG THANKS!)         */
/* In order to save things correctly, make sure you create this folder:       */
/* >- scriptfiles\achievements\user (Here is where all ach-userfiles save)    */
/*                                                                            */
/* Note: Do not release any other edit of this INC without my permission.     */
/* Thanks to;                                                                 */
/*           - Y_Less for his includes                                        */
/*           - LCI Ach System by Deskoft for inspiration. Not it's edit btw.  */
/*           - Me for everything else.                                        */
/*                                                                            */
/* Please do not remove any credits!  Thanks for downloading!                 */
/*-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=*/
/*-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=*/

#if defined iach
	#endinput
#endif

#include <YSI\y_ini>

#define iach                                                                    //ignore this.
#define MAX_ACHIEVEMENTS 		120                                              //Number of achievements you'll have in your GM.
#define ACH_TIMER_UPDATE        2 												//Check for Unlocks Per Player Per Second.
#define ACH_USER_NAME			"/achs/%s.ini"				                      //Path where user achievements are saving.
#define ACH_SHOW_TIME           5                                               //Seconds for the "Ach Unlocked" to stay on screen.
#define ACH_SOUND_ID            1130                                            //You can put a music id here..
//#define ACH_ANIM_ON 															//use this if you want the textdraw to shine (LAG).

enum PLAYER_ACH_DATA
{
	achprogress[MAX_ACHIEVEMENTS+1],
	achieved[MAX_ACHIEVEMENTS+1]
};

enum MAIN_ACH_DATA
{
    ACH_WINVALUES,
    ACH_TITLE[32],
	ACH_INFO[164]
};

new
	bool:Ach_JustJoined[MAX_PLAYERS],
    Text:DynamicAchTD[MAX_PLAYERS][2],
    Text:AchTD[2],
	ACH_NUM,
	ACH_TIMER,
	ACH_USER[MAX_PLAYERS][PLAYER_ACH_DATA],
	ACH_MAIN[MAX_ACHIEVEMENTS][MAIN_ACH_DATA]
;

/* Achievement Natives:
native CreateAchievement(title[], info[], unlockvalue);
native LoadPlayerAchievements(playerid);
native SetPlayerAchievement(playerid, achid, value);
native GivePlayerAchievement(playerid, achid, value);
native GetPlayerAchievement(playerid, achid);
native bool:DidPlayerAchieve(playerid, achid);
*/

ach_OnPlayerConnect(playerid)
{
    Ach_JustJoined[playerid] = true;
    
    for(new a=0; a<MAX_ACHIEVEMENTS; a++)
	{
	    ACH_USER[playerid][achprogress][a] = 0;
	    ACH_USER[playerid][achieved][a] = 0; //Fixed.
	}

    SetTimerEx("Ach_CJJ", 5000, false, "d", playerid);
    
    LoadPlayerAchievements(playerid);

    HideAch(playerid);

	DynamicAchTD[playerid][0] = TextDrawCreate(320.000000, 330.000000, "30 Kills");
	TextDrawAlignment(DynamicAchTD[playerid][0], 2);
	TextDrawBackgroundColor(DynamicAchTD[playerid][0], 255);
	TextDrawFont(DynamicAchTD[playerid][0], 2);
	TextDrawLetterSize(DynamicAchTD[playerid][0], 0.370000, 1.699998);
	TextDrawColor(DynamicAchTD[playerid][0], 1179058175);
	TextDrawSetOutline(DynamicAchTD[playerid][0], 1);
	TextDrawSetProportional(DynamicAchTD[playerid][0], 1);
	TextDrawSetSelectable(DynamicAchTD[playerid][0], 0);

	DynamicAchTD[playerid][1] = TextDrawCreate(320.000000, 349.000000, "Info");
	TextDrawAlignment(DynamicAchTD[playerid][1], 2);
	TextDrawBackgroundColor(DynamicAchTD[playerid][1], 255);
	TextDrawFont(DynamicAchTD[playerid][1], 1);
	TextDrawLetterSize(DynamicAchTD[playerid][1], 0.200000, 1.500000);
	TextDrawColor(DynamicAchTD[playerid][1], -1);
	TextDrawSetOutline(DynamicAchTD[playerid][1], 1);
	TextDrawSetProportional(DynamicAchTD[playerid][1], 1);
	TextDrawSetSelectable(DynamicAchTD[playerid][1], 0);

	return true;
}

forward Ach_CJJ(playerid);
public Ach_CJJ(playerid)
{
	Ach_JustJoined[playerid] = false;
	return true;
}

ach_OnPlayerDisconnect(playerid)
{
	if(pInfo[playerid][pLoggedIn])
	{
    	SavePlayerAchievements(playerid);
    }

    for(new a=0; a<MAX_ACHIEVEMENTS; a++)
	{
	    ACH_USER[playerid][achprogress][a] = 0;
	    ACH_USER[playerid][achieved][a] = 0; //Fixed.
	}
	
	return true;
}

forward Init_AchSystem();
public Init_AchSystem()
{
	ACH_TIMER = SetTimer("AchCheck", ACH_TIMER_UPDATE*1000, true);

	AchTD[0] = TextDrawCreate(320.000000, 330.000000, "~n~");
	TextDrawAlignment(AchTD[0], 2);
	TextDrawBackgroundColor(AchTD[0], 255);
	TextDrawFont(AchTD[0], 1);
	TextDrawLetterSize(AchTD[0], 0.699998, 8.000000);
	TextDrawColor(AchTD[0], -1);
	TextDrawSetOutline(AchTD[0], 0);
	TextDrawSetProportional(AchTD[0], 1);
	TextDrawSetShadow(AchTD[0], 1);
	TextDrawUseBox(AchTD[0], 1);
	TextDrawBoxColor(AchTD[0], 75);
	TextDrawTextSize(AchTD[0], 251.000000, 260.000000);
	TextDrawSetSelectable(AchTD[0], 0);

	AchTD[1] = TextDrawCreate(320.000000, 307.000000, "] achievement unlocked ]");
	TextDrawAlignment(AchTD[1], 2);
	TextDrawBackgroundColor(AchTD[1], 255);
	TextDrawFont(AchTD[1], 2);
	TextDrawLetterSize(AchTD[1], 0.299997, 2.000000);
	TextDrawColor(AchTD[1], -11579393);
	TextDrawSetOutline(AchTD[1], 1);
	TextDrawSetProportional(AchTD[1], 1);
	TextDrawUseBox(AchTD[1], 1);
	TextDrawBoxColor(AchTD[1], 255);
	TextDrawTextSize(AchTD[1], 0.000000, 260.000000);
	TextDrawSetSelectable(AchTD[1], 0);

	ACH_NUM = -1;

	return true;
}

forward Exit_AchSystem();
public Exit_AchSystem()
{
    KillTimer(ACH_TIMER);
    return true;
}

forward CreateAchievement(title[], info[], unlockvalue);
public CreateAchievement(title[], info[], unlockvalue)
{
	ACH_NUM++;
	format(ACH_MAIN[ACH_NUM][ACH_TITLE], 32, "%s", title);
	format(ACH_MAIN[ACH_NUM][ACH_INFO], 164, "%s", info);
	ACH_MAIN[ACH_NUM][ACH_WINVALUES] = unlockvalue;

	if(ACH_NUM > MAX_ACHIEVEMENTS) printf("  **[WARNING] Number of achievements created is exceeding the max allowed limit.");

	return ACH_NUM;
}

stock GivePlayerAchievement(playerid, achid, value)
{
	ACH_USER[playerid][achprogress][achid] += value;
	return true;
}

stock SetPlayerAchievement(playerid, achid, value)
{
	ACH_USER[playerid][achprogress][achid] = value; //Fix2
	return true;
}
stock GetPlayerAchievement(playerid, achid)
{
	return ACH_USER[playerid][achprogress][achid];
}
stock DidPlayerAchieve(playerid, achid)
{
	return ACH_USER[playerid][achieved][achid];
}

forward SavePlayerAchievements(playerid);
public SavePlayerAchievements(playerid)
{
    new achtemp[128], achpname[MAX_PLAYER_NAME];
	GetPlayerName( playerid, achpname, sizeof achpname );
	format( achtemp, sizeof achtemp, ACH_USER_NAME, achpname ); /*IMP*/
	new INI:ACHNAME = INI_Open(achtemp);

	for(new a=0; a<MAX_ACHIEVEMENTS; a++)
	{
	    format(achtemp, sizeof achtemp, "ach%i", a);
     	INI_WriteInt(ACHNAME, achtemp, ACH_USER[playerid][achprogress][a]);
     	format(achtemp, sizeof achtemp, "unl%i", a);
		INI_WriteInt(ACHNAME, achtemp, ACH_USER[playerid][achieved][a]);
	}
	INI_Close(ACHNAME);
	return true;
}

forward LoadPlayerAchievements(playerid);
public LoadPlayerAchievements(playerid)
{
    new achtemp[128], achpname[MAX_PLAYER_NAME];
	GetPlayerName( playerid, achpname, sizeof achpname );
	format( achtemp, sizeof achtemp, ACH_USER_NAME, achpname );
	if(fexist(achtemp))
	{
		INI_ParseFile(achtemp, "load_achfile", .bExtra = true, .extra = playerid);
	}
	return true;
}

forward load_achfile(playerid, name[], value[]);
public load_achfile(playerid, name[], value[])
{
	new achentry[6];
	for(new a=0; a<MAX_ACHIEVEMENTS; a++)
	{
		format(achentry, sizeof achentry, "ach%i", a);
		INI_Int(achentry, ACH_USER[playerid][achprogress][a]);
		format(achentry, sizeof achentry, "unl%i", a);
		INI_Int(achentry, ACH_USER[playerid][achieved][a]);
	}
    return true;
}

forward AchCheck();
public  AchCheck()
{
	foreach(new i : Player)
	{
		if(Ach_JustJoined[i]) continue;
		for(new a=0; a<MAX_ACHIEVEMENTS; a++)
		{
			if(ACH_USER[i][achieved][a] != 1 && ACH_MAIN[a][ACH_WINVALUES] != 0)
			{
		    	if(ACH_USER[i][achprogress][a] >= ACH_MAIN[a][ACH_WINVALUES])
				{
                    ACH_USER[i][achieved][a] = 1;
                    ShowPlayerAchievement(i, a);
                    CallLocalFunction("OnPlayerAchieve", "dd", i, a);
				}
			}
		}
	}
	return true;
}

forward ShowPlayerAchievement(playerid, achid);
public ShowPlayerAchievement(playerid, achid)
{
	TextDrawShowForPlayer(playerid, AchTD[0]);
	TextDrawShowForPlayer(playerid, AchTD[1]);
	TextDrawSetString(DynamicAchTD[playerid][0], ACH_MAIN[achid][ACH_TITLE]);
	TextDrawSetString(DynamicAchTD[playerid][1], ACH_MAIN[achid][ACH_INFO]);
	TextDrawShowForPlayer(playerid, DynamicAchTD[playerid][0]);
	TextDrawShowForPlayer(playerid, DynamicAchTD[playerid][1]);
	PlayerPlaySound(playerid, ACH_SOUND_ID, 0, 0, 0);
	SetTimerEx("HideAch", 7000, false, "d", playerid);
	return true;
}

forward HideAch(playerid);
public HideAch(playerid)
{
    PlayerPlaySound(playerid, 0, 0, 0, 0);
    TextDrawHideForPlayer(playerid, AchTD[0]);
	TextDrawHideForPlayer(playerid, AchTD[1]);
	TextDrawHideForPlayer(playerid, DynamicAchTD[playerid][0]);
	TextDrawHideForPlayer(playerid, DynamicAchTD[playerid][1]);
	return true;
}

forward OnPlayerAchieve(playerid, achid);

/* ~~~~  ~~~~~~~~~~~~~~~~~~ End of File || ENJOY! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/