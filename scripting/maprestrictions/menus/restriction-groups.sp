void Menus_ShowRestrictionGroups(int client)
{
	Menu menu = new Menu(RestrictionGroup_Handler);
	menu.SetTitle("Restriction Groups");
	menu.AddItem("new", "New Restriction Group");
	for (int i = 0; i < g_RestrictionGroups.Length; i++)
	{
		RestrictionGroup r;
		GetGroup(i, r);

		char sIndex[10];
		Format(sIndex, sizeof(sIndex), "%d", i);

		char sDesc[255];
		Format(sDesc, sizeof(sDesc), "%s, maxplayers %d", r.Name, r.MaxPlayers);
		menu.AddItem(sIndex, sDesc);
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int RestrictionGroup_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (param2 == MenuCancel_ExitBack)
	{
		Menus_ShowMainMenu(param1);
	}

	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:
				{
					// NEW RESTRICTION GROUP MENu
				}
				default:
				{
					char sIndex[10];
					menu.GetItem(param2, sIndex, sizeof(sIndex));

					int index = StringToInt(sIndex);
					Menus_RestrictionGroupDetail(param1, index);
				}
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
	return 0;
}