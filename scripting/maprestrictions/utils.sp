bool IsValidClient(int client) {
    return client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client);
}

void PrintToPlayer(int client, const char[] format, any ...)
{
    char chatBuffer[MAX_MESSAGE_LENGTH]
    VFormat(chatBuffer, sizeof(chatBuffer), format, 3);
    Format(chatBuffer, sizeof(chatBuffer), "{green}[AbNeR MapRestrictions]{default} %s", chatBuffer);
    CPrintToChat(client, chatBuffer);
}

