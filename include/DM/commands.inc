#if defined main_commands_included_
	#endinput
#endif
#define main_commands_included_

YCMD:commands(playerid, params[], help)
{
	if (help) return SendHelpMessage(playerid, "Displays a list of commands you can use.");

	if(!pInfo[playerid][pSpawned]) return SendErrorMessage(playerid, "You can't use this command because you are not spawned.");

	ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, ""COL_BLUE"Commands", ""COL_WHITE"/register - To register on the server.\
		\n/login - to login and revive your saved stats.\n/kill - to kill yourself and respawn.\n/buy - to buy weapons after next spawn.\
		\n/pm - to PM another player.\n/reply - to reply to the last PM received.\n/spawnnow - To skip kill cam and go into the round.", "Ok", "");

	return 1;
}

YCMD:acmds(playerid,params[], help)
{
	if(!adminCheck(playerid, 1)) return 1;

	if(help) return SendHelpMessage(playerid, "Displays a list of the admin commands.");
	
	switch(pInfo[playerid][pAdminLevel])
	{
		case 0: return 1;
		
		case 1337: ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, ""COL_RED"Owner "COL_WHITE"level commands:", ""COL_WHITE"\n/asetlevel - to set someone's admin level.\n\n"COL_RED"Note: "COL_WHITE"You can use all these commands in silent mode with an \'ex\'.", "Ok", "");
		
		case 1:
		{
			ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, ""COL_RED"Admin level 1 commands:", ""COL_WHITE"/aannounce - to announce a message on the server\n/asay - to chat as an admin.\n/akill - to kill a player.\n/aip - to check a player's IP.\
				\n/afreeze- to freeze/unfreeze a player.\n/awarn - to warn a player.", "Ok", "");
		}

		case 2:
		{
			new tempstring[400];
			strcat(tempstring, ""COL_WHITE"/aexplode - to explode a player.\n/aslap - to slap a player.\n/goto - to teleport to a player.\n/get - to teleport a player to you.\n/akick - to kick a player.");
			strcat(tempstring, "\n/aheal - to heal a player.\n/aarmour - to give armour to a player.\n/arestore - to heal and armour a player.\n/agiveweapon - to give a player a weapon.\n\n"COL_YELLOW"Note: "COL_WHITE"You can also use all level 1 commands also.");
			ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, ""COL_RED"Admin level 2 commands:", tempstring, "Ok", "");
		}

		case 3:
		{
			new tempstring[421];
			strcat(tempstring, ""COL_WHITE"/akickex - to kick a player silently.\n/asetscore - to set a players score.\n/agivescore - to add to a player's score.\n/asetcash - to set a player's cash.\n");
			strcat(tempstring, "/agivecash - to give a player some cash.\n/ahealall - to heal everyone.\n/aarmourall - to give armour to everyone.\n/arestoreall - to heal and give armour to everyone.\n\n"COL_YELLOW"Note: "COL_WHITE"You can also use all level 1 and 2 commands also.");
			ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, ""COL_RED"Admin level 3 commands:", tempstring, "Ok", "");
		}

		case 4:
		{
			new tempstring[256];
			strcat(tempstring, ""COL_WHITE"/askipround - to skip the current round.\n/apreviousmap - to replay the last map.\n/achangemap - to change the map.\n/ajetpack - to get a jetpack."COL_YELLOW"Note: "COL_WHITE"You can also use all level 1,2 and 3 commands also.");
			ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, ""COL_RED"Admin level 4 commands:", tempstring, "Ok", "");
		}

		default: 
		{
			ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, ""COL_WHITE"Admin level "COL_BLUE"5 "COL_WHITE"commands:", ""COL_WHITE"Level 5 admins don't have any commands as of now.\nYou can use all commands from other levels.\nUse /level to know the commands for other levels.", "Ok", "");
		}
	}
	
	return 1;
}

YCMD:level(playerid,params[], help)
{
	if(!adminCheck(playerid, 1)) return 1;

	if(help) return SendHelpMessage(playerid, "Displays a list of commands for a certain level.");
	
	new
		plevel = strval(params)
	;
	
	if(plevel < 1 || plevel > 5 && plevel != 1337)
	{
		SendUsageMessage(playerid, "/level ([1-5] or [1337])");
		
		return 1;
	}
	
	if(plevel > pInfo[playerid][pAdminLevel])
	{
		SendFErrorMessage(playerid, "You aren't allowed to see the admin commands for level %d.", plevel);
		return 1;
	}
	
	switch(plevel)
	{
		case 0: return 1;
		
		case 1337: ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, ""COL_RED"Owner "COL_WHITE"level commands:", ""COL_WHITE"\n/asetlevel - to set someone's admin level.\n\n"COL_RED"Note: "COL_WHITE"You can use all these commands in silent mode with an \'ex\'.", "Ok", "");
		
		case 1:
		{
			ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, ""COL_RED"Admin level 1 commands:", ""COL_WHITE"/aannounce - to announce a message on the server\n/asay - to chat as an admin.\n/akill - to kill a player.\n/aip - to check a player's IP.\
				\n/afreeze- to freeze/unfreeze a player.\n/awarn - to warn a player.", "Ok", "");
		}

		case 2:
		{
			new tempstring[400];
			strcat(tempstring, ""COL_WHITE"/aexplode - to explode a player.\n/aslap - to slap a player.\n/goto - to teleport to a player.\n/get - to teleport a player to you.\n/akick - to kick a player.");
			strcat(tempstring, "\n/aheal - to heal a player.\n/aarmour - to give armour to a player.\n/arestore - to heal and armour a player.\n/agiveweapon - to give a player a weapon.\n\n"COL_YELLOW"Note: "COL_WHITE"You can also use all level 1 commands also.");
			ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, ""COL_RED"Admin level 2 commands:", tempstring, "Ok", "");
		}

		case 3:
		{
			new tempstring[421];
			strcat(tempstring, ""COL_WHITE"/akickex - to kick a player silently.\n/asetscore - to set a players score.\n/agivescore - to add to a player's score.\n/asetcash - to set a player's cash.\n");
			strcat(tempstring, "/agivecash - to give a player some cash.\n/ahealall - to heal everyone.\n/aarmourall - to give armour to everyone.\n/arestoreall - to heal and give armour to everyone.\n\n"COL_YELLOW"Note: "COL_WHITE"You can also use all level 1 and 2 commands also.");
			ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, ""COL_RED"Admin level 3 commands:", tempstring, "Ok", "");
		}

		case 4:
		{
			new tempstring[256];
			strcat(tempstring, ""COL_WHITE"/askipround - to skip the current round.\n/apreviousmap - to replay the last map.\n/achangemap - to change the map.\n/ajetpack - to get a jetpack.\n"COL_YELLOW"Note: "COL_WHITE"You can also use all level 1,2 and 3 commands also.");
			ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, ""COL_RED"Admin level 4 commands:", tempstring, "Ok", "");
		}

		default: 
		{
			ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, ""COL_WHITE"Admin level "COL_BLUE"5+ "COL_WHITE"commands:", ""COL_WHITE"Level 5+ admins don't have any commands as of now.\nYou can use all commands from other levels.\nUse /level to know the commands for other levels.\nNext level of commands is Level 1337.", "Ok", "");
		}
	}
	
	return 1;
}

YCMD:register(playerid, params[], help)
{
	if(help) return SendHelpMessage(playerid, "It registers you to our database to avoid loss of stats");
	
	if(pInfo[playerid][pRegistered])
	{
		SendErrorMessage(playerid, "You are already registered.");
		return 1;
	}

	if(pInfo[playerid][pLoggedIn])
	{
		SendErrorMessage(playerid, "You are already logged in.");
		return 1;
	}

	if(strlen(params) >= 3)
	{
		WP_Hash(pInfo[playerid][pPassword], 129, params);
		orm_insert(pInfo[playerid][pORMID], "onPlayerRegister", "is", playerid, params);

		return 1;
	}

	ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, ""COL_YELLOW"Register", ""COL_WHITE"Please input your desired password to register your account.\nYou cannot put an empty password.", "Register", "");
	return 1;
}

YCMD:help(playerid, params[], help)
{
    if (help)
    {
    	SendHelpMessage(playerid, "It displays help about the mode or about individual commands.");
    }

    else
    {
        if (isnull(params))
        {
	        SendServerMessage(playerid, "This is a TDM server. You kill the opponent team to increase your team score.");
	        SendServerMessage(playerid, "At the end of the round, the team with the most kills wins!");
        }

        else
        {
            Command_ReProcess(playerid, params, true);
        }
    }
    return 1;
}

YCMD:kill(playerid, params[], help)
{
    if (help)
    {
    	SendHelpMessage(playerid, "It sets your health to 0 and kills you.");
    	return 1;
    }

    if(pInfo[playerid][pVisible])
    {
    	SendErrorMessage(playerid, "You're marked and cannot skip death");
    	return 1;
    }

    if(pInfo[playerid][pTimeSinceSpawn] > 10)
    {
    	SendErrorMessage(playerid, "You cannot kill yourself because it has been 10 seconds since you spawned.");
    	return 1;
    }

    pInfo[playerid][pLastDamage] = INVALID_PLAYER_ID;
    pInfo[playerid][pLastDamageReason] = 255;

	SetPlayerHealth(playerid, 0.00);
	return 1;
}

YCMD:stats(playerid, params[], help)
{
	if(help) return SendHelpMessage(playerid, "Displays some stats for your username.");

	new tempString[256];

	format(tempString, sizeof(tempString), ""COL_WHITE"User ID: %d.\nKills: %d.\nDeaths: %d.\nK/D Ratio: %.2f.\n", pInfo[playerid][pID], pInfo[playerid][pTotalKills], pInfo[playerid][pTotalDeaths], ((!pInfo[playerid][pTotalDeaths]) ? (0) : (pInfo[playerid][pTotalKills]/pInfo[playerid][pTotalDeaths])));
	format(tempString, sizeof(tempString), "%sHead Shots: %d.\nAccuracy: %.2f.\nCurrent Killstreak: %d.\nCookies: %d.\n", tempString, pInfo[playerid][pTotalHeadShots], pInfo[playerid][pTotalAccuracy], pInfo[playerid][pKillStreak], pInfo[playerid][pCookies]);
	format(tempString, sizeof(tempString), "%sTime Played [HH:MM:SS]: %d:%d:%d.\nTotal Time Played [HH:MM:SS]: %d:%d:%d.", tempString, pInfo[playerid][pHoursPlayed], pInfo[playerid][pMinutesPlayed], pInfo[playerid][pSecondsPlayed], pInfo[playerid][pTotalHoursPlayed], pInfo[playerid][pTotalMinutesPlayed], pInfo[playerid][pTotalSecondsPlayed]);
	ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, ""COL_WHITE"Stats", tempString, "Okay", "");
	return 1;
}

YCMD:afkcheck(playerid, params[], help)
{
	if(help) return SendHelpMessage(playerid, "Check whether a player is AFK or not.");

	new
		player
	;

	if(sscanf(params, "u", player))
	{
		SendUsageMessage(playerid, "/afkcheck <player id/name>");
		return 1;
	}

    if(!IsPlayerConnected(playerid))
	{
	    SendErrorMessage(playerid, ERROR_CMD_PLAYER_NOT_CONNECTED);
	    return 1;
    }

	if(playerid == player)
	{
		SendErrorMessage(playerid, "No, you are not AFK, dumbass.");
		return 1;
	}

	if(pInfo[player][pAFK])
	{
		formatex(g_string, "[SERVER]: {FFFFFF}%s (%d) is AFK.", playerName(player), player);
		SendClientMessage(playerid, COLOR_SERVER, g_string);
	}

	else
	{
		formatex(g_string, "[SERVER]: {FFFFFF}%s (%d) is not AFK.", playerName(player), player);
		SendClientMessage(playerid, COLOR_SERVER, g_string);
	}
	return 1;
}

YCMD:buy(playerid, params[], help)
{
    if (help)
    {
    	SendHelpMessage(playerid, "It displays the buy dialog on next spawn.");
    	return 1;
    }

	pInfo[playerid][pBuyAllowed] = 1;
	SendServerMessage(playerid, "You'll get the menu after you spawn.");
	return 1;
}

