#if defined main_mysql_defined_
	#endinput
#endif
#define main_mysql_defined_

#include <a_mysql>

native WP_Hash(buffer[], len, const str[]);

new MySQL:dbHandle;

#define mysql_function_query(%0,%1,%2,%3,%4) mysql_tquery(%0,%1,%3,%4)

new
	mysql_normalString[256],
	//mysql_smallString[512],
	mysql_mediumString[512]
;

#define MYSQL_HOST				"127.0.0.1"
#define MYSQL_USER 				"root"
#define MYSQL_DATABASE			"test"
#define MYSQL_PASS				""
#define MYSQL_PLAYERDATA_TABLE	"cs_playerdata"

#define QUERY_CONNECTION_LOG 1
 
#define QUERY_PLAYER_CHECK 2
#define QUERY_PLAYER_LOGIN 3
#define QUERY_PLAYER_UPDATE 4
#define QUERY_PLAYER_REGISTER 5

#define QUERY_BANK_REGISTER 6
#define QUERY_BANK_CHECK 7
#define QUERY_BANK_UPDATE 8

#define QUERY_BP_REGISTER 9
#define QUERY_BP_CHECK 10
#define QUERY_BP_UPDATE 11

#define QUERY_BAN_REGISTER 12
#define QUERY_ACBAN_REGISTER 13
#define QUERY_BAN_CHECK 14

#define QUERY_LOAD_EXTRAS 15

mysql_init()
{
	//mysql_log(ALL);
	dbHandle = MYSQL_INVALID_HANDLE;
	dbHandle = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DATABASE);
	if(dbHandle == MYSQL_INVALID_HANDLE ) print("Could not connect to MySQL DB.");
	return 1;
}

mysql_exit()
{
	mysql_close(dbHandle);

	return 1;
}

mysql_onPlayerConnect(playerid)
{
	pInfo[playerid][pORMID] = orm_create(MYSQL_PLAYERDATA_TABLE, dbHandle);

	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pID], "playerID");
	orm_addvar_string(pInfo[playerid][pORMID], p_Name[playerid], 24, "playerName");
	orm_addvar_string(pInfo[playerid][pORMID], pInfo[playerid][pPassword], 129, "playerPassword");
	orm_addvar_string(pInfo[playerid][pORMID], pInfo[playerid][pFetchedIP], 16, "playerIP");
	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pAutoLog], "playerAutoLog");
	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pScore], "playerScore");
	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pAdminLevel], "playerAdminLevel");
	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pVIPLevel], "playerVIPLevel");
	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pVIPCredits], "playerVIPCredits");
	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pTotalKills], "playerKills");
	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pTotalDeaths], "playerDeaths");
	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pTotalHeadShots], "playerHeadshots");
	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pTotalHits], "playerShotsOnTarget");
	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pTotalShots], "playerTotalShots");
	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pWins], "playerWins");
	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pLosses], "playerLosses");
	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pTotalMarks], "playerMarks");
	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pTotalSecondsPlayed], "playerTotalSecondsPlayed");
	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pTotalMinutesPlayed], "playerTotalMinutesPlayed");
	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pTotalHoursPlayed], "playerTotalHoursPlayed");
	orm_addvar_string(pInfo[playerid][pORMID], pInfo[playerid][pLastSession], 16, "playerLastSession");
	orm_addvar_int(pInfo[playerid][pORMID], pInfo[playerid][pCookies], "playerCookies");
	
	orm_setkey(pInfo[playerid][pORMID], "playerName");
	orm_select(pInfo[playerid][pORMID], "onPlayerDataLoad", "i", playerid);

	// Log connection
	new
		realName[24]
	;

	mysql_escape_string(playerName(playerid), realName);

	formatex(mysql_normalString, "INSERT INTO `cs_playerConnections`(`conName`,`conIP`,`conPlayerID`,`conType`,`conReason`) VALUES('%s','%s','%d','Connect','None')", realName, playerIP(playerid), playerid);
	mysql_function_query(dbHandle, mysql_normalString, false, "onQueryFinish", "i", QUERY_CONNECTION_LOG);

	return 1;
}

forward onPlayerRegister(playerid, password[]);
public onPlayerRegister(playerid, password[])
{
	formatex(g_string, "[DATABASE]: {FFFFFF}You have successfully registered (ID: %d) to the server using the password \'"COL_RED"%s{FFFFFF}\'.", pInfo[playerid][pID], password);
	SendClientMessage(playerid, COLOR_SERVER, g_string);

	pInfo[playerid][pLoggedIn] = 1;
	return 1;
}

onPlayerLogin(playerid, type = 0)
{
	SetPlayerScore(playerid, pInfo[playerid][pScore]);
	if(!type) SendServerMessage(playerid, "You have logged in to the server. Your stats have been restored.");
	else SendServerMessage(playerid, "You have been automatically logged into the server and your stats have been restored.");

	return 1;
}

