ArrayList g_RestrictionGroups;

void	  Init_Restrictions()
{
	if (g_RestrictionGroups == INVALID_HANDLE)
		g_RestrictionGroups = new ArrayList(sizeof(RestrictionGroup));
	else
		g_RestrictionGroups.Clear();
}

enum struct Restriction
{
	int	  Index;
	float Position[3];
	float Angle[3];
}

Restriction NewRestriction(Restriction r, int index, float position[3], float angle[3])
{
	r.Index	   = index;
	r.Position = position;
	r.Angle	   = angle;
	return r;
}

void AddRestrictionGroup(RestrictionGroup r)
{
	g_RestrictionGroups.PushArray(r, sizeof(r));
}

enum struct RestrictionGroup
{
	int		  Index;
	char	  Name[255];
	int		  MaxPlayers;
	ArrayList Restrictions;
}

RestrictionGroup NewRestrictionGroup(RestrictionGroup r, int index, char name[255], int maxPlayers)
{
	r.Index		   = index;
	r.Name		   = name;
	r.MaxPlayers   = maxPlayers;
	r.Restrictions = new ArrayList(sizeof(Restriction));
	return r;
}

void AddRestrictionToGroup(RestrictionGroup group, Restriction restriction)
{
	group.Restrictions.PushArray(restriction, sizeof(restriction));
}

void GetGroup(int index, RestrictionGroup r)
{
    g_RestrictionGroups.GetArray(index, r, sizeof(r));
}

void GetRestriction(RestrictionGroup r, int index, Restriction f)
{
    r.Restrictions.GetArray(index, f, sizeof(f));
}