YCMD:spawnnow(playerid, params[], help)
{
    if (help)
    {
    	SendHelpMessage(playerid, "It spawns you, skipping the killcam.");
    	return 1;
    }

	if(!pInfo[playerid][pKillCam])
	{
		SendErrorMessage(playerid, "You are not viewing a killcam.");
		return 1;
	}

	pInfo[playerid][pKillCam] = 1;

	return 1;
}

YCMD:pm(playerid,params[], help)
{	
    if (help)
    {
    	SendHelpMessage(playerid, "It sends a private message to the desired player.");
    	return 1;
    }

	if(pInfo[playerid][pMuted])
	{
		SendFErrorMessage(playerid, "You have been muted by an administrator. You cannot talk for another %d seconds.", pInfo[playerid][pMuteTime]);
		return 1;
	}
    
	new player;
	new message[120];
	
	if(sscanf(params, "us[120]", player, message))
	{
	    SendUsageMessage(playerid,"pm <player name / id> <message>");
	    return 1;
	}

    if(!IsPlayerConnected(playerid))
	{
	    SendErrorMessage(playerid, ERROR_CMD_PLAYER_NOT_CONNECTED);
	    return 1;
    }

	if(playerid == player)
	{
		SendErrorMessage(playerid, ERROR_CMD_PLAYER_SAME_PLAYER);
		return 1;
	}

	if(IPCheck(message, 1, playerid, 1)) return 0;
	
	format(g_bString, sizeof(g_bString), "PM Sent to %s <%d>: "COL_GRAY"%s", playerName(player), player, message);
	SendClientMessage(playerid, COLOR_GREEN,g_bString);
	
	format(g_bString, sizeof(g_bString), "PM From %s <%d>: "COL_GRAY"%s", playerName(playerid), playerid, message);
	SendClientMessage(player, COLOR_GREEN,g_bString);

	if(random(100) > 75) SendClientMessage(player, COLOR_INFO, "[INFO]: "COL_WHITE"Use /r [Message] to reply quickly.");
	
	GameTextForPlayer(playerid, "~w~PM ~r~SENT~w~!", 800, 1);
	GameTextForPlayer(player, "~w~PM ~r~RECIEVED~w~!", 800, 1);

	mysql_log_privateMessage(playerid, player, message);

	pInfo[player][pLastPM] = playerid;

	return 1;
}

YCMD:reply(playerid,params[], help)
{
    if(help)
    {
    	SendHelpMessage(playerid, "It replies to the last guy who PMed you.");
    	return 1;
    }

	if(pInfo[playerid][pMuted])
	{
		SendFErrorMessage(playerid, "You have been muted by an administrator. You cannot talk for another %d seconds.", pInfo[playerid][pMuteTime]);
		return 1;
	}
    
	if(isnull(params))
	{
	    SendUsageMessage(playerid,"r <message>");
	    return 1;
	}
	
	new player = pInfo[playerid][pLastPM];
	
    if(!IsPlayerConnected(player))
	{
	    SendErrorMessage(playerid, ERROR_CMD_PLAYER_NOT_CONNECTED);
	    return 1;
    }

	if(IPCheck(params, 1, playerid, 1)) return 0;
	
	format(g_bString, sizeof(g_bString), "Reply to %s <%d>: "COL_GRAY"%s", playerName(player), player, params);
	SendClientMessage(playerid, COLOR_GREEN,g_bString);
	
	format(g_bString, sizeof(g_bString), "Reply from %s <%d>: "COL_GRAY"%s", playerName(playerid), playerid, params);
	SendClientMessage(player, COLOR_GREEN,g_bString);
	
	GameTextForPlayer(playerid, "~w~PM ~r~SENT~w~!", 800, 1);
	GameTextForPlayer(player, "~w~PM ~r~RECIEVED~w~!", 800, 1);

	mysql_log_privateMessage(playerid, player, params);
	
	pInfo[player][pLastPM] = playerid;
	
	return 1;
}

YCMD:credits(playerid, params[], help)
{
	if(help) return SendHelpMessage(playerid, "List of people who helped make the script.");
	
	ShowPlayerDialog(playerid, 1000, DIALOG_STYLE_MSGBOX, ""COL_BLUE"Credits", "{FFFFFF}Cell_ - for CVT script.\nIncognito - for streamer and IRC.\nBlueG for MySQL.\nY_Less for YSI, sscanf, Whirlpool and fixes.inc.\nSlice for md-sort and fixes.inc.\nInfernus for progress.inc.\niPLEOMAX for iAchieve.\nJoe_Staff for screen fader.\nAll the mappers mentioned with their maps.", "Thanks", "");
	
	return 1;
}

YCMD:aka(playerid, params[], help)
{
	if(!adminCheck(playerid)) return 1;

	if(help) return SendHelpMessage(playerid, "Get a list of all the aliases a player has used.");
	
	new player;
	
	if(sscanf(params, "u", player))
	{
		SendUsageMessage(playerid, "/aka <player name/player ID>");
	
		return 1;
	}

	if(!IsPlayerConnected(player))
	{
		SendErrorMessage(playerid, ERROR_CMD_PLAYER_NOT_CONNECTED);
		return 1;
	}

	if(playerid == player)
	{
		SendErrorMessage(playerid, ERROR_CMD_PLAYER_SAME_PLAYER);
		return 1;
	}
	
	if(pInfo[player][pAdminLevel] > pInfo[playerid][pAdminLevel])
	{
		SendErrorMessage(playerid, "You cannot use the command on this admin.");
		return 1;
	}
	
	if(pInfo[player][pNoAKA])
	{
		SendErrorMessage(playerid, "This player doesn't have any AKA(s).");
		return 1;
	}
	
	format(mysql_mediumString, sizeof(mysql_mediumString), "%s(%d)'s AKA(s): "COL_RED"%s", playerName(player), player, pInfo[player][pAKAString]);
	SendAdminMessage(playerid, mysql_mediumString);
	return 1;
}

YCMD:fakechat(playerid, params[], help)
{
	if(!adminCheck(playerid, 5)) return 0;

	if(help) return SendHelpMessage(playerid, "Sends a fake message to the server.");

	new
		player,
		text[100]
	;
	
	if(sscanf(params, "us[100]", player, text))
	{
		SendUsageMessage(playerid, "/fakechat <player name/ID> <message>");
		return 1;
	}

	if(!IsPlayerConnected(player))
	{
		SendErrorMessage(playerid, ERROR_CMD_PLAYER_NOT_CONNECTED);
		return 1;
	}
	
	if(pInfo[player][pAdminLevel] > pInfo[playerid][pAdminLevel])
	{
		SendErrorMessage(playerid, "You cannot use the command on this admin.");
		return 1;
	}

	CallLocalFunction("OnPlayerText", "is", player, text);
	SendAdminMessage(playerid, "Fake message sent.");

	#if defined USE_IRC
		format(g_string,sizeof(g_string),"9[ADMIN] %s <%d> has used fake chat on %s <%d>.", playerName(playerid), playerid, playerName(player), player);
	    IRC_GroupSay(irc_botGroups[1],IRC_ADMINCHANNEL,g_string);
    #endif
	
	formatex(mysql_mediumString, "[ADMIN] {FFFFFF}%s <%d> used fake message on %s <%d>.", playerName(player), player, playerName(playerid), playerid);
	foreach(new x : Player)
	{
		if(x != playerid)
		{
			if(pInfo[x][pAdminLevel] > pInfo[playerid][pAdminLevel])
			{
				SendClientMessage(x, COLOR_ADMIN, mysql_mediumString);
			}
		}
	}
	
	return 1;
}

YCMD:fakecmd(playerid, params[], help)
{
	if(!adminCheck(playerid, 1337)) return 0;

	if(help) return SendHelpMessage(playerid, "Simulate a player using a command.");
	
	new
	    player,
	    command[32],
	    parameters[72],
	    tempString[128]
  	;
	
	if(sscanf(params, "us[32] S[72]", player, command, parameters))
	{
	    SendUsageMessage(playerid, "/fakecmd <playerid> /<command> <parameters>");
	    return 1;
	}

	if(!IsPlayerConnected(player))
	{
		SendErrorMessage(playerid, ERROR_CMD_PLAYER_NOT_CONNECTED);
		return 1;
	}
	
	if(pInfo[player][pAdminLevel] > pInfo[playerid][pAdminLevel])
	{
		SendErrorMessage(playerid, "You cannot use the command on this admin.");
		return 1;
	}
	
	if(isnull(parameters))
	{
	    parameters[0] = '\0';
	}
	
	formatex(tempString, "%s %s", command, parameters);
	Command_ReProcess(player, tempString, false);
	//CallLocalFunction("OnPlayerCommandText", "is", player, tempString);

	SendAdminMessage(playerid, "Fake command sent.");
	
	#if defined USE_IRC
		format(g_string,sizeof(g_string),"9[ADMIN] %s <%d> has used fake command on %s <%d>.", playerName(playerid), playerid, playerName(player), player);
    	IRC_GroupSay(irc_botGroups[1],IRC_ADMINCHANNEL,g_string);
	#endif
	
	formatex(mysql_mediumString, "[ADMIN] {FFFFFF}%s <%d> used fake command on %s <%d>.", playerName(player), player, playerName(playerid), playerid);
	foreach(new x : Player)
	{
		if(x != playerid)
		{
			if(pInfo[x][pAdminLevel] > pInfo[playerid][pAdminLevel])
			{
				SendClientMessage(x, COLOR_ADMIN, mysql_mediumString);
			}
		}
	}
	
	return 1;
}

YCMD:aban(playerid,params[], help)
{
	if(!adminCheck(playerid, 3)) return 1;

	if(help) return SendHelpMessage(playerid, "Use to ban a player from the server.");

	new ID;
	new cmdreason[100];
	
	if(sscanf(params,"us[32]",ID,cmdreason))
	{
	    SendUsageMessage(playerid,"/aban <player name/ID> <reason>");
	    return 1;
	}

	if(!IsPlayerConnected(ID))
	{
		SendErrorMessage(playerid, ERROR_CMD_PLAYER_NOT_CONNECTED);
		return 1;
	}
	
	if(pInfo[ID][pAdminLevel] > pInfo[playerid][pAdminLevel])
	{
		SendErrorMessage(playerid, "You cannot use the command on this admin.");
		return 1;
	}

	if(strlen(cmdreason) > 32)
	{
		SendErrorMessage(playerid, "Maximum ban reason length (32) exceeded.");
		return 1;
	}

	pInfo[ID][pBeingKicked] =1;
	format(g_string,sizeof(g_string),"[ADMIN] "COL_WHITE"%s <%d> has banned %s <%d> from the server. Reason: "COL_RED"%s.",playerName(playerid),playerid,playerName(ID),ID,cmdreason);
	SendClientMessageToAll(COLOR_ADMIN,g_string);

	#if defined USE_IRC
		format(g_string,sizeof(g_string),"9[ADMIN] %s <%d> has banned %s <%d> from the server. Reason: %s.",playerName(playerid), playerid, playerName(ID),ID,cmdreason);
	    IRC_GroupSay(irc_botGroups[0],IRC_CHANNEL,g_string);
	    IRC_GroupSay(irc_botGroups[1],IRC_ADMINCHANNEL,g_string);
    #endif
	
	mysql_banPlayer(ID, playerid, cmdreason);

	return 1;
}