forward onPlayerDataLoad(playerid);
public onPlayerDataLoad(playerid)
{
	switch(orm_errno(pInfo[playerid][pORMID]))
	{
		case ERROR_OK:
		{
			if(pInfo[playerid][pAutoLog])
			{
				if(!strcmp(pInfo[playerid][pFetchedIP], p_IP[playerid]))
				{
					pInfo[playerid][pRegistered] = 1;
					onPlayerLogin(playerid);

					return 1;
				}
			}

			orm_delvar(pInfo[playerid][pORMID], "playerIP");
			orm_addvar_string(pInfo[playerid][pORMID], p_IP[playerid], 16, "playerIP");
		
			pInfo[playerid][pRegistered] = 1;
		}

		case ERROR_NO_DATA:
		{
			pInfo[playerid][pRegistered] = 0;
			pInfo[playerid][pLoggedIn] = 0;

			SendServerMessage(playerid, "Your stats will not save. Please \'"COL_RED"/register{FFFFFF}\' if you want your stats to be saved.");
			SendServerMessage(playerid, "Your passwords are hashed. Contact NotHim for more info on hashed passwords. Or just don't use your regular password here.");
		}
	}

	orm_setkey(pInfo[playerid][pORMID], "playerID");
	return 1;
}

mysql_onPlayerDisconnect(playerid, reason)
{
	if(pInfo[playerid][pLoggedIn])
	{
		pInfo[playerid][pScore] = GetPlayerScore(playerid);
		format(pInfo[playerid][pFetchedIP], 16, "%s", p_IP[playerid]);
		formatex(g_bString, "UPDATE `cs_data` SET `playerLastConnection`=NOW() WHERE `playerID`='%d'", pInfo[playerid][pID]);
		mysql_tquery(dbHandle, g_bString);
		orm_update(pInfo[playerid][pORMID]);
		pInfo[playerid][pLoggedIn] = 0;
	}

	orm_destroy(pInfo[playerid][pORMID]);

	// Log connection
	new
		realName[24],
		tempStr[24]
	;

	mysql_escape_string(playerName(playerid), realName);

	switch(reason)
	{
		case 0: tempStr = "Desync";
		case 1: tempStr = "Leave";
		case 2: tempStr = "Kick";
	}
	formatex(mysql_normalString, "INSERT INTO `cs_playerConnections`(`conName`,`conIP`,`conPlayerID`,`conType`,`conReason`) VALUES('%s','%s','%d','Disconnect','%s')", realName, playerIP(playerid), playerid, tempStr);
	mysql_function_query(dbHandle, mysql_normalString, false, "onQueryFinish", "i", QUERY_CONNECTION_LOG);
	return 1;
}

stock mysql_banPlayer(bannedid, bannerid, reason[], time = 1080)
{	
	if(bannedid == INVALID_PLAYER_ID) return 0;
	
	new
		realName[2][24],
		reasonx[32]
	;

	mysql_escape_string(playerName(bannedid), realName[0]);
	mysql_escape_string(playerName(bannerid), realName[1]);
	mysql_escape_string(reason, reasonx, 32);

	formatex(mysql_mediumString, "INSERT INTO `cs_playerBans`(`banName`,`banIP`,`bannerName`,`banReason`,`banTime`) VALUES('%s','%s','%s','%s','%d')", realName[0], playerIP(bannedid), realName[1], reasonx, time);
	mysql_function_query(dbHandle, mysql_mediumString, false, "onPlayerBanQuery", "iii", bannedid, QUERY_BAN_REGISTER, bannerid);

	format(mysql_mediumString, sizeof(mysql_mediumString), ""COL_WHITE"You have been banned from this server.\n"COL_BLUE"Ban Name: "COL_WHITE"%s.\n"COL_BLUE"Ban IP: "COL_WHITE"%s\n"COL_BLUE"Ban Reason: "COL_WHITE"%s\n"COL_BLUE"Banned by: "COL_WHITE"%s.\n"COL_BLUE"Time remaning: "COL_WHITE"%d hours\n\n"COL_RED"NOTE: {FFFFFF}Take a screenshot of this if you want to ban appeal.", playerName(bannedid), playerIP(bannedid), reason, playerName(bannerid), time);
	ShowPlayerDialog(bannedid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, ""COL_RED"BAN INFO", mysql_mediumString, "Bye bye", "");
	
	pInfo[bannedid][pBeingKicked] =1;
	
	return 1;
}

