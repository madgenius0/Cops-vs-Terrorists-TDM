#if defined main_irc_included_
	#endinput
#endif
#define main_irc_included_

#include <irc>

#define IRC_SERVER			""
#define IRC_PORT			6667

#define BOT_1_NAME			"cvt_echoBot0"
#define BOT_1_REALNAME		"cvt_echoBot0"
#define BOT_1_USERNAME		"cvt_bots"

#define BOT_2_NAME			"cvt_echoBot1"
#define BOT_2_REALNAME		"cvt_echoBot1"
#define BOT_2_USERNAME		"cvt_bots"

#define BOT_3_NAME			"cvt_aEchoBot0"
#define BOT_3_REALNAME		"cvt_aEchoBot0"
#define BOT_3_USERNAME		"cvt_bots"

#define BOT_4_NAME			"cvt_aEchoBot1"
#define BOT_4_REALNAME		"cvt_aEchoBot1"
#define BOT_4_USERNAME		"cvt_bots"

#define IRC_BOT_PASSWORD	""

#define IRC_CHANNEL 		"#cvt.echo"
#define IRC_ADMINCHANNEL 	"#cvt.admin"

new 
	irc_botID[4],
	irc_botGroups[2]
;

forward connectBots(botid);

irc_init()
{
	irc_botGroups[0] = IRC_CreateGroup();
	irc_botGroups[1] = IRC_CreateGroup();
	return 1;
}

public connectBots(botid)
{
	switch(botid)
	{
		case 0: irc_botID[0] = IRC_Connect(IRC_SERVER, IRC_PORT, BOT_1_NAME, BOT_1_REALNAME, BOT_1_USERNAME);
		case 1: irc_botID[1] = IRC_Connect(IRC_SERVER, IRC_PORT, BOT_2_NAME, BOT_2_REALNAME, BOT_2_USERNAME);
		case 2: irc_botID[2] = IRC_Connect(IRC_SERVER, IRC_PORT, BOT_3_NAME, BOT_3_REALNAME, BOT_3_USERNAME);
		case 3: irc_botID[3] = IRC_Connect(IRC_SERVER, IRC_PORT, BOT_4_NAME, BOT_4_REALNAME, BOT_4_USERNAME);
	}
	return 1;
}

disconnectBots()
{
	for(new i = 0; i < sizeof(irc_botID); i++)
		IRC_Quit(irc_botID[i], "Gamemode Exit");

	return 1;
}

public IRC_OnConnect(botid)
{
	IRC_SetMode(botid, "cvt_bots", "+B");
	IRC_SendRaw(botid, "PRIVMSG NickServ :identify "IRC_BOT_PASSWORD"");	

	if(botid == irc_botID[0] || botid == irc_botID[1])
	{
		IRC_JoinChannel(botid, IRC_CHANNEL);
		IRC_Say(botid, IRC_CHANNEL, "2,15[IRC]: Successfully connected to "IRC_CHANNEL"! ");
		IRC_AddToGroup(irc_botGroups[0], botid);
	}

	else
	{
		IRC_JoinChannel(botid, IRC_ADMINCHANNEL, "fairysec");
		IRC_Say(botid, IRC_CHANNEL, "2,15[IRC]: Successfully connected to "IRC_ADMINCHANNEL"! ");
		IRC_AddToGroup(irc_botGroups[1], botid);
	}
	return 1;
}

public IRC_OnReceiveRaw(botid, message[])
{
	return 1;
}

public IRC_OnUserSay(botid, recipient[], user[], host[], message[])
{
	if((message[1] == '\1' && (!(message[1]))) || (!(message[1]))) return 1;
	
	if(message[0] == '`' || message[0] == '#')
	{
		if(!IRC_IsOwner(botid, recipient, user)) 
		{
			for(new i = 0; i < strlen(message); i++)
			{		
				if(message[i] == '{' || message[i] == '}')
					message[i] = ' ';
			}
		}
		
		formatex(g_bString, "[IRC]: {FFFFFF}%s: %s", user, message[1]);
		SendClientMessageToAll(COLOR_IRC, g_bString);

		format(g_bString, sizeof(g_bString),"12,15[IRC]: %s: %s", user, message[1]);
		Say(recipient, g_bString);

		return 1;
	}

	return 1;
}

IRC_CSay(message[], target = 0)
{
	switch(target)
	{
		case 1337: IRC_GroupSay(irc_botGroups[1], IRC_ADMINCHANNEL, message);
		default: IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, message);
	}
	return 1;
}

IRCCMD:players(botid, channel[], user[], host[], params[])
{
	new
		i,
		firsttime = 0,
		string[2048]
	;

	if(!gPlayerCount) 
	{
		Say(channel, "4,15[ERROR]: No players online!");
		
		return 1;
	}
	
	for(i = 0; i<=MAX_PLAYERS; i++)
	{
		if(IsPlayerConnected(i) && !IsPlayerNPC(i))
		{
		    if(!firsttime)
			{
			 	format(string, sizeof(string),"10,15[PLAYERS]: <%d>%d %s1", i, ((gTeam[i] == TEAM_COP) ? (12) : (4)), playerName(i));
				firsttime++;
			}
			else
			{
		 		format(string, sizeof(string),"%s, <%d>%d %s1", string, i, ((gTeam[i] == TEAM_COP) ? (12) : (4)), playerName(i));
		 		firsttime++;
			}
		}
	}

	if(!firsttime)
	{
		Say(channel, "4,15[ERROR]: No players online!");
	 	return 1;
	}

 	Say(channel,string);
	return 1;
}

IRCCMD:rcon(botid, channel[], user[], host[], params[])
{
	if (IRC_IsOwner(botid, channel, user))
	{
		if (!isnull(params))
		{
			if (strcmp(params, "exit", true) != 0 && strfind(params, "loadfs irc", true) == -1)
			{
				format(g_string, sizeof(g_string), "6,15[RCON]: Command \'1,15%s\' has been executed.", params);
				Say(channel,g_string);
				SendRconCommand(params);
			}
		}
	}
	return 1;
}

/*IRCCMD:unlockserver(botid, channel[], user[], host[], params[])
{
	if(!strcmp(channel, IRC_CHANNEL, true))
	{
		if (IRC_IsOwner(botid, channel, user))
		{
			format(g_string, sizeof(g_string), "6,15[RCON]: Server unlocked!", params);
			Say(channel,g_string);

			SendClientMessageToAll(COLOR_RED, "SERVER UNLOCKED FROM THE IRC!");
			TextDrawHideForAll(fullScreen);

			gUnlocked = 1;
		}
	}
	return 1;
}*/

IRCCMD:ip(botid, channel[], user[], host[], params[])
{
	if (IRC_IsHalfop(botid, channel, user))
	{
		new player;
		if(sscanf(params, "u", player))
		{
			Say(channel, "13,15[USAGE]: /ip <player id/name>.");
			return 1;
		}

		if(!IsPlayerConnected(player))
		{
		 	Say(channel, "4,15[ERROR]: Player not connected to the server.");
		 	return 1;
		}

		format(g_string, sizeof(g_string), "12,15[SERVER]: 1,15%s <%d>'s IP: %s", playerName(player),player,playerIP(player));
		IRC_Notice(botid, user, g_string);
	}
	return 1;
}

Say(target[], string[])
{
	if(!strcmp(target, IRC_CHANNEL))
		IRC_GroupSay(irc_botGroups[0], target, string);
	else if(!strcmp(target, IRC_ADMINCHANNEL))
		IRC_GroupSay(irc_botGroups[1], target, string);

	return 1;
}