YCMD:atempban(playerid,params[],help)
{
	if(!adminCheck(playerid, 3)) return 0;
	
	if(help) return SendHelpMessage(playerid, "Use to temporarily ban a player from the server.");

	new ID;
	new hours;
	new cmdreason[100];

	if(sscanf(params,"uis[32]",ID,hours,cmdreason))
	{
	    SendUsageMessage(playerid, "/atempban <player name/ID> <hours> <reason>");
	    return 1;
	}

	if(!IsPlayerConnected(ID))
	{
		SendErrorMessage(playerid, ERROR_CMD_PLAYER_NOT_CONNECTED);
		return 1;
	}
	
	if(pInfo[ID][pAdminLevel] > pInfo[playerid][pAdminLevel])
	{
		SendErrorMessage(playerid, "You cannot use the command on this admin.");
		return 1;
	}

	if(strlen(cmdreason) > 32)
	{
		SendErrorMessage(playerid, "Maximum ban reason length (32) exceeded.");
		return 1;
	}

	if(hours < 5 || hours > 1000)
	{
		formatex(g_string, "[ERROR] {FFFFFF}You can't ban someone for %i hours.", hours);
		SendClientMessage(playerid, COLOR_ERROR, g_string);
		
		return 1;
	}

	pInfo[ID][pBeingKicked] =1;
	format(g_string,sizeof(g_string),"[ADMIN] "COL_WHITE"%s <%d> has temp banned %s <%d> from the server for %d hours. Reason: "COL_RED"%s.",playerName(playerid),playerid,playerName(ID),ID,hours,cmdreason);
	SendClientMessageToAll(COLOR_ADMIN,g_string);
	
	mysql_banPlayer(ID, playerid, cmdreason, (hours+1));

	#if defined USE_IRC
		format(g_string,sizeof(g_string),"9[ADMIN] %s <%d> has banned %s <%d> from the server for %d hours. Reason: %s.",playerName(playerid),playerid,playerName(ID),ID, hours,cmdreason);
	    IRC_GroupSay(irc_botGroups[0],IRC_CHANNEL,g_string);
	    IRC_GroupSay(irc_botGroups[1],IRC_ADMINCHANNEL,g_string);
    #endif
	
	return 1;
}

YCMD:abanex(playerid,params[], help)
{
	if(!adminCheck(playerid, 4)) return 1;

	if(help) return SendHelpMessage(playerid, "Use to ban a player from the server.");

	new ID;
	new cmdreason[100];
	
	if(sscanf(params,"us[32]",ID,cmdreason))
	{
	    SendUsageMessage(playerid,"/abanex <player name/ID> <reason>");
	    return 1;
	}

	if(!IsPlayerConnected(ID))
	{
		SendErrorMessage(playerid, ERROR_CMD_PLAYER_NOT_CONNECTED);
		return 1;
	}
	
	if(pInfo[ID][pAdminLevel] > pInfo[playerid][pAdminLevel])
	{
		SendErrorMessage(playerid, "You cannot use the command on this admin.");
		return 1;
	}

	if(strlen(cmdreason) > 32)
	{
		SendErrorMessage(playerid, "Maximum ban reason length (32) exceeded.");
		return 1;
	}

	pInfo[ID][pBeingKicked] =1;
	format(g_string,sizeof(g_string),"[ADMIN] "COL_WHITE"%s <%d> has banned %s <%d> from the server. Reason: "COL_RED"%s.",playerName(playerid),playerid,playerName(ID),ID,cmdreason);
	formatex(mysql_mediumString, "[ADMIN] {FFFFFF}Administrator has banned %s <%d from the server. Reason: "COL_RED"%s.", playerName(ID), ID, cmdreason);

	foreach(new x : Player)
	{
		if(pInfo[x][pAdminLevel] >= 1)
		{
			SendClientMessage(x, COLOR_ADMIN, g_string);
		}
		else
		{
			SendClientMessage(x, COLOR_ADMIN, mysql_mediumString);
		}
	}

	#if defined USE_IRC
		format(g_string,sizeof(g_string),"9[ADMIN] %s <%d> has banned %s <%d> from the server. Reason: %s.",playerName(playerid), playerid, playerName(ID),ID,cmdreason);
	    IRC_GroupSay(irc_botGroups[1],IRC_ADMINCHANNEL,g_string);

		format(g_string,sizeof(g_string),"9[ADMIN] Administrator has banned %s <%d> from the server. Reason: %s.", playerName(ID),ID,cmdreason);
	    IRC_GroupSay(irc_botGroups[0],IRC_CHANNEL,g_string);
	#endif

	mysql_banPlayer(ID, playerid, cmdreason);

	return 1;
}

YCMD:atempbanex(playerid,params[],help)
{
	if(!adminCheck(playerid, 4)) return 0;
	
	if(help) return SendHelpMessage(playerid, "Use to temporarily ban a player from the server.");

	new ID;
	new hours;
	new cmdreason[100];

	if(sscanf(params,"uis[32]",ID,hours,cmdreason))
	{
	    SendUsageMessage(playerid, "/atempbanex <player name/ID> <hours> <reason>");
	    return 1;
	}

	if(!IsPlayerConnected(ID))
	{
		SendErrorMessage(playerid, ERROR_CMD_PLAYER_NOT_CONNECTED);
		return 1;
	}
	
	if(pInfo[ID][pAdminLevel] > pInfo[playerid][pAdminLevel])
	{
		SendErrorMessage(playerid, "You cannot use the command on this admin.");
		return 1;
	}

	if(strlen(cmdreason) > 32)
	{
		SendErrorMessage(playerid, "Maximum ban reason length (32) exceeded.");
		return 1;
	}

	if(hours < 5 || hours > 1000)
	{
		formatex(g_string, "[ERROR] {FFFFFF}You can't ban someone for %i hours.", hours);
		SendClientMessage(playerid, COLOR_ERROR, g_string);
		
		return 1;
	}

	pInfo[ID][pBeingKicked] =1;
	format(g_string,sizeof(g_string),"[ADMIN] "COL_WHITE"%s <%d> has temp banned %s <%d> from the server for %d hours. Reason: "COL_RED"%s.",playerName(playerid),playerid,playerName(ID),ID,hours,cmdreason);
	format(mysql_mediumString,sizeof(mysql_mediumString),"[ADMIN] "COL_WHITE"Administrator has temp banned %s <%d> from the server for %d hours. Reason: "COL_RED"%s.",playerName(ID),ID,hours,cmdreason);

	foreach(new x : Player)
	{
		if(pInfo[x][pAdminLevel] >= 1)
		{
			SendClientMessage(x, COLOR_ADMIN, g_string);
		}
		else
		{
			SendClientMessage(x, COLOR_ADMIN, mysql_mediumString);
		}
	}
	
	mysql_banPlayer(ID, playerid, cmdreason, (hours+1));

	#if defined USE_IRC
		format(g_string,sizeof(g_string),"9[ADMIN] Administrator has banned %s <%d> from the server for %d hours. Reason: %s.",playerName(ID),ID, hours,cmdreason);
	    IRC_GroupSay(irc_botGroups[0],IRC_CHANNEL,g_string);
	    format(g_string,sizeof(g_string),"9[ADMIN] %s <%d> has banned %s <%d> from the server for %d hours. Reason: %s.",playerName(playerid),playerid,playerName(ID),ID, hours,cmdreason);
	    IRC_GroupSay(irc_botGroups[1],IRC_ADMINCHANNEL,g_string);
    #endif
	
	return 1;
}

YCMD:aunban(playerid, params[], help)
{
	if(!adminCheck(playerid, 3)) return 0;

	if(help) return SendHelpMessage(playerid, "Use to unban a player using their name.");
	
	if(isnull(params))
	{
		SendUsageMessage(playerid, "/aunban <name>");
		return 1;
	}
	
	if(strlen(params) > 24)
	{
		SendErrorMessage(playerid, "Player names aren't greater than 24 in length.");
		return 1;
	}
	
	new
		params2[128]
	;

	mysql_escape_string(params, params2);
	formatex(mysql_normalString, "SELECT `banName` FROM `cs_playerBans` WHERE `banName` = '%s'", params2);
	mysql_function_query(dbHandle, mysql_normalString, true, "onUnbanCommandQuery", "iis", playerid, 0, params);
	
	return 1;
}

YCMD:aunbanip(playerid, params[], help)
{
	if(!adminCheck(playerid, 4)) return 0;
	
	if(help) return SendHelpMessage(playerid, "Use to unban a player using their IP.");
	
	if(isnull(params))
	{
		SendUsageMessage(playerid, "/adunbanip <IP>");
		return 1;
	}
	
	if(strlen(params) > 15)
	{
		SendErrorMessage(playerid, "Player IPs aren't greater than 16 in length.");
		return 1;
	}
	
	new
		params2[128]
	;

	mysql_escape_string(params, params2);
	
	formatex(mysql_normalString, "SELECT `banName` FROM `sona_playerBans` WHERE `banIP` = '%s'", params2);
	mysql_function_query(dbHandle, mysql_normalString, true, "onUnbanCommandQuery", "iis", playerid, 1, params);
	
	return 1;
}

YCMD:ascreen(playerid,params[], help)
{
	if(!adminCheck(playerid, 1)) return 0;

	if(help) return SendHelpMessage(playerid, "To announce something for a specific player.");

	new
		player,
		text[120]
	;

	if(sscanf(params, "us[120]", player, text))
	{
		SendUsageMessage(playerid, "/adscreen <player name/ID> <text>");
		return 1;
	}
	
	if(isnull(text))
	{
		SendUsageMessage(playerid, "/adscreen <player name/ID> <text>");
	    return 1;
	}

	if(!IsPlayerConnected(player))
	{
		SendErrorMessage(playerid, ERROR_CMD_PLAYER_NOT_CONNECTED);
	    return 1;
	}

	GameTextForPlayer(player,text,5000,3);

	formatex(g_string, "[ADMIN]: {FFFFFF}Screen message to %s(%d): %s", playerName(player), player, text);
	SendClientMessage(playerid, COLOR_ADMIN, g_string);

	return 1;
}

YCMD:askipround(playerid, params[], help)
{
	if(!adminCheck(playerid, 3)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to skip the current round.");
		return 1;
	}

	mapEnd();
	SendFAdminMessageToAll("Administrator %s <%d> has skipped current round.", playerName(playerid), playerid);

	return 1;
}

YCMD:askiproundex(playerid, params[], help)
{
	if(!adminCheck(playerid, 4)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to skip the current round without sending a message to all.");
		return 1;
	}

	formatex(mysql_mediumString, "[ADMIN]: {FFFFFF}Administrator %s <%d> has skipped current round.", playerName(playerid), playerid);
	foreach(new x : Player)
	{
		if(pInfo[x][pAdminLevel] >= 1)
			SendClientMessage(x, COLOR_ADMIN, mysql_mediumString);

		else
			SendClientMessage(x, COLOR_ADMIN, "[ADMIN]: {FFFFFF}Administrator has skipped current round.");
	}
	mapEnd();

	return 1;
}

YCMD:apreviousmap(playerid, params[], help)
{
	if(!adminCheck(playerid, 3)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to skip to the previous map.");
		return 1;
	}

	gMapSpecified = gCurrentMap - 1;
	mapEnd();
	SendFAdminMessageToAll("Administrator %s <%d> has skipped current round.", playerName(playerid), playerid);
	return 1;
}

YCMD:apreviousmapex(playerid, params[], help)
{
	if(!adminCheck(playerid, 4)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to skip to the previous map without sending a message to all.");
		return 1;
	}

	gMapSpecified = gCurrentMap - 1;
	mapEnd();

	formatex(g_string, "[ADMIN]: {FFFFFF}Administrator %s <%d> has skipped to the previous map.", playerName(playerid), playerid);
	foreach(new x : Player)
	{
		if(pInfo[x][pAdminLevel] >= 1)
			SendClientMessage(x, COLOR_ADMIN, g_string);

		else
			SendClientMessage(x, COLOR_ADMIN, "[ADMIN]: {FFFFFF}Administrator has skipped to the previous map.");
	}
	return 1;
}

YCMD:achangemap(playerid, params[], help)
{
	if(!adminCheck(playerid, 3)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to change the map to another map using map name/id.");
		return 1;
	}

	if(isnull(params))
	{
		SendUsageMessage(playerid, "achangemap <map name / mapid>");
		return 1;
	}

	new value;

	if(!IsNumeric(params))
	{
	    for(new i = 0; i < TOTAL_MAPS; i++)
		{
		    if(strfind(mapInfo[i][mapName], params, true) > -1)
		    {
		        value = i;
		        break;
		    }
		}
	}

	else value = strval(params);

	if(value >= TOTAL_MAPS || value < 0)
	{
		SendFErrorMessage(playerid, "Invalid map id: %d.", value);
		return 1;
	}

	gMapSpecified = value;
	mapEnd();

	SendFAdminMessageToAll("Administrator %s <%d> has changed the map to %s.", playerName(playerid), playerid, mapInfo[value][mapName]);
	return 1;
}