#if defined USE_IRC
	stock mysql_ircBanPlayer(bannedid, reason[], ircName[], time= 1080)
	{	
		if(bannedid == INVALID_PLAYER_ID) return 0;

		new
			realName[2][32],
			reasonx[32]
		;

		mysql_escape_string(playerName(bannedid), realName[0]);
		mysql_escape_string(ircName, realName[1]);
		mysql_escape_string(reason, reasonx);
		
		formatex(mysql_mediumString, "INSERT INTO `cs_playerBans`(`banName`,`banIP`,`bannerName`,`banReason`,`banTime`) VALUES('%s','%s','IRC-%s','%s','%d')", realName[0], playerIP(bannedid), realName[1], reasonx, time);
		mysql_function_query(dbHandle, mysql_mediumString, false, "onPlayerBanQuery", "iii", bannedid, QUERY_ACBAN_REGISTER, -1);
		
		format(mysql_mediumString, sizeof(mysql_mediumString), ""COL_WHITE"You have been banned from this server.\n"COL_BLUE"Ban Name: "COL_WHITE"%s.\n"COL_BLUE"Ban IP: "COL_WHITE"%s\n"COL_BLUE"Ban Reason: "COL_WHITE"%s\n"COL_BLUE"Banned by: "COL_WHITE"%s.\n"COL_BLUE"Time remaning: "COL_WHITE"%d hours\n\n"COL_RED"NOTE: {FFFFFF}Take a screenshot of this if you want to ban appeal.", playerName(bannedid), playerIP(bannedid), reason, ircName, time);
		ShowPlayerDialog(bannedid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, ""COL_RED"BAN INFO", mysql_mediumString, "Bye bye", "");
		
		pInfo[bannedid][pBeingKicked] =1;
		
		return 1;
	}
#endif

stock mysql_removePlayerBan(data[], unbantype = 0, bool:expired = false)
{
	mysql_escape_string(data, data, 32);

	if(unbantype == 0)
	{
		if(expired == false) formatex(mysql_normalString, "DELETE FROM `cs_playerBans` WHERE `banName` = '%s' AND NOW() <= DATE_ADD(ban_timestamp, INTERVAL ban_time HOUR)", data);
		else formatex(mysql_normalString, "DELETE FROM `cs_playerBans` WHERE `banName` = '%s'", data);
		
		mysql_tquery(dbHandle, mysql_normalString, "onQueryFinish");
		
		return 1;
	}
	else
	{
		if(expired == false) formatex(mysql_normalString, "DELETE FROM `cs_playerBans` WHERE `banIP` = '%s' AND NOW() <= DATE_ADD(ban_timestamp, INTERVAL ban_time HOUR)", data);
		else formatex(mysql_normalString, "DELETE FROM `cs_playerBans` WHERE `banIP` = '%s'", data);
		
		mysql_tquery(dbHandle, mysql_normalString, "onQueryFinish");
		
		return 1;
	}
}

mysql_banCheck(playerid)
{
	if(playerid == INVALID_PLAYER_ID) return 0;

	new
		realName[24]
	;

	mysql_escape_string(playerName(playerid), realName);

	formatex(mysql_mediumString, "SELECT `banID`, `banName`, `banIP`, `bannerName`, `banReason`, TIMESTAMPDIFF(HOUR, NOW(), DATE_ADD(`banDay`, INTERVAL `banTime` HOUR)) FROM `cs_playerBans` WHERE (`banIP` = '%s' OR `banName` = '%s') AND (NOW() <= DATE_ADD(`banDAY`, INTERVAL `banTime` HOUR) OR `banTime` = '0')", playerIP(playerid), realName);
	mysql_function_query(dbHandle, mysql_mediumString, true, "onPlayerBanQuery", "ii", playerid, QUERY_BAN_CHECK);
	
	return 1;
}

forward onPlayerBanQuery(bannedid, queryid, bannerid);
public onPlayerBanQuery(bannedid, queryid, bannerid)
{
	if(bannedid == INVALID_PLAYER_ID) return 0;

	switch(queryid)
	{
		case QUERY_BAN_CHECK:
		{
			new rows1;
			
			cache_get_row_count(rows1);
			
			if(!rows1) return 1;
			
			cache_get_value_index_int(0, 0, banID(bannedid));
			cache_get_value_index(0, 1, pBanName(bannedid), 24);
			cache_get_value_index(0, 2, pBanIP(bannedid), 15);
			cache_get_value_index(0, 3, pBannerName(bannedid), 24);
			cache_get_value_index(0, 4, pBanReason(bannedid), 40);
			cache_get_value_index_int(0, 5, pBanTime(bannedid));
			
			/*cache_get_row(0, 0, g_string, dbHandle);				banID(bannedid) = strval(g_string);
			cache_get_row(0, 1, g_string, dbHandle);				format(pBanName(bannedid), 24, g_string);
			cache_get_row(0, 2, g_string, dbHandle);				format(pBanIP(bannedid), 16, g_string);
			cache_get_row(0, 3, g_string, dbHandle);				format(pBannerName(bannedid), 24, g_string);
			cache_get_row(0, 4, g_string, dbHandle);				format(pBanReason(bannedid), 40, g_string);
			cache_get_row(0, 5, g_string, dbHandle);				pBanTime(bannedid) = strval(g_string);*/
			
			if(pBanTime(bannedid) <= 0) 
			{
				mysql_removePlayerBan(playerName(bannedid), 1, true);
				return 1;
			}
			onPlayerBanDetected(bannedid, pBanTime(bannedid), pBannerName(bannedid), pBanReason(bannedid), pBanIP(bannedid), pBanName(bannedid), banID(bannedid));
			
			return 1;
		}
		
		default:
		{
			printf("[MYSQL ERROR] Unknown queryid (ID: '%d' passed under 'onPlayerBanQuery'.", queryid);
			return 1;
		}
	}
	return 0;
}


