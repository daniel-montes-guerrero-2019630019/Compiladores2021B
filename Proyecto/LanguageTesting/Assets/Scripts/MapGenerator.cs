using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.Tilemaps;

public class MapGenerator : MonoBehaviour{

	private Dictionary<string, Template> templates { get; set; }
	private List<Section> sections { get; set; }
	[Header("Reference here your Tilemap")]
	public Tilemap tilemap;
	public int width { get; set; }
	public int height { get; set; }

	public void CreateRulesAndTemplates()
	{
		// Create all ruletiles and templates
		List<Rule> rules = new List<Rule>();
		rules.Add(new Rule{
				isMultipleSprite = true,
				isDefault = true,
				spriteMultiplePath = "Mountain/Tileset",
				spritePath = "ground_middle",
				matrixOfNeighbors = new int[,] {}
				});
		rules.Add(new Rule{
				isMultipleSprite = true,
				isDefault = false,
				spriteMultiplePath = "Mountain/Tileset",
				spritePath = "grass",
				matrixOfNeighbors = new int[,] {{0, -1, 0}, {0, 0, 0}, {0, 0, 0}}
				});
		RuleTile rule = RuleTileGenerator.CreateRuleTile("mountain", rules);
		List<Rule> rules2 = new List<Rule>();
		rules2.Add(new Rule{
				isMultipleSprite = false,
				isDefault = true,
				spriteMultiplePath = "",
				spritePath = "Mountain/tierra_nieve",
				matrixOfNeighbors = new int[,] {}
				});
		rules2.Add(new Rule{
				isMultipleSprite = false,
				isDefault = false,
				spriteMultiplePath = "",
				spritePath = "Mountain/nieve",
				matrixOfNeighbors = new int[,] {{0, -1, 0}, {0, 0, 0}, {0, 0, 0}}
				});
		RuleTile rule2 = RuleTileGenerator.CreateRuleTile("nieve", rules2);
		templates["camino1"] = new Template{
			seed = 2563.53452346346F,
			algorithm = "RandomWalkSmoothed",
			minSectionWidth = 5,
			filler = "nieve"
		};
		templates["camino2"] = new Template{
			seed = 3.1416926F,
			algorithm = "RandomWalkSmoothed",
			minSectionWidth = 5,
			filler = "mountain"
		};
		templates["cueva1"] = new Template{
			seed = 317.7862F,
			fillPercent = 47,
			algorithm = "MooreCellularAutomata",
			edgeAreWalls = true,
			smoothCount = 15,
			filler = "mountain"
		};
		templates["cueva2"] = new Template{
			seed = 317.7862F,
			fillPercent = 46,
			algorithm = "VonNeumannCellularAutomata",
			edgeAreWalls = false,
			smoothCount = 15,
			filler = "mountain"
		};
		templates["hoyo1"] = new Template{
			seed = 34.52345F,
			algorithm = "DirectionalTunnel",
			minPathWidth = 2,
			maxPathWidth = 10,
			roughness = 1,
			curvyness = 3,
			maxPathChange = 5,
			filler = "nieve"
		};
		templates["hoyo2"] = new Template{
			seed = 2234.52345245F,
			algorithm = "DirectionalTunnel",
			minPathWidth = 2,
			maxPathWidth = 10,
			roughness = 1,
			curvyness = 3,
			maxPathChange = 5,
			filler = "mountain"
		};
	}

	public void CreateMap()
	{
		sections = new List<Section>();
		for (int i = 0; i < 7; i++)
		{
			sections.Add(new Section{
				width = width,
					  height = height,
					  id = i,
					  neighbors = new int[4] {-1, -1, -1, -1}
			});
		}
		sections[0].Init(templates["camino1"]);
		sections[1].Init(templates["cueva2"]);
		sections[2].Init(templates["cueva1"]);
		sections[3].Init(templates["hoyo1"]);
		sections[4].Init(templates["hoyo2"]);
		sections[5].Init(templates["camino2"]);
		sections[6].Init(templates["camino2"]);
		sections[0].neighbors[3] = 1;
		sections[1].neighbors[2] = 2;
		sections[0].neighbors[2] = 3;
		sections[2].neighbors[3] = 4;
		sections[5].neighbors[0] = 6;
	}