YCMD:achangemapex(playerid, params[], help)
{
	if(!adminCheck(playerid, 4)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to change the map to another map using map name/id without sending a message to all.");
		return 1;
	}

	if(isnull(params))
	{
		SendUsageMessage(playerid, "achangemapex <map name / mapid>");
		return 1;
	}

	new value;

	if(!IsNumeric(params))
	{
	    for(new i = 0; i < TOTAL_MAPS; i++)
		{
		    if(strfind(mapInfo[i][mapName], params, true) > -1)
		    {
		        value = i;
		        break;
		    }
		}
	}

	else value = strval(params);

	if(value >= TOTAL_MAPS || value < 0)
	{
		SendFErrorMessage(playerid, "Invalid map id: %d.", value);
		return 1;
	}

	gMapSpecified = value;
	mapEnd();

	formatex(g_bString, "[ADMIN]: {FFFFFF}Administrator %s <%d> has changed the map to %s.", playerName(playerid), playerid, mapInfo[value][mapName]);
	formatex(g_string, "[ADMIN]: {FFFFFF}Administrator has changed the map to %s.", mapInfo[value][mapName]);

	foreach(new x : Player)
	{
		if(pInfo[x][pAdminLevel] >= 1)
			SendClientMessage(x, COLOR_ADMIN, g_bString);

		else
			SendClientMessage(x, COLOR_ADMIN, g_string);
	}
	return 1;
}

YCMD:aip(playerid, params[], help)
{
	if(!adminCheck(playerid)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to display a player's IP.");
		return 1;
	}

	new player;
	if(sscanf(params, "u", player))
	{
		SendUsageMessage(playerid, "ip <player name / playerid>");
		return 1;
	}

	if(!IsPlayerConnected(player))
	{
		SendErrorMessage(playerid, ERROR_CMD_PLAYER_NOT_CONNECTED);
		return 1;
	}

	if(playerid == player)
	{
		SendErrorMessage(playerid, ERROR_CMD_PLAYER_SAME_PLAYER);
		return 1;
	}

	SendFAdminMessage(playerid, "%s\'s <%d> IP: %s.", playerName(player), player, playerIP(player));

	return 1;
}

YCMD:afreeze(playerid, params[], help)
{
	if(!adminCheck(playerid)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to freeze/unfreeze a player.");
		return 1;
	}

	new player,
		reason[32]
	;

	if(sscanf(params, "uS[32]", player, reason))
	{
		SendUsageMessage(playerid, "afreeze <player name / playerid> (reason)");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0, .same = 0)) return 1;

	if(!pInfo[player][pFrozen])
	{
		pInfo[player][pFrozen] = 1;
		GameTextForPlayer(player, "~w~You have been ~r~frozen~w~!", 3000, 1);
		SendFAdminMessageToAll("Administrator %s <%d> has frozen %s <%d>. Reason: "COL_RED"%s", playerName(playerid), playerid, playerName(player), player, reason);
		TogglePlayerControllable(player, false);
		return 1;
	}

	pInfo[player][pFrozen] = 0;
	GameTextForPlayer(player, "~w~You have been ~r~unfrozen~w~!", 3000, 1);
	SendFAdminMessageToAll("Administrator %s <%d> has unfrozen %s <%d>. Reason: "COL_RED"%s", playerName(playerid), playerid, playerName(player), player, reason);
	TogglePlayerControllable(player, true);

	return 1;
}

YCMD:countdown(playerid, params[], help)
{
	if(!adminCheck(playerid, 1)) return 0;
	
	if(help) return SendUsageMessage(playerid, "Start a countdown on the server.");

	new
		count,
		freeze
	;
	
	if(sscanf(params, "iI(0)", count, freeze))
	{
		SendUsageMessage(playerid, "/countdown <count> <OPT:freeze>");
		return 1;
	}
	
	if(sInfo[sCountDown] > 1)
	{
		SendErrorMessage(playerid, "A countdown is already in progress. You cannot start another countdown.");
		return 1;
	}
	
	if(count > 1000 || count < 1)
	{
		SendErrorMessage(playerid, "The count is out of range. Try again.");
		
		return 1;
	}
	
	if(freeze < 0 || freeze > 1)
	{
		SendUsageMessage(playerid, "/countdown <count> <freeze: 1 for yes, 0 for no>");
		return 1;
	}
	
	if(freeze == 1 && count > 50)
	{
		SendErrorMessage(playerid, "You are such an abusing admin.");
		return 1;
	}
	
	formatex(mysql_normalString, "[SERVER]: {FFFFFF}Administrator %s <%d> has started a countdown of %d %s freeze.", playerName(playerid), playerid, count, ((sInfo[sCountDownF])?("with"):("without")));
	SendClientMessageToAll(COLOR_SERVER, mysql_normalString);

	count += 1;
	
	switch(freeze)
	{
		case 0:
		{
			sInfo[sCountDown] = count;
			sInfo[sCountDownF] = 0;
		}
		case 1:
		{
			sInfo[sCountDown] = count;
			sInfo[sCountDownF] = 1;
			for(new i = 0; i < MAX_PLAYERS; i++)
			{
				if(!IsPlayerConnected(i)) continue;
				if(i == playerid) continue;
				TogglePlayerControllable(i, 0);
			}
		}
	}
	
	return 1;
}

YCMD:countdownex(playerid, params[], help)
{
	if(!adminCheck(playerid, 2)) return 0;
	
	if(help) return SendUsageMessage(playerid, "Start a countdown on the server.");

	new
		count,
		freeze
	;
	
	if(sscanf(params, "iI(0)", count, freeze))
	{
		SendUsageMessage(playerid, "/countdown <count> <OPT:freeze>");
		return 1;
	}
	
	if(sInfo[sCountDown] > 1)
	{
		SendErrorMessage(playerid, "A countdown is already in progress. You cannot start another countdown.");
		return 1;
	}
	
	if(count > 1000 || count < 1)
	{
		SendErrorMessage(playerid, "The count is out of range. Try again.");
		
		return 1;
	}
	
	if(freeze < 0 || freeze > 1)
	{
		SendUsageMessage(playerid, "/countdown <count> <freeze: 1 for yes, 0 for no>");
		return 1;
	}
	
	if(freeze == 1 && count > 50)
	{
		SendErrorMessage(playerid, "You are such an abusing admin.");
		return 1;
	}
	
	formatex(g_bString, "[SERVER]: "COL_WHITE"Administrator has started a countdown of %d %s freeze.", count, ((sInfo[sCountDownF])?("with"):("without")));
	formatex(mysql_normalString, "[SERVER]: {FFFFFF}Administrator %s <%d> has started a countdown of %d %s freeze.", playerName(playerid), playerid, count, ((sInfo[sCountDownF])?("with"):("without")));
	foreach(new x : Player)
	{
		if(pInfo[playerid][pAdminLevel] > 0)
		{
			SendClientMessage(x, COLOR_SERVER, mysql_normalString);
			continue;
		}
		SendClientMessage(x, COLOR_SERVER, g_bString);
	}

	count += 1;
	
	switch(freeze)
	{
		case 0:
		{
			sInfo[sCountDown] = count;
			sInfo[sCountDownF] = 0;
		}
		case 1:
		{
			sInfo[sCountDown] = count;
			sInfo[sCountDownF] = 1;
			for(new i = 0; i < MAX_PLAYERS; i++)
			{
				if(!IsPlayerConnected(i)) continue;
				if(i == playerid) continue;
				TogglePlayerControllable(i, 0);
			}
		}
	}
	
	return 1;
}

YCMD:acaps(playerid, params[], help)
{
	if(!adminCheck(playerid, 1)) return 0;

	if(help) return SendHelpMessage(playerid, "To disallow/allow caps usage for a player.");
	
	new ID;
	if(sscanf(params,"u",ID))
	{
	    SendUsageMessage(playerid,"/acaps <player name/ID>");
	    return 1;
	}

	if(!commandChecks(playerid, ID, .spawn = 0, .same = 0)) return 1;

	if(!pInfo[ID][pLowerText])
	{
		pInfo[ID][pLowerText] = 1;

    	format(g_string,sizeof(g_string),"[ADMIN] "COL_WHITE"Administrator %s <%d> has disallowed uppercase for %s <%d>.",playerName(playerid), playerid, playerName(ID),ID);
		SendClientMessageToAll(COLOR_ADMIN,g_string);

		#if defined USE_IRC
			format(g_string,sizeof(g_string),"9[ADMIN] Administrator has disallowed uppercase text for %s <%d>.",playerName(ID),ID);
			IRC_GroupSay(irc_botGroups[0],IRC_CHANNEL,g_string);

			format(g_string,sizeof(g_string),"9[ADMIN] Administrator %s <%d> has disallowed uppercase text for %s <%d>.",playerName(playerid), playerid, playerName(ID),ID);
			IRC_GroupSay(irc_botGroups[1],IRC_ADMINCHANNEL,g_string);
		#endif

		return 1;
	}

	pInfo[ID][pLowerText] = 0;

	format(g_string,sizeof(g_string),"[ADMIN] "COL_WHITE"Administrator has allowed uppercase text for %s(%d).",playerName(ID),ID);
	SendClientMessageToAll(COLOR_ADMIN,g_string);

	#if defined USE_IRC
		format(g_string,sizeof(g_string),"9[ADMIN] Administrator has allowed uppercase text for %s(%d).",playerName(ID),ID);
		IRC_GroupSay(irc_botGroups[0],IRC_CHANNEL,g_string);

		format(g_string,sizeof(g_string),"9[ADMIN] Administrator %s <%d> has disallowed uppercase text for %s <%d>.",playerName(playerid), playerid, playerName(ID),ID);
		IRC_GroupSay(irc_botGroups[1],IRC_ADMINCHANNEL,g_string);
	#endif

	return 1;
}

YCMD:acapsex(playerid, params[], help)
{
	if(!adminCheck(playerid, 2)) return 0;

	if(help) return SendHelpMessage(playerid, "To disallow/allow caps usage for a player.");
	
	new ID;
	if(sscanf(params,"u",ID))
	{
	    SendUsageMessage(playerid,"/acaps <player name/ID>");
	    return 1;
	}

	if(!commandChecks(playerid, ID, .spawn = 0, .same = 0)) return 1;

	if(!pInfo[ID][pLowerText])
	{
		pInfo[ID][pLowerText] = 1;

    	format(g_bString,sizeof(g_string),"[ADMIN] "COL_WHITE"Administrator %s <%d> has disallowed uppercase for %s <%d>.",playerName(playerid), playerid, playerName(ID),ID);
    	formatex(mysql_normalString, "[ADMIN] {FFFFFF}Administrator has disallowed uppercase for %s <%d>.", playerName(ID), ID);

    	foreach(new x : Player)
    	{
    		if(pInfo[x][pAdminLevel] > pInfo[playerid][pAdminLevel])
    		{
    			SendClientMessage(x, COLOR_ADMIN, g_bString);
    			continue;
    		}
    		SendClientMessage(x, COLOR_ADMIN, mysql_normalString);
    	}
    	#if defined USE_IRC
			format(g_string,sizeof(g_string),"9[ADMIN] Administrator has disallowed uppercase text for %s <%d>.",playerName(ID),ID);
			IRC_GroupSay(irc_botGroups[0],IRC_CHANNEL,g_string);

			format(g_string,sizeof(g_string),"9[ADMIN] Administrator %s <%d> has disallowed uppercase text for %s <%d>.",playerName(playerid), playerid, playerName(ID),ID);
			IRC_GroupSay(irc_botGroups[1],IRC_ADMINCHANNEL,g_string);
		#endif
		return 1;
	}

	pInfo[ID][pLowerText] = 0;

	format(g_string,sizeof(g_string),"[ADMIN] "COL_WHITE"Administrator has allowed uppercase text for %s(%d).",playerName(ID),ID);
	SendClientMessageToAll(COLOR_ADMIN,g_string);

	#if defined USE_IRC
		format(g_string,sizeof(g_string),"9[ADMIN] Administrator has allowed uppercase text for %s(%d).",playerName(ID),ID);
		IRC_GroupSay(irc_botGroups[0],IRC_CHANNEL,g_string);

		format(g_string,sizeof(g_string),"9[ADMIN] Administrator %s <%d> has disallowed uppercase text for %s <%d>.",playerName(playerid), playerid, playerName(ID),ID);
		IRC_GroupSay(irc_botGroups[1],IRC_ADMINCHANNEL,g_string);
	#endif

	return 1;
}