forward onAdminBanQuery(playerid, type, banid, data[]);
public onAdminBanQuery(playerid, type, banid, data[])
{
	if(type == 2)
	{
		new
			rows3
		;

		cache_get_row_count(rows3);
		//cache_get_data(rows3, columns3, dbHandle);

		if(!rows3)
		{
			formatex(g_bString, "[ERROR]: {FFFFFF}The ban IP \'%s\' does not exist in the database.", data);
			SendClientMessage(playerid, COLOR_ERROR, g_bString);
			return 1;
		}
				
		new
			tempVars3[2],
			tempStrings3[4][42]
		;

		cache_get_value_index_int(0, 0, tempVars3[0]);
		cache_get_value_index(0, 1, tempStrings3[0], 40);
		cache_get_value_index(0, 2, tempStrings3[1], 40);
		cache_get_value_index(0, 3, tempStrings3[2], 40);
		cache_get_value_index(0, 4, tempStrings3[3], 40);
		cache_get_value_index_int(0, 5, tempVars3[1]);

		/*cache_get_row(0, 0, g_string, dbHandle);				tempVars3[0] = strval(g_string);
		cache_get_row(0, 1, g_string, dbHandle);				format(tempStrings3[0], 40, g_string);
		cache_get_row(0, 2, g_string, dbHandle);				format(tempStrings3[1], 40, g_string);
		cache_get_row(0, 3, g_string, dbHandle);				format(tempStrings3[2], 40, g_string);
		cache_get_row(0, 4, g_string, dbHandle);				format(tempStrings3[3], 40, g_string);
		cache_get_row(0, 5, g_string, dbHandle);				tempVars3[1] = strval(g_string);*/

		format(g_bString, sizeof(g_bString), ""COL_BLUE"%s "COL_WHITE"(Ban id: %d)", tempStrings3[0], tempVars3[0]);
		format(mysql_mediumString, sizeof(mysql_mediumString), ""COL_WHITE"Data found!\n\nBan Name: "COL_BLUE"%s.\n"COL_WHITE"Ban IP: "COL_BLUE"%s\n"COL_WHITE"Ban Reason: "COL_BLUE"%s\n"COL_WHITE"Banned by: "COL_BLUE"%s\n"COL_WHITE"Time remaning: "COL_BLUE"%d "COL_WHITE"hours.", tempStrings3[0], tempStrings3[1], tempStrings3[3], tempStrings3[2], tempVars3[1]);
		ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, g_bString, mysql_mediumString, "Ok", "");

		return 1;
	}

	else if(type == 1)
	{
		new
			rows
		;

		cache_get_row_count(rows);
		//cache_get_data(rows, columns, dbHandle);

		if(!rows)
		{
			formatex(g_bString, "[ERROR]: {FFFFFF}The ban name \'%s\' does not exist in the database.", data);
			SendClientMessage(playerid, COLOR_ERROR, g_bString);
			return 1;
		}
				
		new
			tempVars[2],
			tempStrings[4][42]
		;

		cache_get_value_index_int(0, 0, tempVars[0]);
		cache_get_value_index(0, 1, tempStrings[0], 40);
		cache_get_value_index(0, 2, tempStrings[1], 40);
		cache_get_value_index(0, 3, tempStrings[2], 40);
		cache_get_value_index(0, 4, tempStrings[3], 40);
		cache_get_value_index_int(0, 5, tempVars[1]);

		/*cache_get_row(0, 0, g_string, dbHandle);				tempVars[0] = strval(g_string);
		cache_get_row(0, 1, g_string, dbHandle);				format(tempStrings[0], 40, g_string);
		cache_get_row(0, 2, g_string, dbHandle);				format(tempStrings[1], 40, g_string);
		cache_get_row(0, 3, g_string, dbHandle);				format(tempStrings[2], 40, g_string);
		cache_get_row(0, 4, g_string, dbHandle);				format(tempStrings[3], 40, g_string);
		cache_get_row(0, 5, g_string, dbHandle);				tempVars[1] = strval(g_string);*/

		format(g_bString, sizeof(g_bString), ""COL_BLUE"%s "COL_WHITE"(Ban id: %d)", data, tempVars[0]);
		format(mysql_mediumString, sizeof(mysql_mediumString), ""COL_WHITE"Data found!\n\nBan Name: "COL_BLUE"%s.\n"COL_WHITE"Ban IP: "COL_BLUE"%s\n"COL_WHITE"Ban Reason: "COL_BLUE"%s\n"COL_WHITE"Banned by: "COL_BLUE"%s\n"COL_WHITE"Time remaning: "COL_BLUE"%d "COL_WHITE"hours.", tempStrings[0], tempStrings[1], tempStrings[3], tempStrings[2], tempVars[1]);
		ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, g_bString, mysql_mediumString, "Ok", "");

		return 1;
	}

	new
		rows2
	;

	cache_get_row_count(rows2);
	//cache_get_data(rows2, columns2, dbHandle);

	if(!rows2)
	{
		formatex(g_bString, "[ERROR]: {FFFFFF}Ban ID \'%d\' does not exist in the databse.", banid);
		SendClientMessage(playerid, COLOR_ERROR, g_bString);
		return 1;
	}
			
	new
		tempVars2[2],
		tempStrings2[4][42]
	;
		
	cache_get_value_index_int(0, 0, tempVars2[0]);
	cache_get_value_index(0, 1, tempStrings2[0], 40);
	cache_get_value_index(0, 2, tempStrings2[1], 40);
	cache_get_value_index(0, 3, tempStrings2[2], 40);
	cache_get_value_index(0, 4, tempStrings2[3], 40);
	cache_get_value_index_int(0, 5, tempVars2[1]);