	public void GenerateAll()
	{
		ClearMap();
		width = 100;
		height = 50;
		sections = new List<Section>();
		templates = new Dictionary<string, Template>();
		CreateRulesAndTemplates();
		CreateMap();
		Generate();
	}

	public void ClearMap()
	{
		tilemap.ClearAllTiles();
	}

	public void Generate()
	{
		bool[] visited = new bool[sections.Count];
		List<ConectedComponent> components = new List<ConectedComponent>();
		for (int i = 0; i < sections.Count; i++)
		{
			visited[i] = false;
		}
		for (int i = 0; i < sections.Count; i++)
		{
			if(!visited[i]){
				ConectedComponent current = new ConectedComponent{
					origin = new int[2] {0, 0},
					corner = new int[2] {width - 1, height - 1},
					elements = new List<int>()
				};
				Dfs(i, visited, current);
				components.Add(current);
			}
		}
		int[] origin = new int[] {0, 0};
		/* Debug.Log("components = " + components.Count); */
		for (int i = 0; i < components.Count; i++)
		{
			MoveCoords(components[i], origin);
			origin[0] = components[i].corner[0] + 1;
			/* Debug.Log("origin[0] = " + origin[0]); */
		}
		int mapWidth = origin[0] + width;
		int mapHeight = origin[1] + height;
		for (int k = 0; k < sections.Count; k++)
		{
			/* Sprite sprite = Resources.Load<Sprite>(RuleTileGenerator.RULE_TILES_PATH + sections[k].filler) as Sprite; */
			TileBase tile = Resources.Load<TileBase>(RuleTileGenerator.RULE_TILES_PATH + sections[k].filler) as TileBase;
			Debug.Log("processing section: " + k);
			/* if(sprite == null) */
			/* { */
			/* 	Debug.Log("Resource sprite load failed"); */
			/* } */
			if(tile == null)
			{
				Debug.Log("Resource tile load failed");
			}
			for (int i = 0; i < width; i++)
			{
				for (int j = 0; j < height; j++)
				{
					int x = sections[k].x + i;
					int y = sections[k].y + j;
					if(sections[k].map[i, j] == 1)
					{
						/* Debug.Log("(" + x + "," + y + ")"); */
						tilemap.SetTile(new Vector3Int(x, y, 0), tile);
					}
				}
			}
		}
	}

	private void MoveCoords(ConectedComponent component, int[] origin)
	{
		int Cx = component.origin[0] - origin[0];
		int Cy = component.origin[1] - origin[1];
		for (int i = 0; i < component.elements.Count; i++)
		{
			int idx = component.elements[i];
			sections[idx].x = sections[idx].x - Cx;
			sections[idx].y = sections[idx].y - Cy;
		}
		component.origin[0] = component.origin[0] - Cx;
		component.origin[1] = component.origin[1] - Cy;
		component.corner[0] = component.corner[0] - Cx;
		component.corner[1] = component.corner[1] - Cy;
	}

	private void Join(ConectedComponent component, Section origin, Section destiny, int direction)
	{
		if (direction == 0)
		{
			destiny.x = origin.x - width;
			destiny.y = origin.y;
		}
		else if (direction == 1)
		{
			destiny.x = origin.x;
			destiny.y = origin.y + height;
		}
		else if (direction == 2)
		{
			destiny.x = origin.x + width;
			destiny.y = origin.y;
		}
		else
		{
			destiny.x = origin.x;
			destiny.y = origin.y - height;
		}
		component.origin[0] = Min(origin.x, destiny.x);
		component.origin[1] = Min(origin.y, destiny.y);
		component.corner[0] = Max(origin.x, destiny.x) + width;
		component.corner[1] = Max(origin.y, destiny.y) + height;
	}

	private void Dfs(int node, bool[] visited, ConectedComponent current)
	{
		visited[node] = true;
		current.elements.Add(node);
		for (int i = 0; i < 4; i++)
		{
			int nextNode = sections[node].neighbors[i];
			if (nextNode == -1)
			{
				continue;
			}
			if (!visited[nextNode])
			{
				Join(current, sections[node], sections[nextNode], i);
				Dfs(nextNode, visited, current);
			}
		}
	}

	private int Min(int a, int b)
	{
		if(a < b) return a;
		return b;
	}

	private int Max(int a, int b)
	{
		if(a > b) return a;
		return b;
	}

}