YCMD:afreezeex(playerid, params[], help)
{
	if(!adminCheck(playerid)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to freeze/unfreeze a player.");
		return 1;
	}

	new player,
		reason[32]
	;

	if(sscanf(params, "uS[32]", player, reason))
	{
		SendUsageMessage(playerid, "afreezeex <player name / playerid> (reason)");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0, .same = 0)) return 1;
	
	new t_string[144];	

	format(t_string, sizeof(t_string), "Administrator has %s %s <%d>. Reason: "COL_RED"%s.", ((pInfo[player][pFrozen]) ? ("unfrozen") : ("frozen")), playerName(player), player, reason);
	format(g_string, sizeof(g_string), "Administrator %s <%d> has %s %s <%d>. Reason: "COL_RED"%s.", playerName(playerid), playerid, ((pInfo[player][pFrozen]) ? ("unfrozen") : ("frozen")), playerName(player), player, reason);

	if(pInfo[player][pFrozen])
	{
		pInfo[player][pFrozen] = 1;
		GameTextForPlayer(player, "~w~You have been ~r~frozen~w~!", 3000, 1);
		TogglePlayerControllable(player, false);
	}

	else
	{
		pInfo[player][pFrozen] = 0;
		GameTextForPlayer(player, "~w~You have been ~r~unfrozen~w~!", 3000, 1);
		TogglePlayerControllable(player, true);
	}

	foreach(new x : Player)
	{
		if(pInfo[x][pAdminLevel] < 1)
			SendClientMessage(x, COLOR_ADMIN, t_string);

		else
			SendClientMessage(x, COLOR_ADMIN, g_string);
	}

	return 1;
}

YCMD:amute(playerid, params[], help)
{
	if(!adminCheck(playerid)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to mute a player from talking in the main chat.");
		return 1;
	}

	new player,
		stime,
		reason[32]
	;

	if(sscanf(params, "uI(60)S[32]", player, stime, reason))
	{
		SendUsageMessage(playerid, "mute <player name / playerid> (time: 60 seconds) (reason)");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0)) return 1;

	pInfo[player][pMuted] = 1;
	pInfo[player][pMuteTime] = stime;

	GameTextForPlayer(player, "~w~You have been ~r~muted~w~!", 3000, 1);
	SendFAdminMessageToAll("Administrator %s <%d> has muted %s <%d> for %d seconds. Reason: "COL_RED"%s", playerName(playerid), playerid, playerName(player), player, stime, reason);

	return 1;
}

YCMD:amuteex(playerid, params[], help)
{
	if(!adminCheck(playerid)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to mute a player from the chat without sending a message to all.");
		return 1;
	}

	new player,
		stime,
		reason[32]
	;

	if(sscanf(params, "uI(60)S[32]", player, stime, reason))
	{
		SendUsageMessage(playerid, "mute <player name / playerid> (time: 60 seconds) (reason)");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0)) return 1;

	pInfo[player][pMuted] = 1;
	pInfo[player][pMuteTime] = stime;

	new t_string[144];	

	GameTextForPlayer(player, "~w~You have been ~r~muted~w~!", 3000, 1);
	formatex(t_string, "Administrator has muted %s <%d> for %d seconds. Reason: "COL_RED"%s", playerName(player), player, stime, reason);
	formatex(g_string, "Administrator %s <%d> has muted %s <%d> for %d seconds. Reason: "COL_RED"%s", playerName(playerid), playerid, playerName(player), player, stime, reason);

	foreach(new x : Player)
	{
		if(pInfo[x][pAdminLevel] < 1)
			SendClientMessage(x, COLOR_ADMIN, t_string);

		else
			SendClientMessage(x, COLOR_ADMIN, g_string);
	}

	return 1;
}

YCMD:aunmute(playerid, params[], help)
{
	if(!adminCheck(playerid)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to unmute a player who's already muted.");
		return 1;
	}

	new player;

	if(sscanf(params, "u", player))
	{
		SendUsageMessage(playerid, "unmute <player name / playerid>");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0)) return 1;

	pInfo[player][pMuted] = 0;
	pInfo[player][pMuteTime] = 0;

	SendFAdminMessageToAll("Administrator %s <%d> has unmuted %s <%d>.", playerName(playerid), playerid, playerName(player), player);

	return 1;
}

YCMD:aunmuteex(playerid, params[], help)
{
	if(!adminCheck(playerid)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to unmuted without sending a message to all.");
		return 1;
	}

	new player;

	if(sscanf(params, "u", player))
	{
		SendUsageMessage(playerid, "unmute <player name / playerid>");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0)) return 1;

	pInfo[player][pMuted] = 0;
	pInfo[player][pMuteTime] = 0;

	new t_string[144];	

	formatex(t_string, "Administrator has unmuted %s <%d>.", playerName(player), player);
	formatex(g_string, "Administrator %s <%d> has unmuted %s <%d>.", playerName(playerid), playerid, playerName(player), player);

	foreach(new x : Player)
	{
		if(pInfo[x][pAdminLevel] < 1)
			SendClientMessage(x, COLOR_ADMIN, t_string);

		else
			SendClientMessage(x, COLOR_ADMIN, g_string);
	}

	return 1;
}

YCMD:awarn(playerid, params[], help)
{
	if(!adminCheck(playerid)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to warn a player for breaking a rule.");
		return 1;
	}

	new player,
		reason
	;

	if(sscanf(params, "us[32]", player, reason))
	{
		SendUsageMessage(playerid, "warn <player name / playerid> <reason>");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0)) return 1;

	if(pInfo[player][pBeingKicked])
	{
		SendErrorMessage(playerid, "The specified player is being kicked by the server shortly.");
		return 1;
	}

	pInfo[playerid][pTotalaWarns]++;
	pInfo[player][pTotalWarns]++;
	pInfo[player][pWarns]++;

	SendFAdminMessageToAll("Administrator %s <%d> has warned %s <%d> (%d/3). Reason "COL_RED"%s", playerName(playerid), playerid, playerName(player), player, pInfo[player][pWarns], reason);
	GameTextForPlayer(player, "~w~You have been ~r~warned~w~!", 3000, 1);

	// IRC_Message

	if(pInfo[player][pWarns] >= 3)
	{
		pInfo[player][pBeingKicked] = 1;
	}

	return 1;
}

YCMD:lastseen(playerid, params[], help)
{
	if(help) return SendUsageMessage(playerid, "Track when a player was last online.");

	if(GetPlayerScore(playerid) < 100)
	{
		SendErrorMessage(playerid, "You need at least 100 score to execute this command.");
		return 1;
	}

	if(isnull(params))
	{
		SendUsageMessage(playerid, "/lastseen <player name>");
		return 1;
	}

	if(strlen(params) > 20)
	{
		SendErrorMessage(playerid, "Maximum name length (20) exceeded.");
		return 1;
	}

	mysql_escape_string(params, params, 24);

	formatex(g_string, "SELECT TIMESTAMPDIFF(HOUR, `playerLastConnection`, NOW()) FROM `sona_playerAccounts` WHERE `playerName` = '%s'", params);
	mysql_function_query(dbHandle, g_string, true, "onLastSeenCheck", "is", playerid, params);

	return 1;
}

YCMD:checkban(playerid, params[], help)
{
	if(!adminCheck(playerid, 1)) return 0;

	if(help) return SendHelpMessage(playerid, "Check a player ban by name.");

	if(isnull(params))
	{
		SendUsageMessage(playerid, "/acheckban <player name>");
		return 1;
	}

	if(strlen(params) > 20)
	{
		SendErrorMessage(playerid, "Maximum name length (20) exceeded.");
		return 1;
	}

	mysql_escape_string(params, params, 24);

	formatex(mysql_mediumString, "SELECT `banID`, `banName`, `banIP`, `bannerName`, `banReason`, TIMESTAMPDIFF(HOUR, NOW(), DATE_ADD(`banDay`, INTERVAL `banTime` HOUR)) FROM `sona_playerBans` WHERE `banName` = '%s' ORDER BY `banID` DESC", params);
	mysql_function_query(dbHandle, mysql_mediumString, true, "onAdminBanQuery", "iiis", playerid, 1, -1, params);
	return 1;
}

YCMD:checkbanid(playerid, params[], help)
{
	if(!adminCheck(playerid, 1)) return 0;

	if(help) return SendHelpMessage(playerid, "Check a player ban by ID.");

	if(isnull(params))
	{
		SendUsageMessage(playerid, "/adcheckbanid <ban ID>");
		return 1;
	}

	if(!IsNumeric(params))
	{
		SendUsageMessage(playerid, "/adcheckbanid <ban ID>");
		return 1;
	}

	new
		tempVar = strval(params)
	;

	if(tempVar < 1)
	{
		SendErrorMessage(playerid, "WHADUP?");
		return 1;
	}

	formatex(mysql_mediumString, "SELECT `banID`, `banName`, `banIP`, `bannerName`, `banReason`, TIMESTAMPDIFF(HOUR, NOW(), DATE_ADD(`banDay`, INTERVAL `banTime` HOUR)) FROM `sona_playerBans` WHERE `banID` = '%d'", tempVar);
	mysql_function_query(dbHandle, mysql_mediumString, true, "onAdminBanQuery", "iiis", playerid, 0, tempVar, "");
	return 1;
}

YCMD:checkbanip(playerid, params[], help)
{
	if(!adminCheck(playerid, 1)) return 0;

	if(help) return SendHelpMessage(playerid, "Check a player ban by IP.");

	if(isnull(params))
	{
		SendUsageMessage(playerid, "/adcheckbanid <ban IP>");
		return 1;
	}

	if(strlen(params) > 15)
	{
		SendErrorMessage(playerid, "Maximum IP length (15) exceeded.");
		return 1;
	}

	new
		dotCounter
	;

	for(new i = 0, j = strlen(params); i != j; i++)
	{
		if(params[i] != '.') continue;
		dotCounter++;
	}

	if(dotCounter != 3)
	{
	 	SendErrorMessage(playerid, "I don't see an IP there.");
		return 1;
	}

	mysql_escape_string(params, params, 24);

	formatex(mysql_mediumString, "SELECT `banID`, `banName`, `banIP`, `bannerName`, `banReason`, TIMESTAMPDIFF(HOUR, NOW(), DATE_ADD(`banDay`, INTERVAL `banTime` HOUR)) FROM `sona_playerBans` WHERE `banIP` = '%s' ORDER BY `banID` DESC", params);
	mysql_function_query(dbHandle, mysql_mediumString, true, "onAdminBanQuery", "iiis", playerid, 2, -1, params);
	return 1;
}

