package layers
{
	import flash.geom.Point;


	public class Wind
	{
		public var points : Array;
		public var hexes : Array;

		private var grid : Array;


		public function Wind(map:Map)
		{
			points = [];
			hexes  = [];
			grid   = [[]];

			var radius : Number = 20;
			var width:int = 5;
			var height:int = 5;

			for (var i : int = 0; i < width; i++)
			{
				grid [i] = [];
				for (var j : int = 0; j < height; j++)
				{
					var w : Number = Math.sqrt(3) * radius;
					var x : Number = i * w;
					x += (w / 2) * (j % 2);
					var y : Number = j * 2 * radius * 0.75;

					var p : Point      = new Point(x,
					                          y);
					var hex : WindNode = new WindNode(p,
					                                  radius);

					points.push(p);
					hexes.push(hex);
					grid[i][j] = hex;
				}
			}

			for (i = 0; i < width; i++)
			{
				for (j = 0; j < height; j++)
				{
					var h : WindNode = grid[i][j];
					var odd:Boolean  = j % 2 == 1;

					// E
					x = i + 1;
					y = j;
					if (x >= grid.length)
						x = 0;
					h.addNeighbor(grid[x][y],0);

					// W
					x = i - 1;
					y = j;
					if (x < 0)
						x = grid.length - 1;
					h.addNeighbor(grid[x][y],180);

					// NE
					x = odd ? i + 1 : i;
					y = j - 1;
					if (x >= grid.length)
						x = 0;
					if (y >= 0)
						h.addNeighbor(grid[x][y],300);

					// NW
					x = odd ? i : i - 1;
					y = j - 1;
					if (x < 0)
						x = grid.length - 1;
					if (y >= 0)
						h.addNeighbor(grid[x][y],240);

					// SE
					x = odd ? i + 1 : i;
					y = j + 1;
					if (x >= grid.length)
						x = 0;
					if (y < grid[x].length)
						h.addNeighbor(grid[x][y],60);

					// SW
					x = odd ? i : i - 1;
					y = j + 1;
					if (x < 0)
						x = grid.length - 1;
					if (y < grid[x].length)
						h.addNeighbor(grid[x][y],120);
				}
			}
		}


		public function hexFromPoint(p : Point) : WindNode
		{
			for each (var hex : WindNode in hexes)
			{
				if (hex.point.equals(p))
				{
					return hex;
				}
			}

			return null;
		}
	}
}
