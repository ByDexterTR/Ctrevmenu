#include <sourcemod>
#include <cstrike>
#include <warden>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "CT Revmenü", 
	author = "ByDexter", 
	description = "", 
	version = "1.2", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

int revhak = 0;
int revsure[65] = { 0, ... };
bool dokun[65] = { false, ... };

ConVar hak = null, revle = null, revflag = null, god = null;

public void OnPluginStart()
{
	RegConsoleCmd("sm_ctr", RevMenu);
	RegConsoleCmd("sm_ctrevmenu", RevMenu);
	RegConsoleCmd("sm_haksifir", HakSifir);
	RegConsoleCmd("sm_haksifirla", HakSifir);
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_spawn", OnClientSpawn);
	HookEvent("player_death", OnClientDeath);
	
	god = CreateConVar("ctrevmenu_god", "1.5", "Kullanıcı doğduktan sonra kaç saniye godu olsun? [ 0.0 = Kapar ]", 0, true, 0.0);
	hak = CreateConVar("ctrevmenu_hak", "3", "CT Rev Menüsünün Kaç Hakkı Olsun? [ 0 = Sınırsız yapar ]", 0, true, 0.0, true, 10.0);
	revle = CreateConVar("ctrevmenu_sure", "5", "Revlenecek oyuncu kaç saniye sonra revlenebilsin? [ 0 = Kapar ]", 0, true, 0.0, true, 30.0);
	revflag = CreateConVar("ctrevmenu_flag", "r", "CT Rev menüsüne erişim ve hakları sıfırlamak için gereken yetki bayrağı.(Komutçunun otomatik olarak erişimi olur)");
	
	AutoExecConfig(true, "CTRevmenu", "ByDexter");
}

public void OnMapStart()
{
	char map[32];
	GetCurrentMap(map, sizeof(map));
	char Filename[256];
	GetPluginFilename(INVALID_HANDLE, Filename, 256);
	if (strncmp(map, "workshop/", 9, false) == 0)
	{
		if (StrContains(map, "/jb_", false) == -1 && StrContains(map, "/jail_", false) == -1 && StrContains(map, "/ba_jail", false) == -1)
			ServerCommand("sm plugins unload %s", Filename);
	}
	else if (strncmp(map, "jb_", 3, false) != 0 && strncmp(map, "jail_", 5, false) != 0 && strncmp(map, "ba_jail", 3, false) != 0)
		ServerCommand("sm plugins unload %s", Filename);
}

public Action RevMenu(int client, int args)
{
	char adminflag[4];
	revflag.GetString(adminflag, sizeof(adminflag));
	if (warden_iswarden(client) || CheckAdminFlag(client, adminflag))
	{
		if (revhak <= 0)
		{
			PrintHintText(client, "Rev hakkı bitmiş kimseyi revleyemezsin!");
			return Plugin_Handled;
		}
		else
		{
			ReviveMenu().Display(client, 1);
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \x01Bu komuta erişiminiz yok.");
		return Plugin_Handled;
	}
}

public Action HakSifir(int client, int args)
{
	char adminflag[4];
	revflag.GetString(adminflag, sizeof(adminflag));
	if (warden_iswarden(client) || CheckAdminFlag(client, adminflag))
	{
		revhak = hak.IntValue;
		PrintToChatAll("[SM] \x01Kalan canlandırma hakkı \x0C%d \x06olarak güncellendi!", revhak);
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "[SM] \x01Bu komuta erişiminiz yok.");
		return Plugin_Handled;
	}
}

Menu ReviveMenu()
{
	Menu menu = new Menu(RevHandle);
	menu.SetTitle("★Revlenecek Oyuncuyu Seçiniz★\n          ★ Kalan hak: %d ★", revhak);
	menu.AddItem("reload", "! Sayfayı Yenile !\n ");
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 3 && !IsPlayerAlive(i))
	{
		char name[MAX_NAME_LENGTH], id[8];
		GetClientName(i, name, sizeof(name));
		Format(id, sizeof(id), "%d", i);
		if (dokun[i])
		{
			Format(name, sizeof(name), "%s(Hazır!)", name);
			menu.AddItem(id, name);
		}
		else
		{
			Format(name, sizeof(name), "%s(%d Saniye)", name, revsure[i]);
			menu.AddItem(id, name, ITEMDRAW_DISABLED);
		}
	}
	return menu;
}