YCMD:awarnex(playerid, params[], help)
{
	if(!adminCheck(playerid)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to warn a player for breaking a rule without sending a message to all.");
		return 1;
	}

	new player,
		reason
	;

	if(sscanf(params, "us[32]", player, reason))
	{
		SendUsageMessage(playerid, "warnex <player name / playerid> <reason>");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0)) return 1;

	if(pInfo[player][pBeingKicked])
	{
		SendErrorMessage(playerid, "The specified player is being kicked by the server shortly.");
		return 1;
	}

	pInfo[playerid][pTotalaWarns]++;
	pInfo[player][pTotalWarns]++;
	pInfo[player][pWarns]++;

	new t_string[144];

	GameTextForPlayer(player, "~w~You have been ~r~warned~w~!", 3000, 1);
	formatex(t_string, "Administrator has warned %s <%d> (%d/3). Reason: "COL_RED"%s", playerName(player), player, pInfo[player][pWarns], reason);
	formatex(g_string, "Administrator %s <%d> has warned %d <%d> (%d/3). Reason: "COL_RED"%s", playerName(playerid), playerid, playerName(player), player, pInfo[player][pWarns], reason);

	foreach(new x : Player)
	{
		if(pInfo[x][pAdminLevel] < 1)
			SendClientMessage(x, COLOR_ADMIN, t_string);

		else
			SendClientMessage(x, COLOR_ADMIN, g_string);
	}

	// IRC_Message

	if(pInfo[player][pWarns] >= 3)
	{
		pInfo[player][pBeingKicked] = 1;
	}

	return 1;
}

YCMD:akill(playerid, params[], help)
{
	if(!adminCheck(playerid, 1)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to kill a player.");
		return 1;
	}

	new
		player,
		reason[32]
	;

	if(sscanf(params, "uS(Not specified)[32]", player, reason))
	{
		SendUsageMessage(playerid, "akill <player name / playerid> (reason)");
		return 1;
	}

	if(!commandChecks(playerid, player, .same = 0)) return 1;

	SetPlayerHealth(player, 0.00);
	SendFAdminMessageToAll("Administrator %s <%d> has killed %s <%d>. Reason: "COL_RED"%s", playerName(playerid), playerid, playerName(player), player, reason);

	return 1;
}

YCMD:akillex(playerid, params[], help)
{
	if(!adminCheck(playerid, 3)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to kill a player without sending a message to all.");
		return 1;
	}

	new
		player,
		reason[32]
	;

	if(sscanf(params, "uS(Not specified)[32]", player, reason))
	{
		SendUsageMessage(playerid, "akillex <player name / playerid> (reason)");
		return 1;
	}

	if(!commandChecks(playerid, player, .same = 0)) return 1;

	SetPlayerHealth(player, 0.00);
	SendFAdminMessageToAdmins("Administrator %s <%d> has killed %s <%d>. Reason: "COL_RED"%s", playerName(playerid), playerid, playerName(player), player, reason);
	SendFAdminMessage(player, "Administrator has killed you. Reason: "COL_RED"%s", reason);

	return 1;
}

YCMD:aexplode(playerid, params[], help)
{
	if(!adminCheck(playerid, 2)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to explode a player.");
		return 1;
	}

	new
		player,
		reason[32]
	;

	if(sscanf(params, "uS(Not specified)[32]", player, reason))
	{
		SendUsageMessage(playerid, "aexplode <player name / playerid> (reason)");
		return 1;
	}

	if(!commandChecks(playerid, player)) return 1;

    new Float:tPos[3];
	GetPlayerPos(player, tPos[0], tPos[1], tPos[2]);
	CreateExplosion(tPos[0], tPos[1], tPos[2], 6, 10.0);

	SendFAdminMessageToAll("Administrator %s <%d> has exploded %s <%d>. Reason: "COL_RED"%s", playerName(playerid), playerid, playerName(player), player, reason);

	return 1;
}

YCMD:aexplodeex(playerid, params[], help)
{
	if(!adminCheck(playerid, 3)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to explode a player without sending a message to all.");
		return 1;
	}

	new
		player,
		reason[32]
	;

	if(sscanf(params, "uS(Not specified)[32]", player, reason))
	{
		SendUsageMessage(playerid, "aexplodeex <player name / playerid> (reason)");
		return 1;
	}

	if(!commandChecks(playerid, player)) return 1;


    new Float:tPos[3];
	GetPlayerPos(player, tPos[0], tPos[1], tPos[2]);
	CreateExplosion(tPos[0], tPos[1], tPos[2], 6, 10.0);

	SendFAdminMessageToAdmins("Administrator %s <%d> has exploded %s <%d>. Reason: "COL_RED"%s", playerName(playerid), playerid, playerName(player), player, reason);
	SendFAdminMessage(player, "Administrator has exploded you. Reason: "COL_RED"%s", reason);

	return 1;
}

YCMD:aslap(playerid, params[], help)
{
	if(!adminCheck(playerid, 2)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to slap a player.");
		return 1;
	}

	new
		player,
		reason[32]
	;

	if(sscanf(params, "uS(Not specified)[32]", player, reason))
	{
		SendUsageMessage(playerid, "aslap <player name / playerid> (reason)");
		return 1;
	}

	if(!commandChecks(playerid, player, .same = 0)) return 1;

    new Float:tPos[3];
	GetPlayerPos(player, tPos[0], tPos[1], tPos[2]);
	SetPlayerPos(player, tPos[0], tPos[1], tPos[2] + 20.00);

	SendFAdminMessageToAll("Administrator %s <%d> has slapped %s <%d>. Reason: "COL_RED"%s", playerName(playerid), playerid, playerName(player), player, reason);

	return 1;
}

YCMD:aslapex(playerid, params[], help)
{
	if(!adminCheck(playerid, 3)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to slap a player without sending a message to all.");
		return 1;
	}

	new
		player,
		reason[32]
	;

	if(sscanf(params, "uS(Not specified)[32]", player, reason))
	{
		SendUsageMessage(playerid, "aslapex <player name / playerid> (reason)");
		return 1;
	}

	if(!commandChecks(playerid, player, .same = 0)) return 1;


    new Float:tPos[3];
	GetPlayerPos(player, tPos[0], tPos[1], tPos[2]);
	SetPlayerPos(player, tPos[0], tPos[1], tPos[2] + 20.00);
	
	SendFAdminMessageToAdmins("Administrator %s <%d> has slapped %s <%d>. Reason: "COL_RED"%s", playerName(playerid), playerid, playerName(player), player, reason);
	SendFAdminMessage(player, "Administrator has slapped you. Reason: "COL_RED"%s", reason);

	return 1;
}

YCMD:gotox(playerid, params[], help)
{
	if(!adminCheck(playerid, 2)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to teleport to a given coordinate.");
		return 1;
	}

	new
		Float:posDefined[4]
	;

	if(sscanf(params, "p<,>fffF(0.00)", posDefined[0], posDefined[1], posDefined[2], posDefined[3]))
	{
		SendUsageMessage(playerid, "gotox <X> <Y> <Z> (angle)");
		return 1;
	}

	SetPlayerPos(playerid, posDefined[0], posDefined[1], posDefined[2]);
	SetPlayerFacingAngle(playerid, posDefined[3]);

	SendFAdminMessage(playerid, "You have been teleported to %s.", params);
	
	return 1;
}

YCMD:get(playerid, params[], help)
{
	if(!adminCheck(playerid, 2)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to teleport another player to you.");
		return 1;
	}

	new
		Float:posDefined[3],
		player
	;

	if(sscanf(params, "u", player))
	{
		SendUsageMessage(playerid, "get <player name / playerid>");
		return 1;
	}

	if(!commandChecks(playerid, player, .higheradmin = 0)) return 1;

	GetPlayerPos(playerid, posDefined[0], posDefined[1], posDefined[2]);
	SetPlayerPos(player, posDefined[0] + 1, posDefined[1] + 1, posDefined[2]);
	SetPlayerInterior(player, GetPlayerInterior(playerid));
	SetPlayerVirtualWorld(player, GetPlayerVirtualWorld(playerid));

	SendFAdminMessage(playerid, "You have teleported "COL_GRAY"%s <%d>{FFFFFF} to you.", playerName(player), player);
	SendFAdminMessage(player, "You have been teleported to %s <%d> by them.", playerName(playerid), playerid);

	return 1;
}

YCMD:getex(playerid, params[], help)
{
	if(!adminCheck(playerid, 3)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to teleport another player to you without letting them know.");
		return 1;
	}

	new
		Float:posDefined[3],
		player
	;

	if(sscanf(params, "u", player))
	{
		SendUsageMessage(playerid, "getex <player name / playerid>");
		return 1;
	}

	if(!commandChecks(playerid, player, .higheradmin = 0)) return 1;

	GetPlayerPos(playerid, posDefined[0], posDefined[1], posDefined[2]);
	SetPlayerPos(player, posDefined[0] + 1, posDefined[1] + 1, posDefined[2]);
	SetPlayerInterior(player, GetPlayerInterior(playerid));
	SetPlayerVirtualWorld(player, GetPlayerVirtualWorld(playerid));

	SendFAdminMessage(playerid, "You have teleported %s <%d> to you.", playerName(player), player);

	return 1;
}

YCMD:goto(playerid, params[], help)
{
	if(!adminCheck(playerid, 2)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to teleport to another player.");
		return 1;
	}

	new
		Float:posDefined[3],
		player
	;

	if(sscanf(params, "u", player))
	{
		SendUsageMessage(playerid, "goto <player name / playerid>");
		return 1;
	}

	if(!commandChecks(playerid, player, .higheradmin = 0)) return 1;

	GetPlayerPos(player, posDefined[0], posDefined[1], posDefined[2]);
	SetPlayerPos(playerid, posDefined[0] + 1, posDefined[1] + 1, posDefined[2]);
	SetPlayerInterior(playerid, GetPlayerInterior(player));
	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(player));

	SendFAdminMessage(playerid, "You have teleported to %s <%d>.", playerName(player), player);
	SendFAdminMessage(player, "%s <%d> has teleported to you.", playerName(playerid), playerid);
	
	return 1;
}

YCMD:gotoex(playerid, params[], help)
{
	if(!adminCheck(playerid, 3)) return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to teleport to another player without letting them know.");
		return 1;
	}

	new
		Float:posDefined[3],
		player
	;

	if(sscanf(params, "u", player))
	{
		SendUsageMessage(playerid, "gotoex <player name / playerid>");
		return 1;
	}

	if(!commandChecks(playerid, player, .higheradmin = 0)) return 1;

	GetPlayerPos(player, posDefined[0], posDefined[1], posDefined[2]);
	SetPlayerPos(playerid, posDefined[0] + 1, posDefined[1] + 1, posDefined[2]);
	SetPlayerInterior(playerid, GetPlayerInterior(player));
	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(player));

	SendFAdminMessage(playerid, "You have teleported to "COL_GRAY"%s <%d>{FFFFFF}.", playerName(player), player);
	
	return 1;
}

YCMD:aannounce(playerid, params[], help)
{
	if(!adminCheck(playerid))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to announce something on the main screen.");
		return 1;
	}

	if(isnull(params))
	{
		SendUsageMessage(playerid, "announce <text>");
		return 1;
	}

	GameTextForAll(params,5000,3);

	return 1;
}

YCMD:asay(playerid, params[], help)
{
	if(!adminCheck(playerid))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to chat as an admin.");
		return 1;
	}

	if(isnull(params))
	{
		SendUsageMessage(playerid, "adsay <text>");
		return 1;
	}

	mysql_log_chat(playerid, params);

	#if defined USE_IRC
		formatex(g_bString, "9,15[ADMIN MESSAGE]: <%d> ADMIN: %s", pInfo[playerid][pAdminLevel], params);
		IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_bString);

		formatex(g_bString, "9,15[ADMIN MESSAGE]: <%d> %s: %s", playerid, playerName(playerid), params);
		IRC_GroupSay(irc_botGroups[1], IRC_ADMINCHANNEL, g_bString);
	#endif

	new poszi;

	foreach(new x : Player)
	{
		if(x != playerid)
		{
			poszi = strfind(params, playerName(x));
			if(poszi != -1)
			{
			    strins(params, "{FFFFFF}", poszi + strlen(playerName(x)), 129);
				strins(params, "{AFAFAF}", poszi, 128);
			}
		}
	}	

	formatex(g_string, "Administrator <%02d>: {FFFFFF}%s", pInfo[playerid][pAdminLevel], params);
	SendClientMessageToAll(COLOR_ADMIN, g_string);

	return 1;
}