/*	cache_get_row(0, 0, g_string, dbHandle);				tempVars2[0] = strval(g_string);
	cache_get_row(0, 1, g_string, dbHandle);				format(tempStrings2[0], 40, g_string);
	cache_get_row(0, 2, g_string, dbHandle);				format(tempStrings2[1], 40, g_string);
	cache_get_row(0, 3, g_string, dbHandle);				format(tempStrings2[2], 40, g_string);
	cache_get_row(0, 4, g_string, dbHandle);				format(tempStrings2[3], 40, g_string);
	cache_get_row(0, 5, g_string, dbHandle);				tempVars2[1] = strval(g_string);*/

	format(g_bString, sizeof(g_bString), ""COL_BLUE"%s "COL_WHITE"(Ban id: %d)", tempStrings2[0], tempVars2[0]);
	format(mysql_mediumString, sizeof(mysql_mediumString), ""COL_WHITE"Data found!\n\nBan Name: "COL_BLUE"%s.\n"COL_WHITE"Ban IP: "COL_BLUE"%s\n"COL_WHITE"Ban Reason: "COL_BLUE"%s\n"COL_WHITE"Banned by: "COL_BLUE"%s\n"COL_WHITE"Time remaning: "COL_BLUE"%d "COL_WHITE"hours.", tempStrings2[0], tempStrings2[1], tempStrings2[3], tempStrings2[2], tempVars2[1]);
	ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, g_bString, mysql_mediumString, "Ok", "");

	return 1;
}
/*
#if defined USE_IRC
forward IRC_onAdminBanQuery(botid, type, banid, channel[], user[], data[]);
public IRC_onAdminBanQuery(botid, type, banid, channel[], user[], data[])
{
	if(type == 2)
	{
		new
			rows3,
			columns3
		;

		cache_get_data(rows3, columns3, dbHandle);

		if(!rows3)
		{
			formatex(g_string, "2ERROR: The ban IP \'%s\' does not exist.", data);
			IRC_Notice(botid, user, g_string);
			return 1;
		}
				
		new
			tempVars3[2],
			tempStrings3[4][42]
		;

		cache_get_row(0, 0, g_string, dbHandle);				tempVars3[0] = strval(g_string);
		cache_get_row(0, 1, g_string, dbHandle);				format(tempStrings3[0], 40, g_string);
		cache_get_row(0, 2, g_string, dbHandle);				format(tempStrings3[1], 40, g_string);
		cache_get_row(0, 3, g_string, dbHandle);				format(tempStrings3[2], 40, g_string);
		cache_get_row(0, 4, g_string, dbHandle);				format(tempStrings3[3], 40, g_string);
		cache_get_row(0, 5, g_string, dbHandle);				tempVars3[1] = strval(g_string);

		format(mysql_mediumString, sizeof(mysql_mediumString), "Ban Name: \'%s\'. Ban IP: \'%s\'. Ban Reason: \'%s\'. Banned by: \'%s\'. Time remaning: %d hours.", tempStrings3[0], tempStrings3[1], tempStrings3[3], tempStrings3[2], tempVars3[1]);
		IRC_Notice(botid, user, g_string);
			
		return 1;
	}

	else if(type == 1)
	{
		new
			rows,
			columns
		;

		cache_get_data(rows, columns, dbHandle);

		if(!rows)
		{
			formatex(g_string, "2ERROR: The ban name \'%s\' does not exist.", data);
			IRC_Notice(botid, user, g_string);
			return 1;
		}
				
		new
			tempVars[2],
			tempStrings[4][42]
		;

		cache_get_row(0, 0, g_string, dbHandle);				tempVars[0] = strval(g_string);
		cache_get_row(0, 1, g_string, dbHandle);				format(tempStrings[0], 40, g_string);
		cache_get_row(0, 2, g_string, dbHandle);				format(tempStrings[1], 40, g_string);
		cache_get_row(0, 3, g_string, dbHandle);				format(tempStrings[2], 40, g_string);
		cache_get_row(0, 4, g_string, dbHandle);				format(tempStrings[3], 40, g_string);
		cache_get_row(0, 5, g_string, dbHandle);				tempVars[1] = strval(g_string);

		format(mysql_mediumString, sizeof(mysql_mediumString), "Ban Name: \'%s\'. Ban IP: \'%s\'. Ban Reason: \'%s\'. Banned by: \'%s\'. Time remaning: %d hours.", tempStrings[0], tempStrings[1], tempStrings[3], tempStrings[2], tempVars[1]);
		IRC_Notice(botid, user, g_string);
			
		return 1;
	}

	new
		rows2,
		columns2
	;

	cache_get_data(rows2, columns2, dbHandle);

	if(!rows)
	{
		formatex(g_string, "2ERROR: The ban id \'%d\' does not exist.", banid);
		IRC_Notice(botid, user, g_string);
		return 1;
	}
			
	new
		tempVars2[2],
		tempStrings2[4][42]
	;

	cache_get_row(0, 0, g_string, dbHandle);				tempVars2[0] = strval(g_string);
	cache_get_row(0, 1, g_string, dbHandle);				format(tempStrings2[0], 40, g_string);
	cache_get_row(0, 2, g_string, dbHandle);				format(tempStrings2[1], 40, g_string);
	cache_get_row(0, 3, g_string, dbHandle);				format(tempStrings2[2], 40, g_string);
	cache_get_row(0, 4, g_string, dbHandle);				format(tempStrings2[3], 40, g_string);
	cache_get_row(0, 5, g_string, dbHandle);				tempVars2[1] = strval(g_string);

	format(mysql_mediumString, sizeof(mysql_mediumString), "Ban Name: \'%s\'. Ban IP: \'%s\'. Ban Reason: \'%s\'. Banned by: \'%s\'. Time remaning: %d hours.", tempStrings2[0], tempStrings2[1], tempStrings2[3], tempStrings2[2], tempVars2[1]);
	IRC_Notice(botid, user, g_string);
			
	return 1;
}
#endif*/