public int RevHandle(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		char item[16];
		menu.GetItem(position, item, sizeof(item));
		if (strcmp(item, "reload") == 0)
			ReviveMenu().Display(client, 1);
		else
		{
			if (revhak > 0)
			{
				int revkisi = StringToInt(item);
				if (IsValidClient(revkisi) && !IsPlayerAlive(revkisi) && GetClientTeam(revkisi) == 3)
				{
					CS_RespawnPlayer(revkisi);
					if (revhak != 11)
					{
						revhak--;
						PrintToChatAll("[SM] \x10%N \x01isimli gardiyan \x04yeniden canlandırıldı. \x0CKalan hak: \x10%d", revkisi, revhak);
					}
					else
					{
						PrintToChatAll("[SM] \x10%N \x01isimli gardiyan \x04yeniden canlandırıldı.", revkisi);
					}
					dokun[revkisi] = false;
					if (revhak > 0)
						ReviveMenu().Display(client, 1);
				}
				else
				{
					PrintHintText(client, "Revlemek istediğin oyuncu zaten canlı veya yok");
					ReviveMenu().Display(client, 1);
				}
			}
			else
			{
				PrintHintText(client, "Rev hakkı bitmiş kimseyi revleyemezsin!");
			}
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (position == MenuCancel_Timeout)
			ReviveMenu().Display(client, 1);
	}
}

public Action OnClientDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		if (revle.IntValue == 0)
		{
			dokun[client] = true;
		}
		else
		{
			dokun[client] = false;
			revsure[client] = revle.IntValue;
		}
		CreateTimer(1.1, MenuUpdate, GetClientUserId(client), TIMER_REPEAT);
		for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && GetClientTeam(i) == 3 && warden_iswarden(i))
		{
			if (revhak > 0)
				ReviveMenu().Display(i, 1);
			else
				PrintHintText(i, "Rev hakkı bitmiş kimseyi revleyemezsin!");
		}
	}
}

public Action OnClientSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && GetClientTeam(client) == 3 && god.FloatValue > 0.0)
	{
		PrintToChat(client, "[SM] \x01Canlandığınız için \x0C%d saniye \x04Godunuz var.", god.IntValue);
		SetEntityRenderMode(client, RENDER_GLOW);
		SetEntityRenderColor(client, 0, 255, 0, 200);
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		CreateTimer(god.FloatValue, Godalma, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Godalma(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		PrintToChat(client, "[SM] \x07Godunuz artık yok.");
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
	return Plugin_Stop;
}

public Action MenuUpdate(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client))
		return Plugin_Stop;
	
	if (GetClientTeam(client) != 3)
		return Plugin_Stop;
	
	revsure[client]--;
	if (revsure[client] <= 0)
	{
		dokun[client] = true;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if (hak.IntValue == 0)
		revhak = 11;
	else
		revhak = hak.IntValue;
}

bool CheckAdminFlag(int client, const char[] flags)
{
	int iCount = 0;
	char sflagNeed[22][8], sflagFormat[64];
	bool bEntitled = false;
	Format(sflagFormat, sizeof(sflagFormat), flags);
	ReplaceString(sflagFormat, sizeof(sflagFormat), " ", "");
	iCount = ExplodeString(sflagFormat, ",", sflagNeed, sizeof(sflagNeed), sizeof(sflagNeed[]));
	for (int i = 0; i < iCount; i++)
	{
		if ((GetUserFlagBits(client) & ReadFlagString(sflagNeed[i])) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
		{
			bEntitled = true;
			break;
		}
	}
	return bEntitled;
}

bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
} 