YCMD:vsay(playerid, params[], help)
{
	if(pInfo[playerid][pVIPLevel] < 1)
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to chat as a VIP.");
		return 1;
	}

	if(isnull(params))
	{
		SendUsageMessage(playerid, "vsay <text>");
		return 1;
	}

	mysql_log_chat(playerid, params);

	#if defined USE_IRC
		formatex(g_bString, "9,15[VIP CHAT]: <%d> %d%s: %s", playerid, ((gTeam[playerid] == TEAM_COP) ? (12) : (4)), playerName(playerid), params);
		IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_bString);
	#endif
	
	new poszi;

	foreach(new x : Player)
	{
		if(x != playerid)
		{
			poszi = strfind(params, playerName(x));
			if(poszi != -1)
			{
			    strins(params, "{FFFFFF}", poszi + strlen(playerName(x)), 129);
				strins(params, "{AFAFAF}", poszi, 128);
			}
		}
	}	

	formatex(g_string, "<%02d> [VIP] %s: {FFFFFF}%s", playerid, playerName(playerid), params);
	SendClientMessageToAll(COLOR_VIP, g_string);

	return 1;
}

YCMD:akick(playerid, params[], help)
{
	if(!adminCheck(playerid, 2))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to kick a player from the server.");
		return 1;
	}

	new player,
		reason[32]
	;

	if(sscanf(params, "uS(Not Specified)[32]", player, reason))
	{
		SendUsageMessage(playerid, "kick <player name / playerid> (reason)");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0)) return 1;

	pInfo[playerid][pTotalaKicks]++;
	pInfo[player][pTotalKicks]++;
	pInfo[player][pBeingKicked] = 1;
	SendFAdminMessageToAll("Administrator %s <%d> has kicked %s <%d> from the server. Reason: "COL_RED"%s", playerName(playerid), playerid, playerName(player), player, reason);

	// IRC_Message

	return 1;
}

YCMD:aheal(playerid, params[], help)
{
	if(!adminCheck(playerid, 2))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to restore a player's health.");
		return 1;
	}

	new player;

	if(sscanf(params, "u", player))
	{
		SendUsageMessage(playerid, "heal <player name / playerid>");
		return 1;
	}

	if(!commandChecks(playerid, player, .same = 0)) return 1;

	SetPlayerHealth(player, 100.0);
	SendFAdminMessageToAll("Administrator %s <%d> has healed %s <%d>.", playerName(playerid), playerid, playerName(player), player);
	return 1;
}

YCMD:ahealex(playerid, params[], help)
{
	if(!adminCheck(playerid, 3))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to restore a player's health without sending a message to all.");
		return 1;
	}

	new player;

	if(sscanf(params, "u", player))
	{
		SendUsageMessage(playerid, "healex <player name / playerid>");
		return 1;
	}

	if(!commandChecks(playerid, player, .same = 0)) return 1;

	SetPlayerHealth(player, 100.0);
	SendFAdminMessageToAdmins("Administrator %s <%d> has healed %s <%d>.", playerName(playerid), playerid, playerName(player), player);
	SendClientMessage(player, COLOR_ADMIN, "[ADMIN]: {FFFFFF}Administrator has healed you.");
	return 1;
}

YCMD:ahealall(playerid, params[], help)
{
	if(!adminCheck(playerid, 3))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to restore all connected players' health.");
		return 1;
	}

	foreach(new x : Player) if(pInfo[x][pSpawned]) SetPlayerHealth(x, 100.0);
	SendFAdminMessageToAll("Administrator %s <%d> has healed eveyone.", playerName(playerid), playerid);

	return 1;
}

YCMD:ahealallex(playerid, params[], help)
{
	if(!adminCheck(playerid, 4))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to restore all connected players' health without sending a message.");
		return 1;
	}

	formatex(g_string, "Administrator %s <%d> has healed everyone.", playerName(playerid), playerid);

	foreach(new x : Player)
	{
		SetPlayerHealth(x, 100.0);

		if(pInfo[x][pAdminLevel] < 1)
			SendClientMessage(x, COLOR_ADMIN, "Administrator has healed everyone");

		else
			SendClientMessage(x, COLOR_ADMIN, g_string);
	}

	return 1;
}

YCMD:aarmour(playerid, params[], help)
{
	if(!adminCheck(playerid, 2))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to restore a player's armour.");
		return 1;
	}

	new player;

	if(sscanf(params, "u", player))
	{
		SendUsageMessage(playerid, "armour <player name / playerid>");
		return 1;
	}

	if(!commandChecks(playerid, player, .same = 0)) return 1;

	SetPlayerArmour(player, 100.0);
	SendFAdminMessageToAll("Administrator %s <%d> has armour'ed %s <%d>.", playerName(playerid), playerid, playerName(player), player);
	return 1;
}

YCMD:aarmourex(playerid, params[], help)
{
	if(!adminCheck(playerid, 3))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to restore a player's armour without sending a message to all.");
		return 1;
	}

	new player;

	if(sscanf(params, "u", player))
	{
		SendUsageMessage(playerid, "armourex <player name / playerid>");
		return 1;
	}

	if(!commandChecks(playerid, player, .same = 0)) return 1;

	SetPlayerArmour(player, 100.0);
	SendFAdminMessageToAdmins("Administrator %s <%d> has armour'ed %s <%d>.", playerName(playerid), playerid, playerName(player), player);
	SendClientMessage(player, COLOR_ADMIN, "[ADMIN]: {FFFFFF}Administrator has armour'ed you.");
	return 1;
}

YCMD:aarmourall(playerid, params[], help)
{
	if(!adminCheck(playerid, 3))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to restore all connected players' armour.");
		return 1;
	}

	foreach(new x : Player) if(pInfo[x][pSpawned]) SetPlayerArmour(x, 100.0);
	SendFAdminMessageToAll("Administrator %s <%d> has armour'ed eveyone.", playerName(playerid), playerid);

	return 1;
}

YCMD:aarmourallex(playerid, params[], help)
{
	if(!adminCheck(playerid, 4))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to restore all connected players' armour without sending a message.");
		return 1;
	}

	formatex(g_string, "Administrator %s <%d> has armour'ed everyone.", playerName(playerid), playerid);

	foreach(new x : Player)
	{
		SetPlayerArmour(x, 100.0);

		if(pInfo[x][pAdminLevel] < 1)
			SendClientMessage(x, COLOR_ADMIN, "Administrator has armour'ed everyone");

		else
			SendClientMessage(x, COLOR_ADMIN, g_string);
	}

	return 1;
}

YCMD:arestore(playerid, params[], help)
{
	if(!adminCheck(playerid, 2))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to restore a player's health and armour.");
		return 1;
	}

	new player;

	if(sscanf(params, "u", player))
	{
		SendUsageMessage(playerid, "restore <player name / playerid>");
		return 1;
	}

	if(!commandChecks(playerid, player, .same = 0)) return 1;

	SetPlayerHealth(player, 100.0);
	SetPlayerArmour(player, 100.0);
	SendFAdminMessageToAll("Administrator %s <%d> has restored %s <%d>'s health and armour.", playerName(playerid), playerid, playerName(player), player);
	return 1;
}

YCMD:arestoreex(playerid, params[], help)
{
	if(!adminCheck(playerid, 3))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to restore a player's health and armour without sending a message to all.");
		return 1;
	}

	new player;

	if(sscanf(params, "u", player))
	{
		SendUsageMessage(playerid, "restoreex <player name / playerid>");
		return 1;
	}

	if(!commandChecks(playerid, player, .same = 0)) return 1;

	SetPlayerHealth(player, 100.0);
	SetPlayerArmour(player, 100.0);
	SendFAdminMessageToAdmins("Administrator %s <%d> has restored %s <%d>'s health and armpur.", playerName(playerid), playerid, playerName(player), player);
	SendClientMessage(player, COLOR_ADMIN, "[ADMIN]: {FFFFFF}Administrator has restored your health and armour.");
	return 1;
}

YCMD:arestoreall(playerid, params[], help)
{
	if(!adminCheck(playerid, 3))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to restore all connected players' health and armour.");
		return 1;
	}

	foreach(new x : Player) if(pInfo[x][pSpawned])
	{
		SetPlayerHealth(x, 100.0);
		SetPlayerArmour(x, 100.0);
	}

	SendFAdminMessageToAll("Administrator %s <%d> has restored everyone's armour and health.", playerName(playerid), playerid);

	return 1;
}

YCMD:arestoreallex(playerid, params[], help)
{
	if(!adminCheck(playerid, 4))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to restore all connected players' armour and health without sending a message.");
		return 1;
	}

	formatex(g_string, "Administrator %s <%d> has restored everyone's armour and health.", playerName(playerid), playerid);

	foreach(new x : Player)
	{
		SetPlayerHealth(x, 100.0);
		SetPlayerArmour(x, 100.0);

		if(pInfo[x][pAdminLevel] < 1)
			SendClientMessage(x, COLOR_ADMIN, "Administrator has restored everyone's armour and health.");

		else
			SendClientMessage(x, COLOR_ADMIN, g_string);
	}

	return 1;
}

YCMD:agiveweapon(playerid, params[], help)
{
	if(!adminCheck(playerid, 2))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to give a player a weapon.");
		return 1;
	}
	
	new player,
		weapon[12],
		ammo
	;

	if(sscanf(params, "us[12] I(500)", player, weapon, ammo))
	{
		SendUsageMessage(playerid, "giveweapon <player name / playerid> <weapon name / weaponid> (ammo)");
		return 1;
	}

	if(!commandChecks(playerid, player, .same = 0)) return 1;

	new weaponid;

	if(!IsNumeric(weapon))
	{
	    for(new i = 0; i < 47; i++)
		{
		    if(strfind(deathReason[i], weapon, true) > -1)
		    {
		        weaponid = i;
		        break;
		    }
		}
	}

	else weaponid = strval(weapon);
	
	if(weaponid > 46 || weaponid < 0)
	{
		SendErrorMessage(playerid, "Unknown weapoin id.");
		return 1;
	}

	GivePlayerWeapon(player, weaponid, ammo);
	SendFAdminMessageToAll("Administrator %s <%d> has given %s <%d> a(n) %s with %d ammo.", playerName(playerid), playerid, playerName(player), player, deathReason[weaponid], ammo);

	return 1;
}

YCMD:agiveweaponex(playerid, params[], help)
{
	if(!adminCheck(playerid, 3))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to give a player a weapon without sending a message to all.");
		return 1;
	}
	
	new player,
		weapon[12],
		ammo
	;

	if(sscanf(params, "us[12] I(500)", player, weapon, ammo))
	{
		SendUsageMessage(playerid, "giveweaponex <player name / playerid> <weapon name / weaponid> (ammo)");
		return 1;
	}

	if(!commandChecks(playerid, player, .same = 0)) return 1;

	new weaponid;

	if(!IsNumeric(weapon))
	{
	    for(new i = 0; i < 47; i++)
		{
		    if(strfind(deathReason[i], weapon, true) > -1)
		    {
		        weaponid = i;
		        break;
		    }
		}
	}

	else weaponid = strval(weapon);
	
	if(weaponid > 46 || weaponid < 0)
	{
		SendErrorMessage(playerid, "Unknown weapoin id.");
		return 1;
	}

	GivePlayerWeapon(player, weaponid, ammo);
	SendFAdminMessageToAdmins("Administrator %s <%d> has given %s <%d> a(n) %s with %d ammo.", playerName(playerid), playerid, playerName(player), player, deathReason[weaponid], ammo);
	SendFAdminMessage(player, "Administrator has given you a(n) %s with %d ammo.", deathReason[weaponid], ammo);

	// IRC_Message
	return 1;
}

YCMD:akickex(playerid, params[], help)
{
	if(!adminCheck(playerid, 3))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to kick a player from the server without revealing your identity.");
		return 1;
	}

	new player,
		reason[32]
	;

	if(sscanf(params, "uS(Not Specified)[32]", player, reason))
	{
		SendUsageMessage(playerid, "kickex <player name / playerid> (reason)");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0)) return 1;

	pInfo[playerid][pTotalaKicks]++;
	pInfo[player][pTotalKicks]++;
	pInfo[player][pBeingKicked] = 1;

	new t_string[144];

	formatex(t_string, "Administrator has kicked %s <%d> from the server. Reason: "COL_RED"%s", playerName(player), player, reason);
	formatex(g_string, "Administrator %s <%d> has kicked %d <%d> from the server. Reason: "COL_RED"%s", playerName(playerid), playerid, playerName(player), player, reason);

	foreach(new x : Player)
	{
		if(pInfo[x][pAdminLevel] < 1)
			SendClientMessage(x, COLOR_ADMIN, t_string);

		else
			SendClientMessage(x, COLOR_ADMIN, g_string);
	}

	// IRC_Message

	return 1;
}