onPlayerBanDetected(playerid, timeremaining, bannerName[], banReason[], banIP[], banName[], banID)
{
	formatex(g_bString, "[PART] "COL_WHITE"%s <%d> has left the server. (Effected by Ban ID: "COL_RED"%d"COL_WHITE") (IP: "COL_YELLOW"%s"COL_WHITE")", playerName(playerid), playerid, banID, playerIP(playerid));

	foreach(new x : Player)
	{
		if(pInfo[x][pAdminLevel] < 1) continue;

		SendClientMessage(x, COLOR_PINK, g_bString);
	}

	#if defined USE_IRC
		format(g_string,sizeof(g_string),"6[PART6] %s(%d) Has left the server! (Effected by Ban ID: %d) (IP: %s)",playerName(playerid),playerid,banID, playerIP(playerid));						
		IRC_GroupSay(irc_botGroups[1],IRC_ADMINCHANNEL,g_string);
	#endif	

	format(mysql_mediumString, sizeof(mysql_mediumString), ""COL_WHITE"You are banned from this server.\n"COL_BLUE"Ban Name: "COL_WHITE"%s.\n"COL_BLUE"Ban IP: "COL_WHITE"%s\n"COL_BLUE"Current IP: "COL_WHITE"%s\n"COL_BLUE"Ban Reason: "COL_WHITE"%s\n"COL_BLUE"Banned by: "COL_WHITE"%s\n"COL_BLUE"Time remaning: "COL_WHITE"%d hours.\n\n"COL_RED"NOTE: {FFFFFF}Take a screenshot of this if you want to ban appeal.", banName, banIP, playerIP(playerid), banReason, bannerName, timeremaining);
	ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, ""COL_RED"BAN INFO", mysql_mediumString, "Bye bye", "");
	
	SetSpawnInfo(playerid, 0, 0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 0, 0);
	SpawnPlayer(playerid);
	
	pInfo[playerid][pBeingKicked] = 1;
	
	return 1;
}

