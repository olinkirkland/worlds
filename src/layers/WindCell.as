package layers
{
	import flash.geom.Point;

	import global.Util;


	public class WindCell
	{
		public var point : Point;
		public var radius : Number;
		public var height: Number;

		public var angle: Number;
		public var strength:Number;

		public var corners : Array;
		public var neighbors : Object;



		public function WindCell(point : Point,
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

		public function addNeighbor(hex : WindCell,
		                            degrees : Number) : void
		{
			neighbors[degrees] = hex;
		}
	}
}