YCMD:asetscore(playerid, params[], help)
{
	if(!adminCheck(playerid, 3))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to set a player's score to a certain amount.");
		return 1;
	}

	new player,
		amount
	;

	if(sscanf(params, "ui", player, amount))
	{
		SendUsageMessage(playerid, "setscore <player name / playerid> <amount>");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0, .same = 0)) return 1;

	SetPlayerScore(player, amount);
	SendFAdminMessageToAll("Administrator %s <%d> has set %s <%d>'s score to %d.", playerName(playerid), playerid, playerName(player), player, amount);

	// IRC_Message

	return 1;
}

YCMD:asetscoreex(playerid, params[], help)
{
	if(!adminCheck(playerid, 4))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to set a player's score to a certain amount without sending a message.");
		return 1;
	}

	new player,
		amount
	;

	if(sscanf(params, "ui", player, amount))
	{
		SendUsageMessage(playerid, "setscoreex <player name / playerid> <amount>");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0, .same = 0)) return 1;

	SetPlayerScore(player, amount);
	SendFAdminMessageToAdmins("Administrator %s <%d> has set %s <%d>'s score to %d.", playerName(playerid), playerid, playerName(player), player, amount);

	// IRC_Message

	return 1;
}

YCMD:agivescore(playerid, params[], help)
{
	if(!adminCheck(playerid, 3))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to give a player a certain amount of score.");
		return 1;
	}

	new player,
		amount
	;

	if(sscanf(params, "ui", player, amount))
	{
		SendUsageMessage(playerid, "givescore <player name / playerid> <amount>");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0, .same = 0)) return 1;

	new
		total = GetPlayerScore(player) + amount
	;

	SetPlayerScore(player, total);
	SendFAdminMessageToAll("Administrator %s <%d> has given %s <%d> %d score.", playerName(playerid), playerid, playerName(player), player, amount);

	// IRC_Message

	return 1;
}

YCMD:agivescoreex(playerid, params[], help)
{
	if(!adminCheck(playerid, 4))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to give a player a certain amount of score without sending a message to all.");
		return 1;
	}

	new player,
		amount
	;

	if(sscanf(params, "ui", player, amount))
	{
		SendUsageMessage(playerid, "givescoreex <player name / playerid> <amount>");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0, .same = 0)) return 1;

	new
		total = GetPlayerScore(player) + amount
	;

	SetPlayerScore(player, total);
	SendFAdminMessageToAdmins("Administrator %s <%d> has given %s <%d> %d score.", playerName(playerid), playerid, playerName(player), player, amount);

	// IRC_Message

	return 1;
}

YCMD:asetcash(playerid, params[], help)
{
	if(!adminCheck(playerid, 3))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to set a player's cash to a certain amount.");
		return 1;
	}

	new player,
		amount
	;

	if(sscanf(params, "ui", player, amount))
	{
		SendUsageMessage(playerid, "setcash <player name / playerid> <amount>");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0, .same = 0)) return 1;

	ResetPlayerMoney(player);
	GivePlayerMoney(player, amount);
	SendFAdminMessageToAll("Administrator %s <%d> has set %s <%d>'s money to %d.", playerName(playerid), playerid, playerName(player), player, amount);

	// IRC_Message

	return 1;
}

YCMD:asetcashex(playerid, params[], help)
{
	if(!adminCheck(playerid, 4))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to set a player's cash to a certain amount without sending a message.");
		return 1;
	}

	new player,
		amount
	;

	if(sscanf(params, "ui", player, amount))
	{
		SendUsageMessage(playerid, "setcashex <player name / playerid> <amount>");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0, .same = 0)) return 1;

	ResetPlayerMoney(player);
	GivePlayerMoney(player, amount);
	SendFAdminMessageToAdmins("Administrator %s <%d> has set %s <%d>'s money to %d.", playerName(playerid), playerid, playerName(player), player, amount);

	// IRC_Message

	return 1;
}

YCMD:agivecash(playerid, params[], help)
{
	if(!adminCheck(playerid, 3))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to give a player a certain amount of cash.");
		return 1;
	}

	new player,
		amount
	;

	if(sscanf(params, "ui", player, amount))
	{
		SendUsageMessage(playerid, "givecash <player name / playerid> <amount>");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0, .same = 0)) return 1;

	GivePlayerMoney(player, amount);
	SendFAdminMessageToAll("Administrator %s <%d> has given %s <%d> $%d cash.", playerName(playerid), playerid, playerName(player), player, amount);

	// IRC_Message

	return 1;
}

YCMD:agivecashex(playerid, params[], help)
{
	if(!adminCheck(playerid, 4))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to give a player a certain amount of cash without sending a message to all.");
		return 1;
	}

	new player,
		amount
	;

	if(sscanf(params, "ui", player, amount))
	{
		SendUsageMessage(playerid, "givecashex <player name / playerid> <amount>");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0, .same = 0)) return 1;

	GivePlayerMoney(player, amount);
	SendFAdminMessageToAdmins("Administrator %s <%d> has given %s <%d> $%d cash.", playerName(playerid), playerid, playerName(player), player, amount);

	// IRC_Message

	return 1;
}

YCMD:ajetpack(playerid, params[], help)
{
	if(!adminCheck(playerid, 4))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to spawn a jetpack.");
		return 1;
	}

	if(!pInfo[playerid][pSpawned])
	{
		SendErrorMessage(playerid, "You need to be spawned to use this command.");
		return 1;
	}

	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
	SendAdminMessage(playerid, "Jetpack given.");

	return 1;
}

YCMD:asetlevel(playerid, params[], help)
{
	if(!adminCheck(playerid, 1337))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to set a player's admin level.");
		return 1;
	}

	new player,
		amount
	;

	if(sscanf(params, "ui", player, amount))
	{
		SendUsageMessage(playerid, "setlevel <player name / playerid> <amount>");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0, .same = 0)) return 1;

	if(pInfo[player][pAdminLevel] == amount)
	{
		SendFErrorMessage(playerid, "%s <%d> is already admin level %d.", playerName(player), player, amount);
		return 1;
	}

	pInfo[player][pAdminLevel] = amount;
	SendFAdminMessageToAll("Administrator %s <%d> has set %s <%d>'s admin level to %d.", playerName(playerid), playerid, playerName(player), player, amount);

	return 1;
}

YCMD:asetlevelex(playerid, params[], help)
{
	if(!adminCheck(playerid, 1337))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to set a player's admin level.");
		return 1;
	}

	new player,
		amount
	;

	if(sscanf(params, "ui", player, amount))
	{
		SendUsageMessage(playerid, "setlevel <player name / playerid> <amount>");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0, .same = 0)) return 1;

	if(pInfo[player][pAdminLevel] == amount)
	{
		SendFErrorMessage(playerid, "%s <%d> is already admin level %d.", playerName(player), player, amount);
		return 1;
	}

	pInfo[player][pAdminLevel] = amount;

	new t_string[144];

	formatex(t_string, "Administrator has set %s <%d>'s admin level to %d.", playerName(player), player, amount);
	formatex(g_string, "Administrator %s <%d> has set %s <%d>'s admin level to %d", playerName(playerid), playerid, playerName(player), amount);

	foreach(new x : Player)
	{
		if(pInfo[x][pAdminLevel] < 1)
			SendClientMessage(x, COLOR_ADMIN, t_string);

		else
			SendClientMessage(x, COLOR_ADMIN, g_string);
	}

	return 1;
}

YCMD:asetvip(playerid, params[], help)
{
	if(!adminCheck(playerid, 5))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to set a player's VIP level.");
		return 1;
	}

	new player,
		amount
	;

	if(sscanf(params, "ui", player, amount))
	{
		SendUsageMessage(playerid, "asetvip <player name / playerid> <amount>");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0, .same = 0)) return 1;

	if(pInfo[player][pVIPLevel] == amount)
	{
		SendFErrorMessage(playerid, "%s <%d> is already VIP level %d.", playerName(player), player, amount);
		return 1;
	}

	if(pInfo[player][pVIPLevel] > 3)
	{
		SendErrorMessage(playerid, "Maximum VIP level is 3.");
		return 1;
	}

	if(pInfo[player][pVIPLevel] < 0)
	{
		SendErrorMessage(playerid, "Minimum VIP level is 0.");
		return 1;
	}

	pInfo[player][pVIPLevel] = amount;
	SendFAdminMessageToAll("Administrator %s <%d> has set %s <%d>'s VIP level to %d.", playerName(playerid), playerid, playerName(player), player, amount);

	return 1;
}

YCMD:asetvipex(playerid, params[], help)
{
	if(!adminCheck(playerid, 1337))
		return 1;

	if(help)
	{
		SendHelpMessage(playerid, "Use this command to set a player's VIP level.");
		return 1;
	}

	new player,
		amount
	;

	if(sscanf(params, "ui", player, amount))
	{
		SendUsageMessage(playerid, "asetvip <player name / playerid> <amount>");
		return 1;
	}

	if(!commandChecks(playerid, player, .spawn = 0, .same = 0)) return 1;

	if(pInfo[player][pVIPLevel] == amount)
	{
		SendFErrorMessage(playerid, "%s <%d> is already VIP level %d.", playerName(player), player, amount);
		return 1;
	}

	if(pInfo[player][pVIPLevel] > 3)
	{
		SendErrorMessage(playerid, "Maximum VIP level is 3.");
		return 1;
	}

	if(pInfo[player][pVIPLevel] < 0)
	{
		SendErrorMessage(playerid, "Minimum VIP level is 0.");
		return 1;
	}

	pInfo[player][pVIPLevel] = amount;

	new t_string[144];

	formatex(t_string, "Administrator has set %s <%d>'s VIP level to %d.", playerName(player), player, amount);
	formatex(g_string, "Administrator %s <%d> has set %s <%d>'s VIP level to %d", playerName(playerid), playerid, playerName(player), amount);

	foreach(new x : Player)
	{
		if(pInfo[x][pAdminLevel] < 1)
			SendClientMessage(x, COLOR_ADMIN, t_string);

		else
			SendClientMessage(x, COLOR_ADMIN, g_string);
	}

	return 1;
}

adminCheck(playerid, level = 1)
{
	if(pInfo[playerid][pAdminLevel] >= level)
	{
		return 1;
	}

	if(IsPlayerAdmin(playerid))
	{
		return 1;
	}

	formatex(g_string, "[ERROR]: {FFFFFF}You need to have an admin level of at least %d to try this command.", level);
	SendClientMessage(playerid, COLOR_DRED, g_string);
	return 0;
}

commandChecks(playerid, player, connected = 1, same = 1, higheradmin = 1, spawn = 1)
{
	if(connected)
	{
		if(!IsPlayerConnected(player))
		{
			SendErrorMessage(playerid, ERROR_CMD_PLAYER_NOT_CONNECTED);
			return 0;
		}
	}

	if(same)
	{
		if(playerid == player)
		{
			SendErrorMessage(playerid, ERROR_CMD_PLAYER_SAME_PLAYER);
			return 0;
		}
	}

	if(higheradmin)
	{
		if(pInfo[playerid][pAdminLevel] < pInfo[player][pAdminLevel])
		{
			SendFErrorMessage(playerid, "You cannot use this command on %s <%d> because he is a higher level admin.", playerName(player), player);
			return 0;
		}
	}

	if(spawn)
	{
		if(!pInfo[player][pSpawned])
		{
			SendFErrorMessage(playerid, "%s <%d> is not spawned yet. This command cannot be used on them.", playerName(player), player);
			return 0;
		}
	}

	return 1;
}