forward onUnbanCommandQuery(playerid, type, data[]);
public onUnbanCommandQuery(playerid, type, data[])
{
	new rows1;
	
	cache_get_row_count(rows1);

	if(!rows1) 
	{
		format(g_string, sizeof(g_string), "Cannot find the IP/name '%s' on our ban database. Please try again.", data);
		SendErrorMessage(playerid, g_string);
		return 1;
	}
	
	if(type == 0)
	{	
		mysql_removePlayerBan(data, 0, false);
		
		formatex(g_string, "[ADMIN]: "COL_WHITE" Unbanned Name: "COL_RED"%s.", data);
		SendClientMessage(playerid, COLOR_ADMIN, g_string);

	    #if defined USE_IRC
		    format(g_string,sizeof(g_string),"9[ADMIN] %s <%d> has unbanned %s.",playerName(playerid),playerid, data);
		    IRC_GroupSay(irc_botGroups[1],IRC_CHANNEL,g_string);
		#endif

		mysql_log_unban(playerid, data);
		
		return 1;
	}
	
	else if(type == 1)
	{
		mysql_removePlayerBan(data, 1, false);
		
		mysql_log_unban(playerid, data);
		
		formatex(g_string, "[ADMIN]: "COL_WHITE" Unbanned IP: "COL_RED"%s.", data);
		SendClientMessage(playerid, COLOR_ADMIN, g_string);

	    #if defined USE_IRC
		    format(g_string,sizeof(g_string),"9[ADMIN] %s <%d> has unbanned IP %s.",playerName(playerid),playerid, data);
		    IRC_GroupSay(irc_botGroups[1],IRC_CHANNEL,g_string);
		#endif

		return 1;
	}
	
	else
	{
		SendErrorMessage(playerid, "Wierd error. Please try again.");
		return 1;
	}
}

// ==================================================================================================
// ==================================================================================================

public OnQueryError(errorid, const error[], const callback[], const query[], MySQL:handle)
{
	print(" ");
	printf("[MYSQL ERROR]: Error ID: '%d'", errorid);
	printf("[MYSQL ERROR]: Error: '%s'", error);
	printf("[MYSQL ERROR]: Callback: '%s'", callback);
	printf("[MYSQL ERROR]: Query: '%d'", query);
	print(" ");
	
	return 1;
}

// ==================================================================================================
// ==================================================================================================

mysql_getAKA(playerid)
{
	if(playerid == INVALID_PLAYER_ID)
		return 0;
	
	new
		realName[24]
	;

	mysql_escape_string(playerName(playerid), realName);

	formatex(mysql_normalString, "SELECT DISTINCT `conName` FROM `con_playerConnections` WHERE `conIP` = '%s' AND `conName` != '%s'", playerIP(playerid), realName);
	mysql_function_query(dbHandle, mysql_normalString, true, "onAKAGet", "i", playerid);
	
	return 1;
}

forward onAKAGet(playerid);
public onAKAGet(playerid)
{
	if(playerid == INVALID_PLAYER_ID)
		return 0;
	
	new
		rows1, tempStr[32]
	;
	
	cache_get_row_count(rows1);

	if(!rows1)
	{
		pInfo[playerid][pNoAKA] = 1;
		return 1;
	}

	format(pInfo[playerid][pAKAString], 128, " ");
	
	for(new i = 0; i < rows1; i++)
	{
		cache_get_value_index(i, 0, tempStr);
		format(pInfo[playerid][pAKAString], 128, "%s%s%s", pInfo[playerid][pAKAString], tempStr, ((i+1)==rows1)?("."):(","));
	}
	pInfo[playerid][pNoAKA] = 0;
	
	return 1;
}

mysql_log_unban(playerid, data[])
{	
	new
		realName[24]
	;

	mysql_escape_string(playerName(playerid), realName);
	mysql_escape_string(data, data, 32);

	formatex(mysql_normalString, "INSERT INTO `cs_unbanLogs` (`adminName`, `unbanData`) VALUES ('%s', '%s')", realName, data);
	mysql_function_query(dbHandle, mysql_normalString, false, "onQueryFinish", "");
	
	return 1;
}

/*mysql_log_irc_unban(user[], data[])
{
	if(strlen(data) > 32) return 0;
	
	new
		realName[32]
	;

	mysql_escape_string(user, realName, 32);
	mysql_escape_string(data, data, 32);
	
	formatex(mysql_normalString, "INSERT INTO `cs_unbanLogs` (`adminName`, `unbanData`) VALUES ('IRC-%s', '%s')", realName, data);
	mysql_function_query(dbHandle, mysql_normalString, false, "onQueryFinish", "");
	
	return 1;
}*/


mysql_log_chat(playerid, msg[])
{
	if(isnull(msg)) return 1;

	new
		realName[24]
	;

	mysql_escape_string(playerName(playerid), realName);
	mysql_escape_string(msg, msg, 256);
	
	formatex(mysql_mediumString, "INSERT INTO `cs_chatLogs` (`playerName`, `playerID`, `playerText`) VALUES ('%s', '%d', '%s')", realName, playerid, msg);
	mysql_function_query(dbHandle, mysql_mediumString, false, "onQueryFinish", "");
	
	return 1;
}

mysql_log_adminChat(playerid, msg[])
{
	if(isnull(msg)) return 0;

	new
		realName[24]
	;

	mysql_escape_string(playerName(playerid), realName);
	mysql_escape_string(msg, msg, 256);
	
	formatex(mysql_mediumString, "INSERT INTO `cs_adminChatLogs` (`playerName`, `playerID`, `playerAdminLevel`, `playerText`) VALUES ('%s', '%d', '%d', '%s')", realName, playerid, pInfo[playerid][pAdminLevel], msg);
	mysql_function_query(dbHandle, mysql_mediumString, false, "onQueryFinish", "");
	
	return 1;
}

