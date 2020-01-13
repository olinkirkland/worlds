package layers
{
	import flash.geom.Point;


	public class WindNode
	{
		public var point : Point;
		public var radius : Number;

		public var corners : Array;
		public var neighbors : Object;


		public function WindNode(point : Point,
                                 radius : Number)
		{
			this.point  = point;
			this.radius = radius;

			neighbors = {};

			determineCorners();
		}


		public function determineCorners() : void
		{
			corners = [];
			for (var i : int = 0; i < 6; i++)
			{
				corners.push(determineCorner(i));
			}
		}


		private function determineCorner(i : int) : Point
		{
			var angle : Number = Util.toRadians(60 * i - 30);
			return new Point(point.x + radius * Math.cos(angle),
			                 point.y + radius * Math.sin(angle));
		}

		public function addNeighbor(hex : WindNode,
		                            degrees : Number) : void
		{
			neighbors[degrees] = hex;
		}
	}
}