mysql_log_radioChat(playerid, msg[])
{
	if(isnull(msg)) return 0;

	new
		realName[24]
	;

	mysql_escape_string(playerName(playerid), realName);
	mysql_escape_string(msg, msg, 32);
	
	formatex(mysql_mediumString, "INSERT INTO `cs_radioChatLogs` (`playerName`, `playerID`, `playerTeam`, `playerText`) VALUES ('%s', '%d', '%d', '%s')", realName, playerid, gTeam[playerid], msg);
	mysql_function_query(dbHandle, mysql_mediumString, false, "onQueryFinish", "");
	
	return 1;
}

mysql_log_privateMessage(sender, receiver, msg[])
{
	if(isnull(msg)) return 0;

	new
		realName[2][24],
		msg2[128]
	;

	mysql_escape_string(playerName(sender), realName[0], 24);
	mysql_escape_string(playerName(receiver), realName[1], 24);
	mysql_escape_string(msg, msg2, 256);

	formatex(mysql_mediumString, "INSERT INTO `cs_privateMessageLogs` (`senderName`, `senderID`, `receiverName`, `receiverID`, `pmText`) VALUES ('%s', '%d', '%s', '%d', '%s')", realName[0], sender, realName[1], receiver, msg2);
	mysql_function_query(dbHandle, mysql_mediumString, false, "onQueryFinish", "");
	
	return 1;
}



forward onBanCheckEx(playerid);
public onBanCheckEx(playerid)
{
	new
		rows
	;

	cache_get_row_count(rows);

	if(rows > 0)
	{
		new
			lastNames[3][24]
		;

		for(new i = 0; i < rows; i++)
		{
			if(i > 2) break;
			cache_get_value_index(i, 0, lastNames[i], 24);
			//cache_get_row(i, 0, g_string, dbHandle);	format(lastNames[i], 24, g_string);
		}

		formatex(g_string, "Yes, he might possibly be evading. Last names: %s, %s, %s.", lastNames[0], lastNames[1], lastNames[2]);
		SendAdminMessage(playerid, g_string);
		return 1;
	}

	SendAdminMessage(playerid, "No, he might not be possibly evading.");
	return 1;
}

#if defined USE_IRC
	forward onIRCBanCheckEx(botid, user[]);
	public onIRCBanCheckEx(botid, user[])
	{
		new rows;

		cache_get_row_count(rows);
		//cache_get_data(rows, fields, dbHandle);

		if(rows > 0)
		{
			new
				lastNames[3][24]
			;

			for(new i = 0; i < rows; i++)
			{
				if(i > 2) continue;
				cache_get_value_index(i, 0, lastNames[i], 24);
				//cache_get_row(i, 0, g_string, dbHandle);	format(lastNames[i], 24, g_string);
			}
			formatex(g_string, "4Yes, he might possibly be ban evading. Last names: %s, %s, %s", lastNames[0], lastNames[1], lastNames[2]);
			IRC_Notice(botid, user, g_string);
			return 1;
		}

		IRC_Notice(botid, user, "3No, he might not be possibly evading.");
		return 1;
	}

	forward onIRCLastSeen(botid, name[], channel[]);
	public onIRCLastSeen(botid, name[], channel[])
	{
		new
			rows
		;

		cache_get_row_count(rows);

		if(!rows)
		{
			formatex(g_string, "2ERROR: User %s does not exist.", name);
			Say(channel, g_string);

			return 1;
		}

		new
			tempVar
		;

		cache_get_value_index_int(0, 0, tempVar);
		//cache_get_row(0, 0, g_string, dbHandle);		tempVar = strval(g_string);

		formatex(g_string, "%s was last seen3 %d hours ago.", name, tempVar);
		Say(channel, g_string);

		return 1;
	}

#endif

forward onLastSeenCheck(playerid, name[]);
public onLastSeenCheck(playerid, name[])
{
	if(!IsPlayerConnected(playerid)) return 0;

	new
		rows
	;

	cache_get_row_count(rows);
	//cache_get_data(rows, columns, dbHandle);

	if(!rows)
	{
		formatex(g_bString, "[ERROR]: {FFFFFF}The name %s was not found on the database.", name);
		SendClientMessage(playerid, COLOR_ERROR, g_bString);
		return 1;
	}

	new
		tempVar
	;

	cache_get_value_index_int(0, 0, tempVar);
	//cache_get_row(0, 0, g_string, dbHandle);		tempVar = strval(g_string);

	formatex(g_bString, "[SERVER]: {FFFFFF}%s was last seen %d hours ago.", name, tempVar);
	SendClientMessage(playerid, COLOR_SERVER, g_bString);

	return 1;
}
